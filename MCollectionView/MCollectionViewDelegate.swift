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
  @objc optional func numberOfSectionsInCollectionView(_ collectionView:MCollectionView) -> Int
  func collectionView(_ collectionView:MCollectionView, numberOfItemsInSection section:Int) -> Int
  func collectionView(_ collectionView:MCollectionView, viewForIndexPath indexPath:IndexPath, initialFrame:CGRect) -> UIView
  func collectionView(_ collectionView:MCollectionView, frameForIndexPath indexPath:IndexPath) -> CGRect
  func collectionView(_ collectionView:MCollectionView, identifierForIndexPath indexPath:IndexPath) -> String

  /// Reload
  @objc optional func collectionViewWillReload(_ collectionView:MCollectionView)
  @objc optional func collectionViewDidReload(_ collectionView:MCollectionView)

  /// Move
  @objc optional func collectionView(_ collectionView:MCollectionView, canMoveItemAt indexPath: IndexPath) -> Bool
  @objc optional func collectionView(_ collectionView:MCollectionView, moveItemAt indexPath: IndexPath, to:IndexPath)


  /// Event
  @objc optional func collectionView(_ collectionView:MCollectionView, didInsertCellView cellView: UIView, atIndexPath indexPath: IndexPath)
  @objc optional func collectionView(_ collectionView:MCollectionView, didDeleteCellView cellView: UIView, atIndexPath indexPath: IndexPath)
  @objc optional func collectionView(_ collectionView:MCollectionView, didReloadCellView cellView: UIView, atIndexPath indexPath: IndexPath)
  @objc optional func collectionView(_ collectionView:MCollectionView, didMoveCellView cellView: UIView, fromIndexPath: IndexPath, toIndexPath:IndexPath)


  ///
  @objc optional func collectionView(_ collectionView:MCollectionView, cellView:UIView, didAppearForIndexPath indexPath:IndexPath)
  @objc optional func collectionView(_ collectionView:MCollectionView, cellView:UIView, willDisappearForIndexPath indexPath:IndexPath)
  @objc optional func collectionView(_ collectionView:MCollectionView, cellView:UIView, didUpdateScreenPositionForIndexPath indexPath:IndexPath, screenPosition:CGPoint)
}
