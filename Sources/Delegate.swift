//
//  MCollectionViewDelegate.swift
//  MCollectionViewExample
//
//  Created by Luke on 3/17/17.
//  Copyright © 2017 lkzhao. All rights reserved.
//

import UIKit

@objc public protocol MCollectionViewDelegate {

  /// Data source
  func numberOfItemsInCollectionView(_ collectionView: MCollectionView) -> Int
  func collectionView(_ collectionView: MCollectionView, viewForIndex index: Int, initialFrame: CGRect) -> UIView
  func collectionView(_ collectionView: MCollectionView, frameForIndex index: Int) -> CGRect
  func collectionView(_ collectionView: MCollectionView, identifierForIndex index: Int) -> String

  /// Move
  @objc optional func collectionView(_ collectionView: MCollectionView, moveItemAt index: Int, to: Int) -> Bool
  @objc optional func collectionView(_ collectionView: MCollectionView, willDrag cell: UIView, at index: Int) -> Bool
  @objc optional func collectionView(_ collectionView: MCollectionView, didDrag cell: UIView, at index: Int)

  /// Reload
  @objc optional func collectionViewWillReload(_ collectionView: MCollectionView)
  @objc optional func collectionViewDidReload(_ collectionView: MCollectionView)

  /// Callback during reloadData
  @objc optional func collectionView(_ collectionView: MCollectionView, didInsertCellView cellView: UIView, atIndex index: Int)
  @objc optional func collectionView(_ collectionView: MCollectionView, didDeleteCellView cellView: UIView, atIndex index: Int)
  @objc optional func collectionView(_ collectionView: MCollectionView, didReloadCellView cellView: UIView, atIndex index: Int)
  @objc optional func collectionView(_ collectionView: MCollectionView, didMoveCellView cellView: UIView, fromIndex: Int, toIndex: Int)

  ///
  @objc optional func collectionView(_ collectionView: MCollectionView, cellView: UIView, didAppearForIndex index: Int)
  @objc optional func collectionView(_ collectionView: MCollectionView, cellView: UIView, willDisappearForIndex index: Int)
  @objc optional func collectionView(_ collectionView: MCollectionView, cellView: UIView, didUpdateScreenPositionForIndex index: Int, screenPosition: CGPoint)
}
