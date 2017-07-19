//
//  HorizontalGalleryViewController.swift
//  MCollectionViewExample
//
//  Created by Luke Zhao on 2016-06-14.
//  Copyright © 2016 lkzhao. All rights reserved.
//

import UIKit
import MCollectionView


struct ArrayDataProvider<Data>: CollectionDataProvider {
  let data: [Data]
  let identifierMapper: (Int, Data) -> String = { "\($0)" }

  var numberOfItems: Int {
    return data.count
  }
  func identifier(at: Int) -> String {
    return identifierMapper(at, data[at])
  }
  func data(at: Int) -> Data {
    return data[at]
  }
}

struct ClosureViewProvider<Data, View>: CollectionViewProvider where View: UIView {
  let viewUpdater: (View, Data, Int) -> Void
  func view(at: Int) -> View {
    return ReuseManager.shared.dequeue(View.self) ?? View()
  }
  func update(view: View, with data: Data, at: Int) {
    viewUpdater(view, data, at)
  }
}


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

  var collectionView: MCollectionView!
  override func viewDidLoad() {
    super.viewDidLoad()
    collectionView = MCollectionView()
    let provider1 = CustomProvider(
      dataProvider: ArrayDataProvider(data: images),
      viewProvider: ClosureViewProvider(viewUpdater: { (view: ImageCell, data: UIImage, at: Int) in
        view.image = data
        view.yaal.rotation.setTo(CGFloat.random(-0.035, max: 0.035))
      }),
      layoutProvider: HorizontalLayout(sizeProvider: { _, data, maxSize in
        return sizeForImage(data.size, maxSize: maxSize)
      }),
      eventResponder: NoEventResponder<UIImage>()
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
      eventResponder: NoEventResponder<UIImage>(),
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
      eventResponder: NoEventResponder<UIImage>(),
      animator: ZoomAnimator()
    )
    collectionView.provider = SectionComposer([provider1, provider2, provider3], layoutProvider: HorizontalLayout())
    view.addSubview(collectionView)
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    collectionView.frame = view.bounds
    collectionView.contentInset = UIEdgeInsetsMake(topLayoutGuide.length + 10, 10, 10, 10)
  }
}
