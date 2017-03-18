//
//  ImageCell.swift
//  MCollectionViewExample
//
//  Created by Luke Zhao on 2016-06-14.
//  Copyright © 2016 lkzhao. All rights reserved.
//

import UIKit
import MCollectionView

func sizeForImage(_ imageSize: CGSize, maxSize: CGSize) -> CGSize {
  var imageSize = imageSize
  if imageSize.width > maxSize.width {
    imageSize.height /= imageSize.width/maxSize.width
    imageSize.width = maxSize.width
  }
  if imageSize.height > maxSize.height {
    imageSize.width /= imageSize.height/maxSize.height
    imageSize.height = maxSize.height
  }
  return imageSize
}

class ImageCell: MCell {
  var imageView = UIImageView()
  var image: UIImage? {
    didSet {
      imageView.image = image
    }
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    imageView.clipsToBounds = true
    imageView.layer.cornerRadius = 7
    addSubview(imageView)
    showShadow = true
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    imageView.frame = bounds
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
