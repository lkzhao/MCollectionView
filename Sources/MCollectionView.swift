//
//  MCollectionView.swift
//  MCollectionView
//
//  Created by YiLun Zhao on 2016-02-12.
//  Copyright © 2016 lkzhao. All rights reserved.
//

import UIKit
import YetAnotherAnimationLibrary

public class MCollectionView: UIScrollView {
  public weak var collectionDelegate: MCollectionViewDelegate?

  // if autoLayoutOnUpdate is enabled. cell will have their corresponding frame 
  // set when they are loaded or when the collection view scrolls
  // turn this off if you want to manually set its frame
  public var autoLayoutOnUpdate = true

  // Remove cell from view hierarchy if the cell is being deleted.
  // Might want to turn this off if you want to do some animation when
  // cell is being deleted
  public var autoRemoveCells = true

  // wabble animation
  public var wabble = false

  public private(set) var hasReloaded = false

  public var numberOfItems: Int {
    return frames.count
  }

  public var overlayView = UIView()

  // the computed frames for cells, constructed in reloadData
  var frames: [CGRect] = []

  // visible indexes & cell
  let visibleIndexesManager = VisibleIndexesManager()
  let moveManager = MoveManager()
  var visibleIndexes: Set<Int> = []
  var visibleCells: [UIView] { return Array(visibleCellToIndexMap.st.keys) }
  var visibleCellToIndexMap: DictionaryTwoWay<UIView, Int> = [:]
  var identifiersToIndexMap: DictionaryTwoWay<String, Int> = [:]

  var lastReloadFrame: CGRect?
  // TODO: change this to private
  var floatingCells: Set<UIView> = []
  var reusableViews: [String:[UIView]] = [:]
  var cleanupTimer: Timer?
  var reloading = false
  public lazy var contentOffsetProxyAnim = MixAnimation<CGPoint>(value: AnimationProperty<CGPoint>())

  public override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }

  public required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    commonInit()
  }

  func commonInit() {
    overlayView.isUserInteractionEnabled = false
    overlayView.layer.zPosition = 1000
    addSubview(overlayView)

    panGestureRecognizer.addTarget(self, action: #selector(pan(gr:)))
    moveManager.collectionView = self
    contentOffsetProxyAnim.velocity.changes.addListener { [weak self] _, _ in
      self?.didScroll()
    }

    yaal_contentOffset.value.changes.addListener { [weak self] _, newOffset in
      guard let collectionView = self else { return }
      let limit = CGPoint(x: newOffset.x.clamp(collectionView.offsetFrame.minX,
                                               collectionView.offsetFrame.maxX),
                          y: newOffset.y.clamp(collectionView.offsetFrame.minY,
                                               collectionView.offsetFrame.maxY))

      if limit != newOffset {
        collectionView.contentOffset = limit
        collectionView.yaal_contentOffset.updateWithCurrentState()
      }
    }
  }

  func pan(gr:UIPanGestureRecognizer) {
    screenDragLocation = absoluteLocation(for: gr.location(in: self))
    if gr.state == .began {
      yaal_contentOffset.stop()
    }
  }

  public override func layoutSubviews() {
    super.layoutSubviews()
    overlayView.frame = CGRect(origin: contentOffset, size: bounds.size)
    if frame != lastReloadFrame {
      lastReloadFrame = frame
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
  public override var contentOffset: CGPoint{
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
    } else if wabble {
      return visibleFrame.insetBy(dx: -abs(scrollVelocity.x/10).clamp(100, 500), dy: -abs(scrollVelocity.y/10).clamp(100, 500))
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
    layoutCellsIfNecessary()
    for (index, cell) in visibleCellToIndexMap.ts {
      collectionDelegate?.collectionView?(self, cellView:cell, didUpdateScreenPositionForIndex:index, screenPosition:cell.center - contentOffset)
    }
  }

  // reload all frames. will automatically diff insertion & deletion
  public func reloadData(contentOffsetAdjustFn: (()->CGPoint)? = nil) {
    guard let collectionDelegate = collectionDelegate else {
      return
    }
    collectionDelegate.collectionViewWillReload?(self)
    reloading = true

    // ask the delegate for all cell's identifier & frames
    frames = []
    var newIdentifiersToIndexMap: DictionaryTwoWay<String, Int> = [:]
    var newVisibleCellToIndexMap: DictionaryTwoWay<UIView, Int> = [:]
    var unionFrame = CGRect.zero
    let itemCount = collectionDelegate.numberOfItemsInCollectionView(self)

    frames.reserveCapacity(itemCount)
    for index in 0..<itemCount {
      let frame = collectionDelegate.collectionView(self, frameForIndex: index)
      let identifier = collectionDelegate.collectionView(self, identifierForIndex: index)
      newIdentifiersToIndexMap[identifier] = index
      unionFrame = unionFrame.union(frame)
      frames.append(frame)
    }
    visibleIndexesManager.reload(with: frames)

    let oldContentOffset = contentOffset
    contentSize = unionFrame.size
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
        cell.yaal_center.updateWithCurrentState()
      }

      newVisibleCellToIndexMap[newIndex] = cell
      if oldIndex == newIndex {
        collectionDelegate.collectionView?(self, didReloadCellView: cell, atIndex: newIndex)
      } else {
        collectionDelegate.collectionView?(self, didMoveCellView: cell, fromIndex: oldIndex, toIndex: newIndex)
      }
    }

    for identifier in deletedVisibleIdentifiers {
      deleteCell(at: identifiersToIndexMap[identifier]!)
    }

    visibleIndexes = newVisibleIndexes
    visibleCellToIndexMap = newVisibleCellToIndexMap
    identifiersToIndexMap = newIdentifiersToIndexMap

    for identifier in insertedVisibleIdentifiers {
      insertCell(at: identifiersToIndexMap[identifier]!)
    }

    layoutCellsIfNecessary()
    for (index, cell) in visibleCellToIndexMap.ts {
      collectionDelegate.collectionView?(self, cellView:cell, didUpdateScreenPositionForIndex:index, screenPosition:cell.center - contentOffset)
    }
    reloading = false
    hasReloaded = true
    collectionDelegate.collectionViewDidReload?(self)
  }


  public func wabbleRect(_ index: Int) -> CGRect {
    let cellFrame = frameForCell(at: index)!
    let cellScreenCenter = absoluteLocation(for: cellFrame.center)
    let cellOffset = cellScreenCenter.distance(screenDragLocation) * scrollVelocity / 7000
    return CGRect(origin: cellFrame.origin + cellOffset, size: cellFrame.size)
  }

  public func layoutCell(at index: Int, animate:Bool) {
    if let cell = visibleCellToIndexMap[index] {
      if !floatingCells.contains(cell) {
        let frame = wabble ? wabbleRect(index) : frameForCell(at: index)!
        cell.bounds = frame.bounds
        if animate {
          cell.yaal_center.animateTo(frame.center, stiffness: 400, damping: 40, threshold:0.5)
        } else {
          cell.center = frame.center
        }
      }
    }
  }

  public func layoutCellsIfNecessary() {
    if autoLayoutOnUpdate {
      for index in visibleIndexes {
        layoutCell(at: index, animate: wabble)
      }
    }
  }

  func didScroll() {
    cleanupTimer?.invalidate()
    cleanupTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(cleanup), userInfo: nil, repeats: false)
    if !reloading {
      loadCells()
    }
  }

  public func dequeueReusableView<T: UIView> (_ viewClass: T.Type) -> T? {
    return reusableViews[String(describing: viewClass)]?.popLast() as? T
  }

  fileprivate func disappearCell(at index: Int) {
    if let cell = visibleCellToIndexMap[index] {
      collectionDelegate?.collectionView?(self, cellView: cell, willDisappearForIndex: index)
      cell.yaal_center.stop()
      cell.removeFromSuperview()

      let identifier = "\(type(of: cell))"
      if reusableViews[identifier] != nil && !reusableViews[identifier]!.contains(cell) {
        reusableViews[identifier]?.append(cell)
      } else {
        reusableViews[identifier] = [cell]
      }
      visibleCellToIndexMap.remove(index)
    }
  }
  fileprivate func appearCell(at index: Int) {
    if let cell = collectionDelegate?.collectionView(self, viewForIndex: index), visibleCellToIndexMap[cell] == nil {
      visibleCellToIndexMap[cell] = index
      self.addSubview(cell)
      if autoLayoutOnUpdate {
        layoutCell(at: index, animate: false)
      }
      collectionDelegate?.collectionView?(self, cellView: cell, didAppearForIndex: index)
    }
  }
  fileprivate func deleteCell(at index: Int) {
    if let cell = visibleCellToIndexMap[index] {
      if autoRemoveCells {
        cell.removeFromSuperview()
      }
      collectionDelegate?.collectionView?(self, didDeleteCellView: cell, atIndex: index)
      visibleCellToIndexMap.remove(index)
    }
  }
  fileprivate func insertCell(at index: Int) {
    if let cell = collectionDelegate?.collectionView(self, viewForIndex: index), visibleCellToIndexMap[cell] == nil {
      visibleCellToIndexMap[cell] = index
      self.addSubview(cell)
      if autoLayoutOnUpdate {
        layoutCell(at: index, animate: false)
      }
      collectionDelegate?.collectionView?(self, didInsertCellView: cell, atIndex: index)
    }
  }

  func cleanup() {
    reusableViews.removeAll()
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
    cell.yaal_center.updateWithCurrentState()
    cell.yaal_center.animateTo(cell.center, stiffness: 300, damping: 25)
    overlayView.addSubview(cell)
  }

  public func unfloat(cell: UIView) {
    guard isFloating(cell: cell) else {
      return
    }

    floatingCells.remove(cell)
    cell.center = self.convert(cell.center, from: cell.superview)
    cell.yaal_center.updateWithCurrentState()
    self.addSubview(cell)

    // index & frame should be always avaliable because floating cell is always visible. Otherwise we have a bug
    let index = self.index(for: cell)!
    let frame = frameForCell(at: index)!
    cell.yaal_center.animateTo(frame.center, stiffness: 300, damping: 25)
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
