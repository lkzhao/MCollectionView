//
//  HorizontalGalleryViewController.swift
//  MCollectionViewExample
//
//  Created by Luke Zhao on 2016-06-14.
//  Copyright © 2016 lkzhao. All rights reserved.
//

import UIKit
import MCollectionView

class HorizontalGalleryViewController: UIViewController {
  var images: [UIImage] = [
    UIImage(named: "l1")!,
    UIImage(named: "l2")!,
    UIImage(named: "l3")!,
    UIImage(named: "1")!,
    UIImage(named: "2")!,
    UIImage(named: "3")!,
    UIImage(named: "4")!,
    UIImage(named: "5")!,
    UIImage(named: "6")!,
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

  var collectionView: CollectionView!
  override func viewDidLoad() {
    super.viewDidLoad()
    collectionView = CollectionView()
    let provider1 = CustomProvider(
      dataProvider: ArrayDataProvider(data: images),
      viewProvider: ClosureViewProvider(viewUpdater: { (view: ImageCell, data: UIImage, at: Int) in
        view.image = data
        view.yaal.rotation.setTo(CGFloat.random(-0.035, max: 0.035))
      }),
      layoutProvider: HorizontalLayout(sizeProvider: { _, data, maxSize in
        return sizeForImage(data.size, maxSize: maxSize)
      })
    )
    let provider2 = CustomProvider(
      dataProvider: ArrayDataProvider(data: images),
      viewProvider: ClosureViewProvider(viewUpdater: { (view: ImageCell, data: UIImage, at: Int) in
        view.image = data
        view.yaal.rotation.setTo(CGFloat.random(-0.035, max: 0.035))
      }),
      layoutProvider: HorizontalLayout(sizeProvider: { _, data, maxSize in
        return sizeForImage(data.size, maxSize: maxSize)
      }),
      animator: WobbleAnimator()
    )
    let provider3 = CustomProvider(
      dataProvider: ArrayDataProvider(data: images),
      viewProvider: ClosureViewProvider(viewUpdater: { (view: ImageCell, data: UIImage, at: Int) in
        view.image = data
        view.yaal.rotation.setTo(CGFloat.random(-0.035, max: 0.035))
      }),
      layoutProvider: HorizontalLayout(sizeProvider: { _, data, maxSize in
        return sizeForImage(data.size, maxSize: maxSize)
      }),
      animator: ZoomAnimator()
    )
    collectionView.provider = SectionComposer([provider1, provider2, provider3], layoutProvider: HorizontalLayout(prefferedRowHeight: 230))
    view.addSubview(collectionView)
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    collectionView.frame = view.bounds
    collectionView.contentInset = UIEdgeInsetsMake(topLayoutGuide.length + 10, 10, 10, 10)
  }
}
