//
//  MCollectionView.swift
//  MCollectionViewExample
//
//  Created by YiLun Zhao on 2016-02-12.
//  Copyright © 2016 lkzhao. All rights reserved.
//

import UIKit
import MotionAnimation

protocol MCollectionViewDataSource{
  func numberOfItemsInCollectionView(collectionView:MCollectionView) -> Int
  func collectionView(collectionView:MCollectionView, viewForIndex:Int) -> UIView
  func collectionView(collectionView:MCollectionView, frameForIndex:Int) -> CGRect

  // todo move to delegate
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

  var visibleCells:[Int:UIView] = [:]
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

  func indexesForFrameIntersectFrame(frame:CGRect) -> Set<Int>{
    var intersect:Set<Int> = []
    for (i, f) in frames.enumerate(){
      if CGRectIntersectsRect(f, frame){
        intersect.insert(i)
      }
    }
    return intersect
  }

  var reusableViews:[String:[UIView]] = [:]
  func dequeueReusableViewWithIdentifier(identifier:String) -> UIView?{
    return reusableViews[identifier]?.popLast()
  }

  private func removeCellFromScreenAtIndex(i:Int){
    let cell = visibleCells[i]!
    dataSource?.collectionView(self, cellView: cell, willDisappearForIndex: i)
    cell.stopAllAnimation()
    cell.removeFromSuperview()
    if let reusable = cell as? ReuseableView, identifier = reusable.identifier{
      if reusableViews[identifier] != nil && !reusableViews[identifier]!.contains(cell){
        reusableViews[identifier]?.append(cell)
      } else {
        reusableViews[identifier] = [cell]
      }
    }
    visibleCells.removeValueForKey(i)
  }
  private func insertCellToScreenAtIndex(i:Int){
    if let cell = dataSource?.collectionView(self, viewForIndex: i){
      visibleCells[i] = cell
      contentView.addSubview(cell)
      dataSource?.collectionView(self, cellView: cell, didAppearForIndex: i)
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
    let indexes = indexesForFrameIntersectFrame(activeFrame)
    let deletedIndexes = visibleIndexes.subtract(indexes)
    let newIndexes = indexes.subtract(visibleIndexes)
    for i in deletedIndexes{
      removeCellFromScreenAtIndex(i)
    }
    for i in newIndexes{
      insertCellToScreenAtIndex(i)
    }
    visibleIndexes = indexes
    layoutCellsIfNecessary()
    for (index, cell) in visibleCells{
      dataSource?.collectionView(self, cellView:cell, didUpdateScreenPositionForIndex:index, screenPosition:cell.center - contentOffset)
    }
  }

  // reload number of cells and all their frames
  // similar to [UICollectionView invalidateLayout]
  func reloadData(){
    frames = []
    if let count = dataSource?.numberOfItemsInCollectionView(self){
      var unionFrame = CGRectZero
      for i in 0..<count{
        let frame = dataSource!.collectionView(self, frameForIndex: i)
        unionFrame = CGRectUnion(unionFrame, frame)
        frames.append(frame)
      }
      contentSize = unionFrame.size
      loadCells()
    }
  }

  func layoutCellsIfNecessary(){
    if autoLayoutOnUpdate {
      for (index, cell) in visibleCells{
        cell.bounds = frames[index].bounds
        cell.center = frames[index].center
      }
    }
  }

  override func didScroll() {
    cleanupTimer?.invalidate()
    loadCells()
    super.didScroll()
  }

  var cleanupTimer:NSTimer?
  override func didEndScroll() {
    super.didEndScroll()
    cleanupTimer = NSTimer.schedule(delay: 0.1) { (timer) -> Void in
      self.reusableViews.removeAll()
    }
  }
}
