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
    UIImage(named: "6")!
  ]

  var numColumns = 1
  var numRows = 3
  var rowWidth: [CGFloat] = [0, 0]

  var collectionView: MCollectionView!
  override func viewDidLoad() {
    super.viewDidLoad()
    collectionView = MCollectionView()
    collectionView.collectionDelegate = self
    collectionView.wabble = true
    view.addSubview(collectionView)
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    collectionView.frame = view.bounds
    collectionView.contentInset = UIEdgeInsetsMake(topLayoutGuide.length + 10, 10, 10, 10)
  }
}

// mark MCollectionViewDataSource
extension HorizontalGalleryViewController:MCollectionViewDelegate {
  func numberOfItemsInCollectionView(_ collectionView: MCollectionView) -> Int {
    return images.count * 100
  }

  func collectionView(_ collectionView: MCollectionView, viewForIndex index: Int) -> UIView {
    let image = images[index % images.count]
    let cell = collectionView.dequeueReusableView(ImageCell.self) ?? ImageCell()
    cell.image = image
    cell.yaal_rotation.setTo(CGFloat.random(-0.035, max: 0.035))
    return cell
  }

  func collectionViewWillReload(_ collectionView: MCollectionView) {
    numColumns = max(1, Int(collectionView.innerSize.width) / 400)
    numRows = max(2, Int(collectionView.innerSize.height) / 180)

    rowWidth = Array<CGFloat>(repeating: 0, count: numRows)
  }

  func collectionView(_ collectionView: MCollectionView, frameForIndex index: Int) -> CGRect {

    func getMinRow() -> (Int, CGFloat) {
      var minWidth: (Int, CGFloat) = (0, rowWidth[0])
      for (index, width) in rowWidth.enumerated() {
        if width < minWidth.1 {
          minWidth = (index, width)
        }
      }
      return minWidth
    }

    let image = images[index % images.count]
    let avaliableHeight = (collectionView.innerSize.height - CGFloat(rowWidth.count - 1) * 10) / CGFloat(rowWidth.count)
    let width = collectionView.innerSize.width / CGFloat(numColumns)
    var imgSize = sizeForImage(image.size, maxSize: CGSize(width: width, height: avaliableHeight))
    imgSize.height = avaliableHeight
    let (rowIndex, offsetX) = getMinRow()
    rowWidth[rowIndex] += imgSize.width + 10
    return CGRect(origin: CGPoint(x: offsetX, y: CGFloat(rowIndex) * (avaliableHeight + 10)), size: imgSize)
  }

  func collectionView(_ collectionView: MCollectionView, identifierForIndex index: Int) -> String {
    return "\(index)"
  }
}
