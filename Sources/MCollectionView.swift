//
//  MCollectionView.swift
//  MCollectionView
//
//  Created by YiLun Zhao on 2016-02-12.
//  Copyright © 2016 lkzhao. All rights reserved.
//

import UIKit

public class MCollectionView: MScrollView {
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

  // inner size is the frame size minus the inset
  public var innerSize: CGSize {
    return CGSize(width: bounds.width - contentInset.left - contentInset.right, height: bounds.height - contentInset.top - contentInset.bottom)
  }

  public var numberOfItems: Int {
    return frames.reduce(0, { (count, section) -> Int in
      return count + section.count
    })
  }

  public var overlayView = UIView()

  // the computed frames for cells, constructed in reloadData
  var frames: [[CGRect]] = []

  // visible indexes & cell
  let visibleIndexesManager = VisibleIndexesManager()
  let moveManager = MoveManager()
  var visibleIndexes: Set<IndexPath> = []
  var visibleCells: [UIView] { return Array(visibleCellToIndexMap.st.keys) }
  var visibleCellToIndexMap: DictionaryTwoWay<UIView, IndexPath> = [:]
  var identifiersToIndexMap: DictionaryTwoWay<String, IndexPath> = [:]

  var lastReloadFrame: CGRect?
  // TODO: change this to private
  var floatingCells: Set<UIView> = []
  var reusableViews: [String:[UIView]] = [:]
  var cleanupTimer: Timer?
  var reloading = false

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
    addSubview(overlayView)
    moveManager.collectionView = self
  }

  public override func layoutSubviews() {
    super.layoutSubviews()
    overlayView.frame = bounds
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
  public var activeFrame: CGRect {
    if let activeFrameSlop = activeFrameSlop {
      return CGRect(x: visibleFrame.origin.x + activeFrameSlop.left, y: visibleFrame.origin.y + activeFrameSlop.top, width: visibleFrame.width - activeFrameSlop.left - activeFrameSlop.right, height: visibleFrame.height - activeFrameSlop.top - activeFrameSlop.bottom)
    } else if wabble {
      let maxDim = max(bounds.width, bounds.height) + 200
      return visibleFrame.insetBy(dx: -(maxDim - bounds.width), dy: -(maxDim - bounds.height))
    } else {
      return visibleFrame
    }
  }

  /*
   * Update visibleCells & visibleIndexes according to scrollView's visibleFrame
   * load cells that move into the visibleFrame and recycles them when
   * they move out of the visibleFrame.
   */
  fileprivate func loadCells() {
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
    for (indexPath, cell) in visibleCellToIndexMap.ts {
      collectionDelegate?.collectionView?(self, cellView:cell, didUpdateScreenPositionForIndexPath:indexPath, screenPosition:cell.center - contentOffset)
    }
  }

  // reload all frames. will automatically diff insertion & deletion
  public func reloadData(_ framesLoadedBlock:(() -> Void)? = nil) {
    self.collectionDelegate?.collectionViewWillReload?(self)
    reloading = true

    // ask the delegate for all cell's identifier & frames
    frames = []
    var newIdentifiersToIndexMap: DictionaryTwoWay<String, IndexPath> = [:]
    var newVisibleCellToIndexMap: DictionaryTwoWay<UIView, IndexPath> = [:]
    var unionFrame = CGRect.zero
    let sectionCount = collectionDelegate?.numberOfSectionsInCollectionView?(self) ?? 1

    frames.reserveCapacity(sectionCount)
    for i in 0..<sectionCount {
      let sectionItemsCount = collectionDelegate?.collectionView(self, numberOfItemsInSection: i) ?? 0
      frames.append([CGRect]())
      for j in 0..<sectionItemsCount {
        let indexPath = IndexPath(item: j, section: i)
        let frame = collectionDelegate!.collectionView(self, frameForIndexPath: indexPath)
        let identifier = collectionDelegate!.collectionView(self, identifierForIndexPath: indexPath)
        newIdentifiersToIndexMap[identifier] = indexPath
        unionFrame = unionFrame.union(frame)
        frames[i].append(frame)
      }
    }
    visibleIndexesManager.reload(with: frames)
    // set scrollview's contentFrame to be the unionFrame
    contentFrame = unionFrame

    let oldContentOffset = contentOffset

    // This block is called to for the application to adjust the contentOffset,
    // usually used when the application inserted some cells at the top. The application
    // have to manually adjust the contentOffset so that the collection doesn't just jump to the top.
    framesLoadedBlock?()

    // When the scrollview is deccelerating, if we reloaded some data and adjusted the contentOffset,
    // we have to update the animations targetOffset, otherwise it will animate to the incorrect position
    let contentOffsetDiff = contentOffset - oldContentOffset
    if let targetY = scrollAnimation.targetOffsetY {
      scrollAnimation.targetOffsetY = targetY + contentOffsetDiff.y
    }
    if let targetX = scrollAnimation.targetOffsetX {
      scrollAnimation.targetOffsetX = targetX + contentOffsetDiff.x
    }

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
      cell.center = cell.center + contentOffsetDiff
      newVisibleCellToIndexMap[newIndex] = cell
      if oldIndex == newIndex {
        collectionDelegate?.collectionView?(self, didReloadCellView: cell, atIndexPath: newIndex)
      } else {
        collectionDelegate?.collectionView?(self, didMoveCellView: cell, fromIndexPath: oldIndex, toIndexPath: newIndex)
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
      collectionDelegate?.collectionView?(self, cellView:cell, didUpdateScreenPositionForIndexPath:index, screenPosition:cell.center - contentOffset)
    }
    reloading = false
    self.collectionDelegate?.collectionViewDidReload?(self)
  }


  public func wabbleRect(_ indexPath: IndexPath) -> CGRect {
    let screenDragLocation = contentOffset + dragLocation
    let cellFrame = frameForCell(at: indexPath)!
    let cellOffset = cellFrame.center.distance(screenDragLocation) * scrollVelocity / 5000
    return CGRect(origin: cellFrame.origin + cellOffset, size: cellFrame.size)
  }

  public func layoutCellsIfNecessary() {
    if autoLayoutOnUpdate {
      for (indexPath, cell) in visibleCellToIndexMap.ts {
        if !floatingCells.contains(cell) {
          if wabble {
            cell.m_animate("center", to:wabbleRect(indexPath).center, stiffness: 150, damping:20, threshold: 1)
          } else {
            let f = frameForCell(at: indexPath)!
            cell.bounds = f.bounds
            cell.center = f.center
          }
        }
      }
    }
  }

  override func didScroll() {
    cleanupTimer?.invalidate()
    if !reloading {
      loadCells()
      super.didScroll()
    }
  }

  override func didEndScroll() {
    super.didEndScroll()
    cleanupTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(cleanup), userInfo: nil, repeats: false)
  }

  public func dequeueReusableView<T: UIView> (_ viewClass: T.Type) -> T? {
    return reusableViews[String(describing: viewClass)]?.popLast() as? T
  }

  fileprivate func disappearCell(at indexPath: IndexPath) {
    if let cell = visibleCellToIndexMap[indexPath] {
      collectionDelegate?.collectionView?(self, cellView: cell, willDisappearForIndexPath: indexPath)
      cell.m_removeAnimationForKey("center")
      cell.removeFromSuperview()

      let identifier = "\(type(of: cell))"
      if reusableViews[identifier] != nil && !reusableViews[identifier]!.contains(cell) {
        reusableViews[identifier]?.append(cell)
      } else {
        reusableViews[identifier] = [cell]
      }
      visibleCellToIndexMap.remove(indexPath)
    }
  }
  fileprivate func appearCell(at indexPath: IndexPath) {
    if let cell = collectionDelegate?.collectionView(self, viewForIndexPath: indexPath, initialFrame: frameForCell(at: indexPath)!), visibleCellToIndexMap[cell] == nil {
      visibleCellToIndexMap[cell] = indexPath
      contentView.addSubview(cell)
      collectionDelegate?.collectionView?(self, cellView: cell, didAppearForIndexPath: indexPath)
    }
  }
  fileprivate func deleteCell(at indexPath: IndexPath) {
    if let cell = visibleCellToIndexMap[indexPath] {
      if autoRemoveCells {
        cell.removeFromSuperview()
      }
      collectionDelegate?.collectionView?(self, didDeleteCellView: cell, atIndexPath: indexPath)
      visibleCellToIndexMap.remove(indexPath)
    }
  }
  fileprivate func insertCell(at indexPath: IndexPath) {
    if let cell = collectionDelegate?.collectionView(self, viewForIndexPath: indexPath, initialFrame: frameForCell(at: indexPath)!), visibleCellToIndexMap[cell] == nil {
      visibleCellToIndexMap[cell] = indexPath
      contentView.addSubview(cell)
      collectionDelegate?.collectionView?(self, didInsertCellView: cell, atIndexPath: indexPath)
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
    cell.m_animate("center", to:cell.center, stiffness: 300, damping: 25)
    overlayView.addSubview(cell)
  }

  public func unfloat(cell: UIView) {
    guard isFloating(cell: cell) else {
      return
    }

    floatingCells.remove(cell)
    cell.center = contentView.convert(cell.center, from: cell.superview)
    contentView.addSubview(cell)

    // index & frame should be always avaliable because floating cell is always visible. Otherwise we have a bug
    let index = indexPath(for: cell)!
    let frame = frameForCell(at: index)!
    cell.m_animate("center", to:frame.center, stiffness: 300, damping: 25)
  }
}

extension MCollectionView {
  public func indexPathForCell(at point: CGPoint) -> IndexPath? {
    for (i, s) in frames.enumerated() {
      for (j, f) in s.enumerated() {
        if f.contains(point) {
          return IndexPath(item: j, section: i)
        }
      }
    }
    return nil
  }

  public func indexPath(for cell: UIView) -> IndexPath? {
    if reloading {
      fatalError("shouldn't call index of view during reload -> wrong index might be returned")
    }
    return visibleCellToIndexMap[cell]
  }

  public func cell(at indexPath: IndexPath) -> UIView? {
    return visibleCellToIndexMap[indexPath]
  }

  public func frameForCell(at indexPath: IndexPath?) -> CGRect? {
    if let indexPath = indexPath, let section = framesForCells(in: indexPath.section) {
      if section.count > indexPath.item {
        return section[indexPath.item]
      }
    }
    return nil
  }

  public func framesForCells(in section: Int) -> [CGRect]? {
    if section < 0 {
      return nil
    } else {
      return frames.count > section ? frames[section] : nil
    }
  }
}
