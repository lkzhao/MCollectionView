//
//  HorizontalRowsViewController.swift
//  MCollectionViewExample
//
//  Created by Luke Zhao on 2016-06-14.
//  Copyright © 2016 lkzhao. All rights reserved.
//

import UIKit

class HorizontalRowsViewController: UIViewController {
  var images:[UIImage] = [
    UIImage(named: "l1")!,
    UIImage(named: "l2")!,
    UIImage(named: "l3")!,
    UIImage(named: "1")!,
    UIImage(named: "2")!,
    UIImage(named: "3")!,
    UIImage(named: "4")!,
    UIImage(named: "5")!,
    UIImage(named: "6")!
  ]
  
  var numColumns = 1
  var numRows = 3
  
  var rowWidth:[CGFloat] = [0,0]
  
  func getMinRow() -> (Int, CGFloat) {
    var minWidth:(Int, CGFloat) = (0,rowWidth[0])
    for (index, width) in rowWidth.enumerate(){
      if width < minWidth.1 {
        minWidth = (index, width)
      }
    }
    return minWidth
  }
}

// mark MCollectionViewDataSource
extension HorizontalRowsViewController:MCollectionViewDelegate{
  func numberOfSectionsInCollectionView(collectionView: MCollectionView) -> Int {
    return 1
  }
  
  func collectionView(collectionView: MCollectionView, numberOfItemsInSection section: Int) -> Int {
    return images.count
  }
  
  func collectionView(collectionView: MCollectionView, viewForIndexPath indexPath: NSIndexPath, initialFrame: CGRect) -> UIView {
    let image = images[indexPath.item]
    let cell = collectionView.dequeueReusableView(ImageCell) ?? ImageCell(frame:initialFrame)
    cell.center = initialFrame.center
    cell.bounds = initialFrame.bounds
    cell.image = image
    cell.rotation = CGFloat.random(-0.035, max: 0.035)
    cell.onTap = {[weak self] cell in
    }
    return cell
  }
  
  func collectionViewWillReload(collectionView: MCollectionView) {
    numColumns = max(1, Int(collectionView.innerSize.width) / 400)
    numRows = max(2, Int(collectionView.innerSize.height) / 180)
    
    rowWidth = Array<CGFloat>(count:numRows, repeatedValue: 0)
  }
  
  func collectionView(collectionView: MCollectionView, frameForIndexPath indexPath: NSIndexPath) -> CGRect {
    let image = images[indexPath.item]
    let avaliableHeight = (collectionView.innerSize.height - CGFloat(rowWidth.count - 1) * 10) / CGFloat(rowWidth.count)
    let width = collectionView.innerSize.width / CGFloat(numColumns)
    var imgSize = sizeForImage(image.size, maxSize: CGSizeMake(width, avaliableHeight))
    //        var imgSize = CGSizeMake(200, 200)
    imgSize.height = avaliableHeight
    let (rowIndex, offsetX) = getMinRow()
    rowWidth[rowIndex] += imgSize.width + 10
    return CGRect(origin: CGPointMake(offsetX, CGFloat(rowIndex) * (avaliableHeight + 10)), size: imgSize)
  }
  
  func collectionView(collectionView: MCollectionView, identifierForIndexPath indexPath: NSIndexPath) -> String {
    return "\(indexPath.item)"
  }
  
  func collectionView(collectionView: MCollectionView, didReloadCellView cellView: UIView, atIndexPath indexPath: NSIndexPath) {
    (cellView as! ImageCell).image = images[indexPath.item]
  }
}
