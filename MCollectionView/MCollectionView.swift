//
//  MCollectionView.swift
//  MCollectionView
//
//  Created by YiLun Zhao on 2016-02-12.
//  Copyright © 2016 lkzhao. All rights reserved.
//

import UIKit

open class MCollectionView: MScrollView {
  open var debugName: String = ""
  open weak var collectionDelegate: MCollectionViewDelegate?

  // the computed frames for cells, constructed in reloadData
  var frames: [[CGRect]] = []

  // if autoLayoutOnUpdate is enabled. cell will have their corresponding frame 
  // set when they are loaded or when the collection view scrolls
  // turn this off if you want to manually set its frame
  open var autoLayoutOnUpdate = true

  // Remove cell from view hierarchy if the cell is being deleted.
  // Might want to turn this off if you want to do some animation when
  // cell is being deleted
  open var autoRemoveCells = true

  // wabble animation
  open var wabble = false

  // for moving cells
  var pressGR: UILongPressGestureRecognizer!

  // inner size is the frame size minus the inset
  open var innerSize: CGSize {
    return CGSize(width: bounds.width - contentInset.left - contentInset.right, height: bounds.height - contentInset.top - contentInset.bottom)
  }

  // Continuous Layout optimization
  open var optimizeForContinuousLayout = false

  override init(frame: CGRect) {
    super.init(frame: frame)
    initialize()
  }

  public required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    initialize()
  }

  func initialize() {
    pressGR = UILongPressGestureRecognizer(target: self, action: #selector(press))
    pressGR.delegate = self
    pressGR.minimumPressDuration = 0.5
    addGestureRecognizer(pressGR)
  }

  func press() {
    switch pressGR.state {
    case .began:
      if let indexPath = indexPathForItemAtPoint(pressGR.location(in: self)),
        collectionDelegate?.collectionView?(self, canMoveItemAt: indexPath) == true {
        // TODO
      }
      break
    case .changed:
      break
    default:
      break
    }
  }

  var visibleIndexStart = IndexPath(item: 0, section: 0)
  var visibleIndexEnd = IndexPath(item: 0, section: 0)
  open var visibleIndexes: Set<IndexPath> = []
  open var visibleCells: [UIView] {
    var cells: [UIView] = []
    for cellIndex in visibleIndexes {
      if let cell = cellForIndexPath(cellIndex) {
        cells.append(cell)
      }
    }
    return cells
  }

  var visibleCellToIndexMap: DictionaryTwoWay<UIView, IndexPath> = [:]
  var identifiersToIndexMap: DictionaryTwoWay<String, IndexPath> = [:]

  open var numberOfItems: Int {
    return frames.reduce(0, { (count, section) -> Int in
      return count + section.count
    })
  }

  var lastReloadFrame: CGRect?
  open override func layoutSubviews() {
    super.layoutSubviews()
    if frame != lastReloadFrame {
      lastReloadFrame = frame
      reloadData()
    }
  }

  func firstVisibleIndex() -> IndexPath? {
    let activeFrame = self.activeFrame
    for (i, s) in frames.enumerated() {
      for (j, f) in s.enumerated() {
        if f.intersects(activeFrame) {
          return IndexPath(item: j, section: i)
        }
      }
    }
    return nil
  }

  func indexesForFramesIntersectingFrame(_ frame: CGRect) -> Set<IndexPath> {
    var intersect: Set<IndexPath> = []
    for (i, s) in frames.enumerated() {
      for (j, f) in s.enumerated() {
        if f.intersects(frame) {
          intersect.insert(IndexPath(item: j, section: i))
        }
      }
    }
    return intersect
  }

  open func indexPathForItemAtPoint(_ point: CGPoint) -> IndexPath? {
    for (i, s) in frames.enumerated() {
      for (j, f) in s.enumerated() {
        if f.contains(point) {
          return IndexPath(item: j, section: i)
        }
      }
    }
    return nil
  }

  open func cellForIndexPath(_ indexPath: IndexPath) -> UIView? {
    return visibleCellToIndexMap[indexPath]
  }

  open func frameForIndexPath(_ indexPath: IndexPath?) -> CGRect? {
    if let indexPath = indexPath, let section = framesForSectionIndex((indexPath as NSIndexPath).section) {
      if section.count > (indexPath as NSIndexPath).item {
        return section[(indexPath as NSIndexPath).item]
      }
    }
    return nil
  }
  open func framesForSectionIndex(_ index: Int) -> [CGRect]? {
    if index < 0 {
      return nil
    } else {
      return frames.count > index ? frames[index] : nil
    }
  }

  fileprivate var reusableViews: [String:[UIView]] = [:]
  open func dequeueReusableView<T: UIView> (_ viewClass: T.Type) -> T? {
    return reusableViews[String(describing: viewClass)]?.popLast() as? T
  }

  fileprivate func removeCellFrom(_ map:inout DictionaryTwoWay<UIView, IndexPath>, atIndexPath indexPath: IndexPath) {
    if let cell = map[indexPath] {
      collectionDelegate?.collectionView?(self, cellView: cell, willDisappearForIndexPath: indexPath)
      cell.m_removeAnimationForKey("center")
      cell.removeFromSuperview()

      let identifier = "\(type(of: cell))"
      if reusableViews[identifier] != nil && !reusableViews[identifier]!.contains(cell) {
        reusableViews[identifier]?.append(cell)
      } else {
        reusableViews[identifier] = [cell]
      }
      map.remove(indexPath)
    }
  }
  fileprivate func insertCellTo(_ map:inout DictionaryTwoWay<UIView, IndexPath>, atIndexPath indexPath: IndexPath) {
    if let cell = collectionDelegate?.collectionView(self, viewForIndexPath: indexPath, initialFrame: frameForIndexPath(indexPath)!), map[cell] == nil {
      map[cell] = indexPath
      contentView.addSubview(cell)
      collectionDelegate?.collectionView?(self, cellView: cell, didAppearForIndexPath: indexPath)
    }
  }
  fileprivate func deleteOnScreenCellAtIndex(_ indexPath: IndexPath) {
    if let cell = visibleCellToIndexMap[indexPath] {
      if autoRemoveCells {
        cell.removeFromSuperview()
      }
      collectionDelegate?.collectionView?(self, didDeleteCellView: cell, atIndexPath: indexPath)
      visibleCellToIndexMap.remove(indexPath)
    }
  }
  fileprivate func insertOnScreenCellTo(_ map:inout DictionaryTwoWay<UIView, IndexPath>, atIndexPath indexPath: IndexPath) {
    if let cell = collectionDelegate?.collectionView(self, viewForIndexPath: indexPath, initialFrame: frameForIndexPath(indexPath)!), map[cell] == nil {
      map[cell] = indexPath
      contentView.addSubview(cell)
      collectionDelegate?.collectionView?(self, didInsertCellView: cell, atIndexPath: indexPath)
    }
  }

  open var activeFrameSlop: UIEdgeInsets? {
    didSet {
      if !reloading && activeFrameSlop != oldValue {
        loadCells()
      }
    }
  }
  open var activeFrame: CGRect {
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
   * load the view for cells that move into the visibleFrame and recycles them when
   * they move out of the visibleFrame.
   */
  fileprivate func loadCells() {
    let indexes = calculateVisibleIndexesFromActiveFrame()
    let deletedIndexes = visibleIndexes.subtracting(indexes)
    let newIndexes = indexes.subtracting(visibleIndexes)
    for i in deletedIndexes {
      removeCellFrom(&visibleCellToIndexMap, atIndexPath: i)
    }
    for i in newIndexes {
      insertCellTo(&visibleCellToIndexMap, atIndexPath: i)
    }
    visibleIndexes = indexes
    layoutCellsIfNecessary()
    for (indexPath, cell) in visibleCellToIndexMap.ts {
      collectionDelegate?.collectionView?(self, cellView:cell, didUpdateScreenPositionForIndexPath:indexPath, screenPosition:cell.center - contentOffset)
    }
  }

  open func wabbleRect(_ indexPath: IndexPath) -> CGRect {
    let screenDragLocation = contentOffset + dragLocation
    let cellFrame = frameForIndexPath(indexPath)!
    let cellOffset = cellFrame.center.distance(screenDragLocation) * scrollVelocity / 5000
    return CGRect(origin: cellFrame.origin + cellOffset, size: cellFrame.size)
  }

  open func indexPathOfView(_ view: UIView) -> IndexPath? {
    if reloading {
      fatalError("shouldn't call index of view during reload -> wrong index might be returned")
    }
    return visibleCellToIndexMap[view]
  }

  open func reloadCellAtIndexPath(_ indexPath: IndexPath) {
    if visibleIndexes.contains(indexPath) {
      removeCellFrom(&visibleCellToIndexMap, atIndexPath: indexPath)
      insertCellTo(&visibleCellToIndexMap, atIndexPath: indexPath)
    }
  }

  open fileprivate(set) var reloading = false
  // reload number of cells and all their frames
  // similar to [UICollectionView invalidateLayout]
  open func reloadData(_ framesLoadedBlock:(() -> Void)? = nil) {
//    print("\(debugName) reloadData")
    self.collectionDelegate?.collectionViewWillReload?(self)
    reloading = true
    frames = []
    var newIdentifiersToIndexMap: DictionaryTwoWay<String, IndexPath> = [:]
    var newVisibleCellToIndexMap: DictionaryTwoWay<UIView, IndexPath> = [:]
    var unionFrame = CGRect.zero
    let count = collectionDelegate?.numberOfSectionsInCollectionView?(self) ?? 1

    frames.reserveCapacity(count)
    for i in 0..<count {
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

    contentFrame = unionFrame
    let oldContentOffset = contentOffset
    framesLoadedBlock?()
    let contentOffsetDiff = contentOffset - oldContentOffset
    if let targetY = scrollAnimation.targetOffsetY {
      scrollAnimation.targetOffsetY = targetY + contentOffsetDiff.y
    }
    if let targetX = scrollAnimation.targetOffsetX {
      scrollAnimation.targetOffsetX = targetX + contentOffsetDiff.x
    }

    visibleIndexStart = firstVisibleIndex() ?? IndexPath(item: 0, section: 0)
    visibleIndexEnd = visibleIndexStart
    let newVisibleIndexes = calculateVisibleIndexesFromActiveFrame()

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
      // delete the cell
      deleteOnScreenCellAtIndex(identifiersToIndexMap[identifier]!)
    }
    for identifier in insertedVisibleIdentifiers {
      // insert the cell
      insertOnScreenCellTo(&newVisibleCellToIndexMap, atIndexPath: newIdentifiersToIndexMap[identifier]!)
    }

    visibleIndexes = newVisibleIndexes
    visibleCellToIndexMap = newVisibleCellToIndexMap
    identifiersToIndexMap = newIdentifiersToIndexMap
    layoutCellsIfNecessary()
    for (index, cell) in visibleCellToIndexMap.ts {
      collectionDelegate?.collectionView?(self, cellView:cell, didUpdateScreenPositionForIndexPath:index, screenPosition:cell.center - contentOffset)
    }
    reloading = false
    self.collectionDelegate?.collectionViewDidReload?(self)
  }

  open var floatingCells: [UIView] = []
  open func layoutCellsIfNecessary() {
    if autoLayoutOnUpdate {
      for (indexPath, cell) in visibleCellToIndexMap.ts {
        if !floatingCells.contains(cell) {
          if wabble {
            cell.m_animate("center", to:wabbleRect(indexPath).center, stiffness: 150, damping:20, threshold: 1)
          } else {
            let f = frameForIndexPath(indexPath)!
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

  var cleanupTimer: Timer?
  override func didEndScroll() {
    super.didEndScroll()
    cleanupTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(cleanup), userInfo: nil, repeats: false)
  }

  func cleanup() {
    reusableViews.removeAll()
  }

//  deinit{
//    print("MCollectionView \(self.debugName) deinit")
//  }
}
