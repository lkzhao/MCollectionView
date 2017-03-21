//
//  GridViewController.swift
//  MCollectionViewExample
//
//  Created by Luke Zhao on 2016-06-05.
//  Copyright © 2016 lkzhao. All rights reserved.
//

import UIKit
import MCollectionView

let kGridCellSize = CGSize(width: 100, height: 100)
let kGridSize = (width: 20, height: 20)
let kGridCellPadding:CGFloat = 10
class GridViewController: UIViewController {

  var collectionView: MCollectionView!
  var items:[Int] = []
  override func viewDidLoad() {
    super.viewDidLoad()
    for i in 1...kGridSize.width * kGridSize.height {
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
    return CGRect(x: CGFloat(i % kGridSize.width) * (kGridCellSize.width + kGridCellPadding),
                  y: CGFloat(i / kGridSize.width) * (kGridCellSize.height + kGridCellPadding),
                  width: kGridCellSize.width,
                  height: kGridCellSize.height)
  }

}
