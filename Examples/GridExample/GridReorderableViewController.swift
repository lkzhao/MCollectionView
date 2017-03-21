//
//  GridReorderableViewController.swift
//  MCollectionViewExample
//
//  Created by Luke on 3/17/17.
//  Copyright © 2017 lkzhao. All rights reserved.
//

import UIKit
import MCollectionView

class GridReorderableViewController: GridViewController {
  func collectionView(_ collectionView: MCollectionView, willDrag cell: UIView, at indexPath: IndexPath) -> Bool {
    return true
  }

  func collectionView(_ collectionView: MCollectionView, moveItemAt indexPath: IndexPath, to: IndexPath) -> Bool {
    items.insert(items.remove(at: indexPath.item), at: to.item)
    return true
  }
}
