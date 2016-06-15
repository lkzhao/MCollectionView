//
//  GridViewController.swift
//  MCollectionViewExample
//
//  Created by Luke Zhao on 2016-06-05.
//  Copyright © 2016 lkzhao. All rights reserved.
//

import UIKit

class GridViewController: UIViewController {
  
  var collectionView:MCollectionView!
  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = UIColor(white: 0.97, alpha: 1.0)
    view.clipsToBounds = true
    collectionView = MCollectionView(frame:view.bounds)
    collectionView.collectionDelegate = self
    collectionView.wabble = true
    collectionView.horizontalScroll = true
    view.addSubview(collectionView)
  }
  
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    collectionView.frame = view.bounds
    collectionView.contentInset = UIEdgeInsetsMake(topLayoutGuide.length, 0, 0, 0)
  }
}



// collectionview datasource and layout
extension GridViewController: MCollectionViewDelegate{
  func numberOfSectionsInCollectionView(collectionView: MCollectionView) -> Int {
    return 1
  }
  
  func collectionView(collectionView: MCollectionView, numberOfItemsInSection section: Int) -> Int {
    return 400
  }
  
  func collectionView(collectionView: MCollectionView, viewForIndexPath indexPath: NSIndexPath, initialFrame: CGRect) -> UIView {
    let v = collectionView.dequeueReusableView(UILabel) ?? UILabel()
    v.backgroundColor = UIColor.lightGrayColor()
    v.text = "\(indexPath.item)"
    v.frame = initialFrame
    return v
  }
  
  func collectionView(collectionView: MCollectionView, identifierForIndexPath indexPath: NSIndexPath) -> String {
    return "\(indexPath.item)"
  }
  
  func collectionView(collectionView: MCollectionView, frameForIndexPath indexPath: NSIndexPath) -> CGRect {
    let i = indexPath.item
    return CGRectMake(CGFloat(i % 20) * 60, CGFloat(i / 20) * 60, 50, 50)
  }
}
