//
//  MCollectionView.swift
//  MCollectionView
//
//  Created by YiLun Zhao on 2016-02-12.
//  Copyright © 2016 lkzhao. All rights reserved.
//

import UIKit

@objc public protocol MCollectionViewDelegate{
  optional func numberOfSectionsInCollectionView(collectionView:MCollectionView) -> Int
  func collectionView(collectionView:MCollectionView, numberOfItemsInSection section:Int) -> Int
  func collectionView(collectionView:MCollectionView, viewForIndexPath indexPath:NSIndexPath, initialFrame:CGRect) -> UIView
  func collectionView(collectionView:MCollectionView, frameForIndexPath indexPath:NSIndexPath) -> CGRect
  func collectionView(collectionView:MCollectionView, identifierForIndexPath indexPath:NSIndexPath) -> String


  optional func collectionViewWillReload(collectionView:MCollectionView)
  optional func collectionViewDidReload(collectionView:MCollectionView)

  optional func collectionView(collectionView:MCollectionView, didInsertCellView cellView: UIView, atIndexPath indexPath: NSIndexPath)
  optional func collectionView(collectionView:MCollectionView, didDeleteCellView cellView: UIView, atIndexPath indexPath: NSIndexPath)
  optional func collectionView(collectionView:MCollectionView, didReloadCellView cellView: UIView, atIndexPath indexPath: NSIndexPath)
  optional func collectionView(collectionView:MCollectionView, didMoveCellView cellView: UIView, fromIndexPath: NSIndexPath, toIndexPath:NSIndexPath)

  optional func collectionView(collectionView:MCollectionView, cellView:UIView, didAppearForIndexPath indexPath:NSIndexPath)
  optional func collectionView(collectionView:MCollectionView, cellView:UIView, willDisappearForIndexPath indexPath:NSIndexPath)
  optional func collectionView(collectionView:MCollectionView, cellView:UIView, didUpdateScreenPositionForIndexPath indexPath:NSIndexPath, screenPosition:CGPoint)
}

public class MCollectionView: MScrollView {
  public var debugName:String = ""
  public weak var collectionDelegate:MCollectionViewDelegate?

  // the computed frames for cells, constructed in reloadData
  var frames:[[CGRect]] = []

  // if autoLayoutOnUpdate is enabled. cell will have their corresponding frame 
  // set when they are loaded or when the collection view scrolls
  // turn this off if you want to have different frame set
  public var autoLayoutOnUpdate = true
  
  // Remove cell from view hierarchy if the cell is being deleted.
  // Might want to turn this off if you want to do some animation when
  // cell is being deleted
  public var autoRemoveCells = true
  
  public var wabble = false

  public var innerSize:CGSize {
    return CGSizeMake(bounds.width - contentInset.left - contentInset.right, bounds.height - contentInset.top - contentInset.bottom)
  }

  // Continuous Layout optimization
  public var optimizeForContinuousLayout = false
  var visibleIndexStart = NSIndexPath(forItem: 0, inSection: 0)
  var visibleIndexEnd = NSIndexPath(forItem: 0, inSection: 0)
  public var visibleIndexes:Set<NSIndexPath> = []
  public var visibleCells:[UIView]{
    var cells:[UIView] = []
    for cellIndex in visibleIndexes{
      if let cell = cellForIndexPath(cellIndex){
        cells.append(cell)
      }
    }
    return cells
  }

  public func previousIndex(index:NSIndexPath) -> NSIndexPath?{
    if index.item > 0{
      return NSIndexPath(forItem: index.item - 1, inSection: index.section)
    }
    var currentSection = (frames:framesForSectionIndex(index.section - 1), sectionIndex: index.section - 1)
    while currentSection.frames != nil{
      if currentSection.frames!.count > 0 {
        return NSIndexPath(forItem:currentSection.frames!.count - 1, inSection: currentSection.sectionIndex)
      }
      currentSection = (framesForSectionIndex(currentSection.sectionIndex - 1), currentSection.sectionIndex - 1)
    }
    return nil
  }
  public func nextIndex(index:NSIndexPath) -> NSIndexPath?{
    if let sectionFrames = framesForSectionIndex(index.section) where sectionFrames.count > index.item + 1{
      return NSIndexPath(forItem: index.item + 1, inSection: index.section)
    }
    var currentSection = (frames:framesForSectionIndex(index.section + 1), sectionIndex: index.section + 1)
    while currentSection.frames != nil{
      if currentSection.frames!.count > 0 {
        return NSIndexPath(forItem:0, inSection: currentSection.sectionIndex)
      }
      currentSection = (framesForSectionIndex(currentSection.sectionIndex + 1), currentSection.sectionIndex + 1)
    }
    return nil
  }


  var visibleCellToIndexMap:DictionaryTwoWay<UIView, NSIndexPath> = [:]
  var identifiersToIndexMap:DictionaryTwoWay<String, NSIndexPath> = [:]


  public var numberOfItems:Int{
    return frames.reduce(0, combine: { (count, section) -> Int in
      return count + section.count
    })
  }

  var lastReloadFrame:CGRect?
  public override func layoutSubviews() {
    super.layoutSubviews()
    if frame != lastReloadFrame {
      lastReloadFrame = frame
      reloadData()
    }
  }

  func firstVisibleIndex() -> NSIndexPath?{
    let activeFrame = self.activeFrame
    for (i, s) in frames.enumerate(){
      for (j, f) in s.enumerate(){
        if CGRectIntersectsRect(f, activeFrame){
          return NSIndexPath(forItem: j, inSection: i)
        }
      }
    }
    return nil
  }
  func indexesForFramesIntersectingFrame(frame:CGRect) -> Set<NSIndexPath>{
    var intersect:Set<NSIndexPath> = []
    for (i, s) in frames.enumerate(){
      for (j, f) in s.enumerate(){
        if CGRectIntersectsRect(f, frame){
          intersect.insert(NSIndexPath(forItem: j, inSection: i))
        }
      }
    }
    return intersect
  }
  func calculateVisibleIndexesUsingOptimizedMethod() -> Set<NSIndexPath> {
    var indexes = Set<NSIndexPath>()
    let currentFrame = activeFrame

    for index in visibleIndexes{
      if let cellFrame = frameForIndexPath(index) where CGRectIntersectsRect(cellFrame, currentFrame) {
        indexes.insert(index)
      }
    }

    var nextIndex:NSIndexPath? = visibleIndexEnd
    var nextCellFrame = frameForIndexPath(nextIndex)
    while (nextCellFrame != nil && CGRectIntersectsRect(nextCellFrame!, currentFrame)){
      indexes.insert(nextIndex!)
      visibleIndexEnd = nextIndex!
      nextIndex = self.nextIndex(nextIndex!)
      nextCellFrame = frameForIndexPath(nextIndex)
    }

    var prevIndex:NSIndexPath? = self.previousIndex(visibleIndexStart)
    var prevCellFrame = frameForIndexPath(prevIndex)
    while (prevCellFrame != nil && CGRectIntersectsRect(prevCellFrame!, currentFrame)){
      indexes.insert(prevIndex!)
      visibleIndexStart = prevIndex!
      prevIndex = self.previousIndex(prevIndex!)
      prevCellFrame = frameForIndexPath(prevIndex)
    }

    while (visibleIndexStart != visibleIndexEnd){
      if let cellFrame = frameForIndexPath(visibleIndexStart) where CGRectIntersectsRect(cellFrame, currentFrame) {
        break;
      }
      visibleIndexStart = self.nextIndex(visibleIndexStart) ?? visibleIndexEnd
    }

    while (visibleIndexStart != visibleIndexEnd){
      if let cellFrame = frameForIndexPath(visibleIndexEnd) where CGRectIntersectsRect(cellFrame, currentFrame) {
        break;
      }
      visibleIndexEnd = self.previousIndex(visibleIndexEnd) ?? visibleIndexStart
    }
    return indexes
  }
  func calculateVisibleIndexesFromActiveFrame() -> Set<NSIndexPath>{
    var indexes:Set<NSIndexPath>
    if optimizeForContinuousLayout {
      indexes = calculateVisibleIndexesUsingOptimizedMethod()

      // no visible cell found. we might be
      if visibleIndexStart == visibleIndexEnd{
        if let firstVisible = firstVisibleIndex(){
          visibleIndexStart = firstVisible
          visibleIndexEnd = firstVisible
          indexes = calculateVisibleIndexesUsingOptimizedMethod()
        }
      }
//      print(visibleIndexStart, visibleIndexEnd)
    } else {
      indexes = indexesForFramesIntersectingFrame(activeFrame)
    }
    for f in floatingCells{
      if let index = visibleCellToIndexMap[f]{
        indexes.insert(index)
      }
    }
    return indexes
  }
  
  public func indexPathForItemAtPoint(point:CGPoint) -> NSIndexPath?{
    for (i, s) in frames.enumerate(){
      for (j, f) in s.enumerate(){
        if f.contains(point){
          return NSIndexPath(forItem: j, inSection: i)
        }
      }
    }
    return nil
  }

  public func cellForIndexPath(indexPath:NSIndexPath) -> UIView?{
    return visibleCellToIndexMap[indexPath]
  }

  private var reusableViews:[String:[UIView]] = [:]
  public func dequeueReusableView<T:UIView> (viewClass: T.Type) -> T?{
    return reusableViews[String(viewClass)]?.popLast() as? T
  }

  public func frameForIndexPath(indexPath:NSIndexPath?) -> CGRect?{
    if let indexPath = indexPath, section = framesForSectionIndex(indexPath.section){
      if section.count > indexPath.item {
        return section[indexPath.item]
      }
    }
    return nil
  }
  public func framesForSectionIndex(index:Int) -> [CGRect]?{
    if index < 0{
      return nil
    } else {
      return frames.count > index ? frames[index] : nil
    }
  }

  private func removeCellFrom(inout map:DictionaryTwoWay<UIView, NSIndexPath>, atIndexPath indexPath:NSIndexPath){
    if let cell = map[indexPath]{
      collectionDelegate?.collectionView?(self, cellView: cell, willDisappearForIndexPath: indexPath)
      cell.m_removeAnimationForKey("center")
      cell.removeFromSuperview()

      let identifier = "\(cell.dynamicType)"
      if reusableViews[identifier] != nil && !reusableViews[identifier]!.contains(cell){
        reusableViews[identifier]?.append(cell)
      } else {
        reusableViews[identifier] = [cell]
      }
      map.remove(indexPath)
    }
  }
  private func insertCellTo(inout map:DictionaryTwoWay<UIView, NSIndexPath>, atIndexPath indexPath:NSIndexPath){
    if let cell = collectionDelegate?.collectionView(self, viewForIndexPath: indexPath, initialFrame: frameForIndexPath(indexPath)!) where map[cell] == nil{
      map[cell] = indexPath
      contentView.addSubview(cell)
      collectionDelegate?.collectionView?(self, cellView: cell, didAppearForIndexPath: indexPath)
    }
  }
  private func deleteOnScreenCellAtIndex(indexPath:NSIndexPath){
    if let cell = visibleCellToIndexMap[indexPath]{
      if autoRemoveCells {
        cell.removeFromSuperview()
      }
      collectionDelegate?.collectionView?(self, didDeleteCellView: cell, atIndexPath: indexPath)
      visibleCellToIndexMap.remove(indexPath)
    }
  }
  private func insertOnScreenCellTo(inout map:DictionaryTwoWay<UIView, NSIndexPath>, atIndexPath indexPath:NSIndexPath){
    if let cell = collectionDelegate?.collectionView(self, viewForIndexPath: indexPath, initialFrame: frameForIndexPath(indexPath)!) where map[cell] == nil{
      map[cell] = indexPath
      contentView.addSubview(cell)
      collectionDelegate?.collectionView?(self, didInsertCellView: cell, atIndexPath: indexPath)
    }
  }

  public var activeFrameSlop:UIEdgeInsets?{
    didSet{
      if !reloading && activeFrameSlop != oldValue{
        loadCells()
      }
    }
  }
  public var activeFrame:CGRect{
    if let activeFrameSlop = activeFrameSlop{
      return CGRectMake(visibleFrame.origin.x + activeFrameSlop.left, visibleFrame.origin.y + activeFrameSlop.top, visibleFrame.width - activeFrameSlop.left - activeFrameSlop.right, visibleFrame.height - activeFrameSlop.top - activeFrameSlop.bottom)
    } else if wabble {
      let maxDim = max(bounds.width, bounds.height) + 200
      return CGRectInset(visibleFrame, -(maxDim - bounds.width), -(maxDim - bounds.height))
    } else {
      return visibleFrame
    }
  }

  /*
   * Update visibleCells & visibleIndexes according to scrollView's visibleFrame
   * load the view for cells that move into the visibleFrame and recycles them when
   * they move out of the visibleFrame.
   */
  private func loadCells(){
    let indexes = calculateVisibleIndexesFromActiveFrame()
    let deletedIndexes = visibleIndexes.subtract(indexes)
    let newIndexes = indexes.subtract(visibleIndexes)
    for i in deletedIndexes{
      removeCellFrom(&visibleCellToIndexMap, atIndexPath: i)
    }
    for i in newIndexes{
      insertCellTo(&visibleCellToIndexMap, atIndexPath: i)
    }
    visibleIndexes = indexes
    layoutCellsIfNecessary()
    for (indexPath, cell) in visibleCellToIndexMap.ts{
      collectionDelegate?.collectionView?(self, cellView:cell, didUpdateScreenPositionForIndexPath:indexPath, screenPosition:cell.center - contentOffset)
    }
  }

  public func adjustedRect(indexPath:NSIndexPath) -> CGRect{
    let screenDragLocation = contentOffset + dragLocation
    let cellFrame = frameForIndexPath(indexPath)!
    //        let cellOffset = abs(cellFrame.center.y - screenDragLocation.y) * collectionView.scrollVelocity / 5000
    let cellOffset = cellFrame.center.distance(screenDragLocation) * scrollVelocity / 5000
    return CGRect(origin: cellFrame.origin + cellOffset, size: cellFrame.size)
  }



  public func indexPathOfView(view:UIView) -> NSIndexPath?{
    if reloading {
      fatalError("shouldn't call index of view during reload -> wrong index might be returned")
    }
    return visibleCellToIndexMap[view]
  }

  public func reloadCellAtIndexPath(indexPath:NSIndexPath){
    if visibleIndexes.contains(indexPath) {
      removeCellFrom(&visibleCellToIndexMap, atIndexPath: indexPath)
      insertCellTo(&visibleCellToIndexMap, atIndexPath: indexPath)
    }
  }

  public private(set) var reloading = false
  // reload number of cells and all their frames
  // similar to [UICollectionView invalidateLayout]
  public func reloadData(framesLoadedBlock:(()->Void)? = nil){
//    print("\(debugName) reloadData")
    if debugName == ""{

    }
    self.collectionDelegate?.collectionViewWillReload?(self)
    reloading = true
    frames = []
    var newIdentifiersToIndexMap:DictionaryTwoWay<String,NSIndexPath> = [:]
    var newVisibleCellToIndexMap:DictionaryTwoWay<UIView,NSIndexPath> = [:]
    var unionFrame = CGRectZero
    let count = collectionDelegate?.numberOfSectionsInCollectionView?(self) ?? 1
    
    frames.reserveCapacity(count)
    for i in 0..<count{
      let sectionItemsCount = collectionDelegate?.collectionView(self, numberOfItemsInSection: i) ?? 0
      frames.append([CGRect]())
      for j in 0..<sectionItemsCount{
        let indexPath = NSIndexPath(forItem: j, inSection: i)
        let frame = collectionDelegate!.collectionView(self, frameForIndexPath: indexPath)
        let identifier = collectionDelegate!.collectionView(self, identifierForIndexPath: indexPath)
        newIdentifiersToIndexMap[identifier] = indexPath
        unionFrame = CGRectUnion(unionFrame, frame)
        frames[i].append(frame)
      }
    }
    
    contentSize = unionFrame.size
    let oldContentOffset = contentOffset
    framesLoadedBlock?()
    let contentOffsetDiff = contentOffset - oldContentOffset
    if let targetY = scrollAnimation.targetOffsetY {
      scrollAnimation.targetOffsetY = targetY + contentOffsetDiff.y
    }
    if let targetX = scrollAnimation.targetOffsetX {
      scrollAnimation.targetOffsetX = targetX + contentOffsetDiff.x
    }

    visibleIndexStart = firstVisibleIndex() ?? NSIndexPath(forItem: 0, inSection: 0)
    visibleIndexEnd = visibleIndexStart
    let newVisibleIndexes = calculateVisibleIndexesFromActiveFrame()

    let newVisibleIdentifiers = Set(newVisibleIndexes.map { index in
      return newIdentifiersToIndexMap[index]!
    })
    let oldVisibleIdentifiers = Set(visibleIndexes.map { index in
      return identifiersToIndexMap[index]!
    })

    let deletedVisibleIdentifiers = oldVisibleIdentifiers.subtract(newVisibleIdentifiers)
    let insertedVisibleIdentifiers = newVisibleIdentifiers.subtract(oldVisibleIdentifiers)
    let existingVisibleIdentifiers = newVisibleIdentifiers.intersect(oldVisibleIdentifiers)

    for identifier in existingVisibleIdentifiers{
      // move the cell to a different index
      let oldIndex = identifiersToIndexMap[identifier]!
      let newIndex = newIdentifiersToIndexMap[identifier]!
      let cell = visibleCellToIndexMap[oldIndex]!
      cell.center = cell.center + contentOffsetDiff
      newVisibleCellToIndexMap[newIndex] = cell
      if oldIndex == newIndex{
        collectionDelegate?.collectionView?(self, didReloadCellView: cell, atIndexPath: newIndex)
      } else {
        collectionDelegate?.collectionView?(self, didMoveCellView: cell, fromIndexPath: oldIndex, toIndexPath: newIndex)
      }
    }
    for identifier in deletedVisibleIdentifiers{
      // delete the cell
      deleteOnScreenCellAtIndex(identifiersToIndexMap[identifier]!)
    }
    for identifier in insertedVisibleIdentifiers{
      // insert the cell
      insertOnScreenCellTo(&newVisibleCellToIndexMap, atIndexPath: newIdentifiersToIndexMap[identifier]!)
    }

    visibleIndexes = newVisibleIndexes
    visibleCellToIndexMap = newVisibleCellToIndexMap
    identifiersToIndexMap = newIdentifiersToIndexMap
    layoutCellsIfNecessary()
    for (index, cell) in visibleCellToIndexMap.ts{
      collectionDelegate?.collectionView?(self, cellView:cell, didUpdateScreenPositionForIndexPath:index, screenPosition:cell.center - contentOffset)
    }
    reloading = false
    self.collectionDelegate?.collectionViewDidReload?(self)
  }

  public var floatingCells:[UIView] = []
  public func layoutCellsIfNecessary(){
    if autoLayoutOnUpdate {
      for (indexPath, cell) in visibleCellToIndexMap.ts{
        if !floatingCells.contains(cell) {
          if wabble {
            cell.m_animate("center", to:adjustedRect(indexPath).center, stiffness: 150, damping:20, threshold: 1)
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
    if !reloading{
      loadCells()
      super.didScroll()
    }
  }

  var cleanupTimer:NSTimer?
  override func didEndScroll() {
    super.didEndScroll()
    cleanupTimer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: #selector(cleanup), userInfo: nil, repeats: false)
  }
  
  func cleanup(){
    reusableViews.removeAll()
  }

  deinit{
    print("MCollectionView \(self.debugName) deinit")
  }
}