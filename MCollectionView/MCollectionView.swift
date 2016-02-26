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
  func collectionView(collectionView:MCollectionView, identifierForIndex:Int) -> String?

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

  var visibleCells:[String:UIView] = [:]
  var visibleIdentifiers:Set<String> = []

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

  func identifiersForFrameIntersectFrame(frame:CGRect) -> Set<String>{
    var intersect:Set<String> = []
    for (i, f) in frames.enumerate(){
      if CGRectIntersectsRect(f, frame){
        intersect.insert(identifiers[i])
      }
    }
    return intersect
  }

  var reusableViews:[String:[UIView]] = [:]
  func dequeueReusableViewWithIdentifier(identifier:String) -> UIView?{
    return reusableViews[identifier]?.popLast()
  }

  private func removeCellFromScreen(identifier:String){
    let cell = visibleCells[identifier]!
//    print("remove \(identifier) \(identifiersMap[identifier]!)")
    dataSource?.collectionView(self, cellView: cell, willDisappearForIndex: identifiersMap[identifier]!)
    cell.stopAllAnimation()
    cell.removeFromSuperview()
    if let reusable = cell as? MCollectionReuseable, identifier = reusable.reuseIdentifier{
      if reusableViews[identifier] != nil && !reusableViews[identifier]!.contains(cell){
        reusableViews[identifier]?.append(cell)
      } else {
        reusableViews[identifier] = [cell]
      }
    }
    visibleCells.removeValueForKey(identifier)
  }
  private func insertCellToScreen(identifier:String){
    if let cell = dataSource?.collectionView(self, viewForIndex: identifiersMap[identifier]!){
//      print("insert \(identifier) \(identifiersMap[identifier]!)")
      visibleCells[identifier] = cell
      contentView.addSubview(cell)
      dataSource?.collectionView(self, cellView: cell, didAppearForIndex: identifiersMap[identifier]!)
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
    let indexes = identifiersForFrameIntersectFrame(activeFrame)
    let deletedIndexes = visibleIdentifiers.subtract(indexes)
    let newIndexes = indexes.subtract(visibleIdentifiers)
    for i in deletedIndexes{
      removeCellFromScreen(i)
    }
    for i in newIndexes{
      insertCellToScreen(i)
    }
    visibleIdentifiers = indexes
    layoutCellsIfNecessary()
    for (index, cell) in visibleCells{
      dataSource?.collectionView(self, cellView:cell, didUpdateScreenPositionForIndex:identifiersMap[index]!, screenPosition:cell.center - contentOffset)
    }
  }

  var identifiers:[String] = []
  var identifiersMap:[String:Int] = [:]

  // reload number of cells and all their frames
  // similar to [UICollectionView invalidateLayout]
  func reloadData(){
    frames = []
    identifiers = []
    identifiersMap = [:]
    if let count = dataSource?.numberOfItemsInCollectionView(self){
      frames.reserveCapacity(count)
      identifiers.reserveCapacity(count)
      var unionFrame = CGRectZero
      for i in 0..<count{
        let frame = dataSource!.collectionView(self, frameForIndex: i)
        let identifier = dataSource!.collectionView(self, identifierForIndex: i) ?? NSUUID().UUIDString
        identifiersMap[identifier] = i
        identifiers.append(identifier)
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
        cell.bounds = frames[identifiersMap[index]!].bounds
        cell.center = frames[identifiersMap[index]!].center
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
