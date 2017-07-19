//
//  MCollectionViewDelegate.swift
//  MCollectionViewExample
//
//  Created by Luke on 3/17/17.
//  Copyright © 2017 lkzhao. All rights reserved.
//

import UIKit

public protocol MCollectionViewReusableView: class {
  func prepareForReuse()
}

@objc public protocol MCollectionViewDelegate {

  /// Data source
  func numberOfItemsInCollectionView(_ collectionView: CollectionView) -> Int
  func collectionView(_ collectionView: CollectionView, viewForIndex index: Int) -> UIView
  func collectionView(_ collectionView: CollectionView, frameForIndex index: Int) -> CGRect
  func collectionView(_ collectionView: CollectionView, identifierForIndex index: Int) -> String

  /// content padding from delegate. will grow contentSize
  @objc optional func collectionViewContentPadding(_ collectionView: CollectionView) -> UIEdgeInsets

  /// Tap
  @objc optional func collectionView(_ collectionView: CollectionView, didTap cell: UIView, at index: Int)

  /// Move
  @objc optional func collectionView(_ collectionView: CollectionView, moveItemAt index: Int, to: Int) -> Bool
  @objc optional func collectionView(_ collectionView: CollectionView, willDrag cell: UIView, at index: Int) -> Bool
  @objc optional func collectionView(_ collectionView: CollectionView, didDrag cell: UIView, at index: Int)

  /// Reload
  @objc optional func collectionViewWillReload(_ collectionView: CollectionView)
  @objc optional func collectionViewDidReload(_ collectionView: CollectionView)

  /// Callback during reloadData
  @objc optional func collectionView(_ collectionView: CollectionView, didInsertCellView cellView: UIView, atIndex index: Int)
  @objc optional func collectionView(_ collectionView: CollectionView, didDeleteCellView cellView: UIView, atIndex index: Int)
  @objc optional func collectionView(_ collectionView: CollectionView, didReloadCellView cellView: UIView, atIndex index: Int)
  @objc optional func collectionView(_ collectionView: CollectionView, didMoveCellView cellView: UIView, fromIndex: Int, toIndex: Int)

  ///
  @objc optional func collectionView(_ collectionView: CollectionView, cellView: UIView, didAppearForIndex index: Int)
  @objc optional func collectionView(_ collectionView: CollectionView, cellView: UIView, willDisappearForIndex index: Int)
  @objc optional func collectionView(_ collectionView: CollectionView, cellView: UIView, didUpdateabsolutePositionForIndex index: Int, absolutePosition: CGPoint)
}
