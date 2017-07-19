//
//  MCollectionView.swift
//  MCollectionView
//
//  Created by YiLun Zhao on 2016-02-12.
//  Copyright © 2016 lkzhao. All rights reserved.
//

import UIKit
import YetAnotherAnimationLibrary

public protocol CollectionAnimator {
  func prepare(collectionView: MCollectionView)
  func insert(view: UIView, at: Int, frame: CGRect)
  func delete(view: UIView, at: Int, frame: CGRect)
  func update(view: UIView, at: Int, frame: CGRect, screenPosition: CGPoint)
}

class DefaultCollectionAnimator: CollectionAnimator {
  func prepare(collectionView: MCollectionView) {}
  func insert(view: UIView, at: Int, frame: CGRect) {
    view.bounds = frame.bounds
    view.center = frame.center
  }
  func delete(view: UIView, at: Int, frame: CGRect) {
    view.removeFromSuperview()
  }
  func update(view: UIView, at: Int, frame: CGRect, screenPosition: CGPoint) {
    view.bounds = frame.bounds
    view.center = frame.center
  }
}

class WobbleAnimator: CollectionAnimator {
  var screenDragLocation: CGPoint = .zero
  var contentOffset: CGPoint = .zero
  var scrollVelocity: CGPoint = .zero
  var offsetAnimation = MixAnimation(value: AnimationProperty<CGPoint>())

  func prepare(collectionView: MCollectionView) {
    screenDragLocation = collectionView.screenDragLocation
    contentOffset = collectionView.contentOffset
    scrollVelocity = collectionView.scrollVelocity
  }

  public func wabbleRect(frame: CGRect, at index: Int) -> CGRect {
    if frame.contains(screenDragLocation + contentOffset) {
      return frame
    } else {
      let cellScreenCenter = frame.center - contentOffset
      let cellOffset = cellScreenCenter.distance(screenDragLocation) * scrollVelocity / 7000
      return CGRect(origin: frame.origin + cellOffset, size: frame.size)
    }
  }

  func insert(view: UIView, at: Int, frame: CGRect) {
    view.bounds = frame.bounds
    view.center = frame.center
    view.yaal.center.updateWithCurrentState()
  }

  func delete(view: UIView, at: Int, frame: CGRect) {
    view.removeFromSuperview()
  }

  func update(view: UIView, at: Int, frame: CGRect, screenPosition: CGPoint) {
    view.bounds = frame.bounds
    let frame = wabbleRect(frame: frame, at: at)
    view.yaal.center.animateTo(frame.center, stiffness: 400, damping: 40, threshold:0.5)
  }
}


class ReuseManager {
  static let shared = ReuseManager()
  var reusableViews: [String:[UIView]] = [:]
  var cleanupTimer: Timer?
  func queue(view: UIView) {
    let identifier = String(describing: type(of: view))
    if reusableViews[identifier] != nil && !reusableViews[identifier]!.contains(view) {
      reusableViews[identifier]?.append(view)
    } else {
      reusableViews[identifier] = [view]
    }
    cleanupTimer?.invalidate()
    cleanupTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(cleanup), userInfo: nil, repeats: false)
  }

  public func dequeueReusableView<T: UIView> (_ viewClass: T.Type) -> T? {
    let cell = reusableViews[String(describing: viewClass)]?.popLast() as? T
    if let cell = cell as? MCollectionViewReusableView {
      cell.prepareForReuse()
    }
    return cell
  }

  @objc func cleanup() {
    reusableViews.removeAll()
  }
}

open class MCollectionView: UIScrollView {
  public var provider: AnyCollectionProvider?
  public var animator: CollectionAnimator = WobbleAnimator()

  public private(set) var hasReloaded = false

  public var minimumContentSize: CGSize = .zero {
    didSet{
      let newContentSize = CGSize(width: max(minimumContentSize.width, contentSize.width),
                                  height: max(minimumContentSize.height, contentSize.height))
      if newContentSize != contentSize {
        contentSize = newContentSize
      }
    }
  }

  public var numberOfItems: Int {
    return frames.count
  }

  public var overlayView = UIView()

  public var supportOverflow = false

  // the computed frames for cells, constructed in reloadData
  var frames: [CGRect] = []

  // visible indexes & cell
  let visibleIndexesManager = VisibleIndexesManager()
  let moveManager = MoveManager()
  public var visibleIndexes: Set<Int> = []
  public var visibleCells: [UIView] { return Array(visibleCellToIndexMap.st.keys) }
  var visibleCellToIndexMap: DictionaryTwoWay<UIView, Int> = [:]
  var identifiersToIndexMap: DictionaryTwoWay<String, Int> = [:]

  var lastReloadSize: CGSize?
  // TODO: change this to private
  public var floatingCells: Set<UIView> = []
  public var loading = false
  public var reloading = false
  public lazy var contentOffsetProxyAnim = MixAnimation<CGPoint>(value: AnimationProperty<CGPoint>())

  public var tapGestureRecognizer = UITapGestureRecognizer()

  public override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }

  public required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    commonInit()
  }

  func commonInit() {
    tapGestureRecognizer.addTarget(self, action: #selector(tap(gr:)))
    addGestureRecognizer(tapGestureRecognizer)

    overlayView.isUserInteractionEnabled = false
    overlayView.layer.zPosition = 1000
    addSubview(overlayView)

    panGestureRecognizer.addTarget(self, action: #selector(pan(gr:)))
    moveManager.collectionView = self
    contentOffsetProxyAnim.velocity.changes.addListener { [weak self] _, _ in
      self?.didScroll()
    }

    yaal.contentOffset.value.changes.addListener { [weak self] _, newOffset in
      guard let collectionView = self else { return }
      let limit = CGPoint(x: newOffset.x.clamp(collectionView.offsetFrame.minX,
                                               collectionView.offsetFrame.maxX),
                          y: newOffset.y.clamp(collectionView.offsetFrame.minY,
                                               collectionView.offsetFrame.maxY))

      if limit != newOffset {
        collectionView.contentOffset = limit
        collectionView.yaal.contentOffset.updateWithCurrentState()
      }
    }
  }

  @objc func tap(gr: UITapGestureRecognizer) {
    for cell in visibleCells {
      if cell.point(inside: gr.location(in: cell), with: nil) {
        provider?.didTap(cell: cell, at: visibleCellToIndexMap[cell]!)
        return
      }
    }
  }

  func pan(gr:UIPanGestureRecognizer) {
    screenDragLocation = absoluteLocation(for: gr.location(in: self))
    if gr.state == .began {
      yaal.contentOffset.stop()
    }
  }

  open override func layoutSubviews() {
    super.layoutSubviews()
    overlayView.frame = CGRect(origin: contentOffset, size: bounds.size)
    if bounds.size != lastReloadSize {
      lastReloadSize = bounds.size
      reloadData()
    }
  }

  public var activeFrameSlop: UIEdgeInsets? {
    didSet {
      if !reloading && activeFrameSlop != oldValue {
        loadCells()
      }
    }
  }
  var screenDragLocation: CGPoint = .zero
  open override var contentOffset: CGPoint{
    didSet{
      if isTracking || isDragging || isDecelerating, !reloading {
        contentOffsetProxyAnim.animateTo(contentOffset, stiffness:1000, damping:40)
      } else {
        contentOffsetProxyAnim.value.value = contentOffsetProxyAnim.value.value + contentOffset - oldValue
        contentOffsetProxyAnim.target.value = contentOffsetProxyAnim.target.value + contentOffset - oldValue
        didScroll()
      }
    }
  }
  public var scrollVelocity: CGPoint {
    return contentOffsetProxyAnim.velocity.value
  }
  var activeFrame: CGRect {
    if let activeFrameSlop = activeFrameSlop {
      return CGRect(x: visibleFrame.origin.x + activeFrameSlop.left, y: visibleFrame.origin.y + activeFrameSlop.top, width: visibleFrame.width - activeFrameSlop.left - activeFrameSlop.right, height: visibleFrame.height - activeFrameSlop.top - activeFrameSlop.bottom)
    } else {
      return visibleFrame
    }
  }

  /*
   * Update visibleCells & visibleIndexes according to scrollView's visibleFrame
   * load cells that move into the visibleFrame and recycles them when
   * they move out of the visibleFrame.
   */
  func loadCells() {
    if loading { return }
    animator.prepare(collectionView: self)
    loading = true
    if offsetFrame.insetBy(dx: -10, dy: -10).contains(contentOffset) {
      let indexes = visibleIndexesManager.visibleIndexes(for: activeFrame).union(floatingCells.map({ return visibleCellToIndexMap[$0]! }))
      let deletedIndexes = visibleIndexes.subtracting(indexes)
      let newIndexes = indexes.subtracting(visibleIndexes)
      for i in deletedIndexes {
          disappearCell(at: i)
      }
      for i in newIndexes {
          appearCell(at: i)
      }
      visibleIndexes = indexes
    }

    for (index, view) in visibleCellToIndexMap.ts {
      if !floatingCells.contains(view) {
        animator.update(view: view, at: index, frame: frames[index], screenPosition: view.center - contentOffset)
      }
    }
    loading = false
  }

  // reload all frames. will automatically diff insertion & deletion
  public func reloadData(contentOffsetAdjustFn: (()->CGPoint)? = nil) {
    guard let provider = provider else {
      return
    }
    provider.willReload()
    provider.prepare(size: innerSize)
    animator.prepare(collectionView: self)
    reloading = true

    // ask the delegate for all cell's identifier & frames
    frames = []
    var newIdentifiersToIndexMap: DictionaryTwoWay<String, Int> = [:]
    var newVisibleCellToIndexMap: DictionaryTwoWay<UIView, Int> = [:]
    var unionFrame = CGRect.zero
    let itemCount = provider.numberOfItems
    let padding = provider.insets

    frames.reserveCapacity(itemCount)
    for index in 0..<itemCount {
      let frame = provider.frame(at: index)
      let identifier = provider.identifier(at: index)
      if newIdentifiersToIndexMap[identifier] != nil {
        print("[MCollectionView] Duplicate Identifier: \(identifier)")
        var i = 2
        var newIdentifier = ""
        repeat {
          newIdentifier = identifier + "\(i)"
          i += 1
        } while newIdentifiersToIndexMap[newIdentifier] != nil
        newIdentifiersToIndexMap[newIdentifier] = index
      } else {
        newIdentifiersToIndexMap[identifier] = index
      }
      unionFrame = unionFrame.union(frame)
      frames.append(frame)
    }
    if padding.top != 0 || padding.left != 0 {
      for index in 0..<frames.count {
        frames[index].origin = frames[index].origin + CGPoint(x: padding.left, y: padding.top)
      }
    }
    visibleIndexesManager.reload(with: frames)

    let oldContentOffset = contentOffset
    contentSize = CGSize(width: max(minimumContentSize.width, unionFrame.size.width + padding.left + padding.right),
                         height: max(minimumContentSize.height, unionFrame.size.height + padding.top + padding.bottom))
    if let offset = contentOffsetAdjustFn?() {
      contentOffset = offset
    }
    let contentOffsetDiff = contentOffset - oldContentOffset

    var newVisibleIndexes = visibleIndexesManager.visibleIndexes(for: activeFrame)
    for cell in floatingCells {
      let cellIdentifier = identifiersToIndexMap[visibleCellToIndexMap[cell]!]!
      if let index = newIdentifiersToIndexMap[cellIdentifier] {
        newVisibleIndexes.insert(index)
      } else {
        unfloat(cell: cell)
      }
    }

    let newVisibleIdentifiers = Set(newVisibleIndexes.map { index in
      return newIdentifiersToIndexMap[index]!
    })
    let oldVisibleIdentifiers = Set(visibleIndexes.map { index in
      return identifiersToIndexMap[index]!
    })

    let deletedVisibleIdentifiers = oldVisibleIdentifiers.subtracting(newVisibleIdentifiers)
    let insertedVisibleIdentifiers = newVisibleIdentifiers.subtracting(oldVisibleIdentifiers)
    let existingVisibleIdentifiers = newVisibleIdentifiers.intersection(oldVisibleIdentifiers)

    for identifier in existingVisibleIdentifiers {
      // move the cell to a different index
      let oldIndex = identifiersToIndexMap[identifier]!
      let newIndex = newIdentifiersToIndexMap[identifier]!
      let cell = visibleCellToIndexMap[oldIndex]!

      // need to update these cells' center if contentOffset changed when we set contentFrame. i.e. anchorPoint is .bottomRight
      // these cells' animation target shifted but their current value did not.
      if !floatingCells.contains(cell) {
        cell.center = cell.center + contentOffsetDiff
        cell.yaal.center.updateWithCurrentState()
        insert(cell: cell)
      }

      newVisibleCellToIndexMap[newIndex] = cell
      provider.update(view: cell, at: newIndex)
      animator.update(view: cell, at: newIndex, frame: frames[newIndex], screenPosition: frames[newIndex].center - contentOffset)
      if oldIndex == newIndex {
//        collectionDelegate.collectionView?(self, didReloadCellView: cell, atIndex: newIndex)
      } else {
//        collectionDelegate.collectionView?(self, didMoveCellView: cell, fromIndex: oldIndex, toIndex: newIndex)
      }
    }

    for identifier in deletedVisibleIdentifiers {
      disappearCell(at: identifiersToIndexMap[identifier]!)
    }

    visibleIndexes = newVisibleIndexes
    visibleCellToIndexMap = newVisibleCellToIndexMap
    identifiersToIndexMap = newIdentifiersToIndexMap

    for identifier in insertedVisibleIdentifiers {
      appearCell(at: identifiersToIndexMap[identifier]!)
    }

    for (index, view) in visibleCellToIndexMap.ts {
      if !floatingCells.contains(view) {
        animator.update(view: view, at: index, frame: frames[index], screenPosition: view.center - contentOffset)
      }
    }
    reloading = false
    hasReloaded = true
    provider.didReload()
  }


  func didScroll() {
    if !reloading {
      loadCells()
    }
  }

  fileprivate func disappearCell(at index: Int) {
    if let cell = visibleCellToIndexMap[index] {
//      collectionDelegate?.collectionView?(self, cellView: cell, willDisappearForIndex: index)
      cell.yaal.center.stop()

      if reloading {
        animator.delete(view: cell, at: index, frame: frames[index])
      } else {
        cell.removeFromSuperview()
        ReuseManager.shared.queue(view: cell)
      }

      visibleCellToIndexMap.remove(index)
    }
  }
  fileprivate func appearCell(at index: Int) {
    guard let provider = provider else { return }
    let cell = provider.view(at: index)
    provider.update(view: cell, at: index)
    if visibleCellToIndexMap[cell] == nil {
      visibleCellToIndexMap[cell] = index
      insert(cell: cell)
      animator.insert(view: cell, at: index, frame: frames[index])
    }
  }
  fileprivate func insert(cell: UIView) {
    if let index = self.index(for: cell) {
      var currentMin = Int.max
      for cell in subviews {
        if let visibleIndex = visibleCellToIndexMap[cell], visibleIndex > index, visibleIndex < currentMin {
          currentMin = visibleIndex
        }
      }
      if currentMin == Int.max {
        insertSubview(cell, belowSubview: overlayView)
      } else {
        insertSubview(cell, belowSubview: visibleCellToIndexMap[currentMin]!)
      }
    } else {
      insertSubview(cell, belowSubview: overlayView)
    }
  }

  override open func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
    if supportOverflow {
      if super.point(inside: point, with: event) {
        return true
      }
      for cell in visibleCells {
        if cell.point(inside: cell.convert(point, from: self), with: event) {
          return true
        }
      }
      return false
    } else {
      return super.point(inside: point, with: event)
    }
  }
}

extension MCollectionView {
  public func isFloating(cell: UIView) -> Bool {
    return floatingCells.contains(cell)
  }

  public func float(cell: UIView) {
    if visibleCellToIndexMap[cell] == nil {
      fatalError("Unable to float a cell that is not on screen")
    }
    floatingCells.insert(cell)
    cell.center = overlayView.convert(cell.center, from: cell.superview)
    cell.yaal.center.updateWithCurrentState()
    cell.yaal.center.animateTo(cell.center, stiffness: 300, damping: 25)
    overlayView.addSubview(cell)
  }

  public func unfloat(cell: UIView) {
    guard isFloating(cell: cell) else {
      return
    }

    floatingCells.remove(cell)
    cell.center = self.convert(cell.center, from: cell.superview)
    cell.yaal.center.updateWithCurrentState()
    insert(cell: cell)

    // index & frame should be always avaliable because floating cell is always visible. Otherwise we have a bug
    let index = self.index(for: cell)!
    let frame = frameForCell(at: index)!
    cell.yaal.center.animateTo(frame.center, stiffness: 300, damping: 25)
  }
}

extension MCollectionView {
  public func indexForCell(at point: CGPoint) -> Int? {
    for (index, frame) in frames.enumerated() {
      if frame.contains(point) {
        return index
      }
    }
    return nil
  }

  public func frameForCell(at index: Int?) -> CGRect? {
    if let index = index {
      return frames.count > index ? frames[index] : nil
    }
    return nil
  }

  public func index(for cell: UIView) -> Int? {
    return visibleCellToIndexMap[cell]
  }

  public func cell(at index: Int) -> UIView? {
    return visibleCellToIndexMap[index]
  }
}
