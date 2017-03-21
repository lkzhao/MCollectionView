//
//  GridViewController.swift
//  MCollectionViewExample
//
//  Created by Luke Zhao on 2016-06-05.
//  Copyright © 2016 lkzhao. All rights reserved.
//

import UIKit
import MCollectionView

class GridViewController: UIViewController {

  var collectionView: MCollectionView!
  var items:[Int] = []
  override func viewDidLoad() {
    super.viewDidLoad()
    for i in 1...400 {
      items.append(i)
    }
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
extension GridViewController: MCollectionViewDelegate {
  func numberOfSectionsInCollectionView(_ collectionView: MCollectionView) -> Int {
    return 1
  }

  func collectionView(_ collectionView: MCollectionView, numberOfItemsInSection section: Int) -> Int {
    return items.count
  }

  func collectionView(_ collectionView: MCollectionView, viewForIndexPath indexPath: IndexPath, initialFrame: CGRect) -> UIView {
    let v = collectionView.dequeueReusableView(UILabel.self) ?? UILabel()
    v.backgroundColor = UIColor.lightGray
    v.text = "\(items[indexPath.item])"
    v.frame = initialFrame
    return v
  }

  func collectionView(_ collectionView: MCollectionView, identifierForIndexPath indexPath: IndexPath) -> String {
    return "\(items[indexPath.item])"
  }

  func collectionView(_ collectionView: MCollectionView, frameForIndexPath indexPath: IndexPath) -> CGRect {
    let i = indexPath.item
    return CGRect(x: CGFloat(i % 20) * 60, y: CGFloat(i / 20) * 60, width: 50, height: 50)
  }

  func collectionView(_ collectionView: MCollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
    return true
  }

  func collectionView(_ collectionView: MCollectionView, moveItemAt indexPath: IndexPath, to: IndexPath) -> Bool {
    items.insert(items.remove(at: indexPath.item), at: to.item)
    return true
  }

}
