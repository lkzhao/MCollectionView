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
  func numberOfSectionsInCollectionView(_ collectionView: MCollectionView) -> Int {
    return 1
  }
  
  func collectionView(_ collectionView: MCollectionView, numberOfItemsInSection section: Int) -> Int {
    return 400
  }
  
  func collectionView(_ collectionView: MCollectionView, viewForIndexPath indexPath: IndexPath, initialFrame: CGRect) -> UIView {
    let v = collectionView.dequeueReusableView(UILabel) ?? UILabel()
    v.backgroundColor = UIColor.lightGray
    v.text = "\((indexPath as NSIndexPath).item)"
    v.frame = initialFrame
    return v
  }
  
  func collectionView(_ collectionView: MCollectionView, identifierForIndexPath indexPath: IndexPath) -> String {
    return "\((indexPath as NSIndexPath).item)"
  }
  
  func collectionView(_ collectionView: MCollectionView, frameForIndexPath indexPath: IndexPath) -> CGRect {
    let i = (indexPath as NSIndexPath).item
    return CGRect(x: CGFloat(i % 20) * 60, y: CGFloat(i / 20) * 60, width: 50, height: 50)
  }
}
