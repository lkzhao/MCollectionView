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
  var collectionView: CollectionView!
  var items:[Int] = []
  override func viewDidLoad() {
    super.viewDidLoad()
    for i in 1...kGridSize.width * kGridSize.height {
      items.append(i)
    }
    view.backgroundColor = UIColor(white: 0.97, alpha: 1.0)
    view.clipsToBounds = true
    collectionView = CollectionView(frame:view.bounds)
    let dataProvider = ArrayDataProvider(data: items, identifierMapper: { (_, data) in
      return "\(data)"
    })
    collectionView.provider = CustomProvider(
      dataProvider: dataProvider,
      viewProvider: ClosureViewProvider(viewUpdater: { (view: UILabel, data: Int, at: Int) in
        view.backgroundColor = UIColor.lightGray
        view.text = "\(data)"
      }),
      layoutProvider: ClosureLayoutProvider(frameProvider: { (_, i: Int) in
        CGRect(x: CGFloat(i % kGridSize.width) * (kGridCellSize.width + kGridCellPadding),
               y: CGFloat(i / kGridSize.width) * (kGridCellSize.height + kGridCellPadding),
               width: kGridCellSize.width,
               height: kGridCellSize.height)
      }),
      eventResponder: ClosureEventResponder(canDrag: { _, _ in return true }, onMove: { [weak self] from, to in
        guard let this = self else { return false }
        print(from, to)
        this.items.insert(this.items.remove(at: from), at: to)
        dataProvider.data = this.items
        return true
      }),
      animator: WobbleAnimator()
    )
    view.addSubview(collectionView)
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    collectionView.frame = view.bounds
    collectionView.contentInset = UIEdgeInsetsMake(topLayoutGuide.length, 0, 0, 0)
  }
}

