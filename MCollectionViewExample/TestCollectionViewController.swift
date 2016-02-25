//
//  TestCollectionViewController.swift
//  MCollectionViewExample
//
//  Created by YiLun Zhao on 2016-02-23.
//  Copyright © 2016 lkzhao. All rights reserved.
//

import UIKit


//class TestCollectionVC: UIViewController, MCollectionViewDataSource {
//  var collectionView:MCollectionView!
//  override func viewDidLoad() {
//    super.viewDidLoad()
//    collectionView = MCollectionView(frame:view.frame)
//    collectionView.dataSource = self;
//    view.addSubview(collectionView)
//    collectionView.reloadData()
//  }
//  func numberOfItemsInCollectionView(collectionView:MCollectionView) -> Int{
//    return 200
//  }
//  func collectionView(collectionView:MCollectionView, viewForIndex index:Int) -> UIView{
//    let v = UIView(frame: self.collectionView(collectionView, frameForIndex: index))
//    v.backgroundColor = UIColor.lightGrayColor()
//    //    v.alpha = 0
//    //    v.m_animate("alpha", to: 1)
//    return v
//  }
//  func collectionView(collectionView:MCollectionView, frameForIndex index:Int) -> CGRect{
//    let columns = 15
//    let cellSize = CGSizeMake(100, 100)
//    let x = CGFloat(20 + CGFloat(index % columns) * CGFloat(cellSize.width + 20))
//    let y = CGFloat(30 + CGFloat(index / columns) * CGFloat(cellSize.height + 20))
//    return CGRectMake(x, y, cellSize.width, cellSize.height)
//  }
//}
