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

  override func viewDidLoad() {
    super.viewDidLoad()
  }

  func collectionView(_ collectionView: MCollectionView, willDrag cell: UIView, at index: Int) -> Bool {
    return true
  }

  func collectionView(_ collectionView: MCollectionView, moveItemAt index: Int, to: Int) -> Bool {
    items.insert(items.remove(at: index), at: to)
    return true
  }
}
