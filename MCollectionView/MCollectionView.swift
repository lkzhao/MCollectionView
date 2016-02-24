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
}

class MCollectionView: MScrollView {
  var dataSource:MCollectionViewDataSource?

  var frames:[CGRect] = []

  var visibleCells:[Int:UIView] = [:]
  var visibleIndexes:Set<Int> = []
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    self.clipsToBounds = true
  }

  required init?(coder aDecoder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
  }
  
  override func layoutSubviews() {
    reloadData() // ask the dataSource for new cell frames
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

  private func loadCells(){
    guard let dataSource = dataSource else { return }
    let maxDiff = max(bounds.width,bounds.height) - min(bounds.width, bounds.height)
    let indexes = indexesForFrameIntersectFrame(CGRectInset(visibleFrame, -maxDiff, -300))
    let deletedIndexes = visibleIndexes.subtract(indexes)
    let newIndexes = indexes.subtract(visibleIndexes)
    for i in deletedIndexes{
      let cell = visibleCells[i]!
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
    for i in newIndexes{
      let cell = dataSource.collectionView(self, viewForIndex: i)
      visibleCells[i] = cell
      contentView.addSubview(cell)
    }
    visibleIndexes = indexes
    layoutCells()
    for (_, cell) in visibleCells{
      if let reusable = cell as? ReuseableView{
        reusable.didUpdateOnScreenPosition(cell.center - contentOffset, inContainer: self)
      }
    }
  }
  
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

  func layoutCells(){
    for (index, cell) in visibleCells{
      cell.bounds = frames[index].bounds
      cell.center = frames[index].center
    }
  }

  override func didScroll() {
    timer?.invalidate()
    loadCells()
    super.didScroll()
  }
  
  var timer:NSTimer?
  override func didEndScroll() {
    super.didEndScroll()
    timer = NSTimer.schedule(delay: 0.1) { (timer) -> Void in
      self.reusableViews.removeAll()
    }
  }
}
