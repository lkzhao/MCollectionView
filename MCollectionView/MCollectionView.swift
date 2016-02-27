//
//  MCollectionView.swift
//  MCollectionViewExample
//
//  Created by YiLun Zhao on 2016-02-12.
//  Copyright © 2016 lkzhao. All rights reserved.
//

import UIKit
import Changeset

protocol MCollectionViewDataSource{
  func numberOfItemsInCollectionView(collectionView:MCollectionView) -> Int
  func collectionView(collectionView:MCollectionView, viewForIndex:Int) -> UIView
  func collectionView(collectionView:MCollectionView, frameForIndex:Int) -> CGRect
  func collectionView(collectionView:MCollectionView, identifierForIndex:Int) -> String

  // todo move to delegate
  func collectionView(collectionView:MCollectionView, didInsertCellView cellView: UIView, atIndex index: Int)
  func collectionView(collectionView:MCollectionView, didDeleteCellView cellView: UIView, atIndex index: Int)

  func collectionView(collectionView:MCollectionView, cellView:UIView, didAppearForIndex index:Int)
  func collectionView(collectionView:MCollectionView, cellView:UIView, willDisappearForIndex index:Int)
  func collectionView(collectionView:MCollectionView, cellView:UIView, didUpdateScreenPositionForIndex index:Int, screenPosition:CGPoint)
}

class MCollectionView: MScrollView {
  var dataSource:MCollectionViewDataSource?

  // the computed frames for cells, constructed in reloadData
  var frames:[CGRect] = []

  // if autoLayoutOnUpdate is enabled. cell will have their corresponding frame 
  // set when they are loaded or when the collection view scrolls
  // turn this off if you want to have different frame set
  var autoLayoutOnUpdate = true

  var visibleCellToIndexMap:DictionaryTwoWay<UIView, Int> = [:]
  var identifiersToIndexMap:DictionaryTwoWay<String, Int> = [:]

  var visibleIndexes:Set<Int> = []

  override init(frame: CGRect) {
    super.init(frame: frame)
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }

  override func layoutSubviews() {
    // size changed.
    // ask the dataSource for new cell frames
    reloadData()
    super.layoutSubviews()
  }

  func indexesForFrames(frames:[CGRect], intersectFrame frame:CGRect) -> Set<Int>{
    var intersect:Set<Int> = []
    for (i, f) in frames.enumerate(){
      if CGRectIntersectsRect(f, frame){
        intersect.insert(i)
      }
    }
    return intersect
  }
  
  func indexForItemAtPoint(point:CGPoint) -> Int?{
    for (i, f) in frames.enumerate(){
      if f.contains(point){
        return i
      }
    }
    return nil
  }

  var reusableViews:[String:[UIView]] = [:]
  func dequeueReusableViewWithIdentifier(identifier:String) -> UIView?{
    return reusableViews[identifier]?.popLast()
  }

  private func removeCellFrom(inout map:DictionaryTwoWay<UIView, Int>, atIndex index:Int){
    if let cell = map[index]{
      dataSource?.collectionView(self, cellView: cell, willDisappearForIndex: index)
      cell.stopAllAnimation()
      cell.removeFromSuperview()
      if let reusable = cell as? MCollectionReuseable, identifier = reusable.reuseIdentifier{
        if reusableViews[identifier] != nil && !reusableViews[identifier]!.contains(cell){
          reusableViews[identifier]?.append(cell)
        } else {
          reusableViews[identifier] = [cell]
        }
      }
      map.remove(index)
    }
  }
  private func insertCellTo(inout map:DictionaryTwoWay<UIView, Int>, atIndex index:Int){
    if let cell = dataSource?.collectionView(self, viewForIndex: index) where map[cell] == nil{
      map[cell] = index
      contentView.addSubview(cell)
      dataSource?.collectionView(self, cellView: cell, didAppearForIndex: index)
    }
  }
  private func deleteOnScreenCellAtIndex(index:Int){
    if let cell = visibleCellToIndexMap[index]{
      dataSource?.collectionView(self, didDeleteCellView: cell, atIndex: index)
      visibleCellToIndexMap.remove(index)
    }
  }
  private func insertOnScreenCellTo(inout map:DictionaryTwoWay<UIView, Int>, atIndex index:Int){
    if let cell = dataSource?.collectionView(self, viewForIndex: index) where map[cell] == nil{
      map[cell] = index
      contentView.addSubview(cell)
      dataSource?.collectionView(self, didInsertCellView: cell, atIndex: index)
    }
  }

  var activeFrame:CGRect{
    let maxDim = max(bounds.width, bounds.height) + 200
    return CGRectInset(visibleFrame, -(maxDim - bounds.width), -(maxDim - bounds.height))
  }

  /*
   * Update visibleCells & visibleIndexes according to scrollView's visibleFrame
   * load the view for cells that move into the visibleFrame and recycles them when
   * they move out of the visibleFrame.
   */
  private func loadCells(){
    let indexes = indexesForFrames(frames, intersectFrame: activeFrame)
    let deletedIndexes = visibleIndexes.subtract(indexes)
    let newIndexes = indexes.subtract(visibleIndexes)
    for i in deletedIndexes{
      removeCellFrom(&visibleCellToIndexMap, atIndex: i)
    }
    for i in newIndexes{
      insertCellTo(&visibleCellToIndexMap, atIndex: i)
    }
    visibleIndexes = indexes
    layoutCellsIfNecessary()
    for (index, cell) in visibleCellToIndexMap.ts{
      dataSource?.collectionView(self, cellView:cell, didUpdateScreenPositionForIndex:index, screenPosition:cell.center - contentOffset)
    }
  }



  func indexOfView(view:UIView) -> Int?{
    return visibleCellToIndexMap[view]
  }


  var reloading = false
  // reload number of cells and all their frames
  // similar to [UICollectionView invalidateLayout]
  func reloadData(framesLoadedBlock:(()->Void)? = nil){
    reloading = true
    frames = []
    var newIdentifiersToIndexMap:DictionaryTwoWay<String,Int> = [:]
    var newVisibleCellToIndexMap:DictionaryTwoWay<UIView,Int> = [:]
    if let count = dataSource?.numberOfItemsInCollectionView(self){
      frames.reserveCapacity(count)
      var unionFrame = CGRectZero
      for i in 0..<count{
        let frame = dataSource!.collectionView(self, frameForIndex: i)
        let identifier = dataSource!.collectionView(self, identifierForIndex: i)
        newIdentifiersToIndexMap[identifier] = i
        unionFrame = CGRectUnion(unionFrame, frame)
        frames.append(frame)
      }
      contentSize = unionFrame.size
    }
    let oldContentOffset = contentOffset
    framesLoadedBlock?()
    let contentOffsetDiff = contentOffset - oldContentOffset
    

    let newVisibleIndexes = indexesForFrames(frames, intersectFrame: activeFrame)

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
      let cell = visibleCellToIndexMap[identifiersToIndexMap[identifier]!]
      cell!.center = cell!.center + contentOffsetDiff
      newVisibleCellToIndexMap[newIdentifiersToIndexMap[identifier]!] = cell
    }
    for identifier in deletedVisibleIdentifiers{
      // delete the cell
      deleteOnScreenCellAtIndex(identifiersToIndexMap[identifier]!)
    }
    for identifier in insertedVisibleIdentifiers{
      // insert the cell
      insertOnScreenCellTo(&newVisibleCellToIndexMap, atIndex: newIdentifiersToIndexMap[identifier]!)
    }

    visibleIndexes = newVisibleIndexes
    visibleCellToIndexMap = newVisibleCellToIndexMap
    identifiersToIndexMap = newIdentifiersToIndexMap
    layoutCellsIfNecessary()
    for (index, cell) in visibleCellToIndexMap.ts{
      dataSource?.collectionView(self, cellView:cell, didUpdateScreenPositionForIndex:index, screenPosition:cell.center - contentOffset)
    }
    reloading = false
  }

  func layoutCellsIfNecessary(){
    if autoLayoutOnUpdate {
      for (index, cell) in visibleCellToIndexMap.ts{
        cell.bounds = frames[index].bounds
        cell.center = frames[index].center
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
    cleanupTimer = NSTimer.schedule(delay: 0.1) { (timer) -> Void in
      self.reusableViews.removeAll()
    }
  }
}
