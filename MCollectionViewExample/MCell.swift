//
//  MCell.swift
//  MCollectionViewExample
//
//  Created by YiLun Zhao on 2016-02-21.
//  Copyright © 2016 lkzhao. All rights reserved.
//

import UIKit

protocol ReuseableView{
  var identifier:String?{get}
  func didUpdateOnScreenPosition(center: CGPoint, inContainer:UIView)
}
class MCell: UIView, ReuseableView {
  var identifier:String? = nil
  func didUpdateOnScreenPosition(center: CGPoint, inContainer:UIView){
    
  }
}
