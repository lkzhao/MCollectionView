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
    return View()
  }
  func update(view: View, with data: Data, at: Int) {
    viewUpdater(view, data, at)
  }
}

class HorizontalLayout: CollectionLayoutProvider {
  var numRows = 3
  var rowWidth: [CGFloat] = [0, 0]
  var size = CGSize.zero

  var insets: UIEdgeInsets = .zero
  func prepare(size: CGSize) {
    self.size = size
    numRows = max(2, Int(size.height) / 180)
    rowWidth = Array<CGFloat>(repeating: 0, count: numRows)
  }

  func frame(with data: UIImage, at: Int) -> CGRect {
    func getMinRow() -> (Int, CGFloat) {
      var minWidth: (Int, CGFloat) = (0, rowWidth[0])
      for (index, width) in rowWidth.enumerated() {
        if width < minWidth.1 {
          minWidth = (index, width)
        }
      }
      return minWidth
    }

    let avaliableHeight = (size.height - CGFloat(rowWidth.count - 1) * 10) / CGFloat(rowWidth.count)
    var imgSize = sizeForImage(data.size, maxSize: CGSize(width: .infinity, height: avaliableHeight))
    imgSize.height = avaliableHeight
    let (rowIndex, offsetX) = getMinRow()
    rowWidth[rowIndex] += imgSize.width + 10
    return CGRect(origin: CGPoint(x: offsetX, y: CGFloat(rowIndex) * (avaliableHeight + 10)), size: imgSize)
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
    collectionView.provider = CustomProvider(
      dataProvider: ArrayDataProvider(data: images),
      viewProvider: ClosureViewProvider(viewUpdater: { (view: ImageCell, data: UIImage, at: Int) in
        view.image = data
        view.yaal.rotation.setTo(CGFloat.random(-0.035, max: 0.035))
      }),
      layoutProvider: HorizontalLayout(),
      eventResponder: NoEventResponder<UIImage>()
    )
    view.addSubview(collectionView)
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    collectionView.frame = view.bounds
    collectionView.contentInset = UIEdgeInsetsMake(topLayoutGuide.length + 10, 10, 10, 10)
  }
}
