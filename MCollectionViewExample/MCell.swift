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
}

class MCell: UIView, ReuseableView {
  var identifier:String? = nil
  
  var pressGR:UILongPressGestureRecognizer!
  override init(frame: CGRect) {
    super.init(frame: frame)
    pressGR = UILongPressGestureRecognizer(target: self, action: "press")
    pressGR.delegate = self
    pressGR.minimumPressDuration = 0
    addGestureRecognizer(pressGR)
    self.m_defineCustomProperty("scale", initialValues: [1]) { (values) -> Void in
      self.transform = CGAffineTransformMakeScale(values[0], values[0])
    }
  }

  required init?(coder aDecoder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
  }
  
  func press(){
    switch pressGR.state{
    case .Began:
      self.m_animate("scale", to: 0.9, damping: 10)
    case .Changed:
      break
    default:
      self.m_animate("scale", to: 1.0, damping: 10)
    }
  }
}

extension MCell:UIGestureRecognizerDelegate{
  func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
    return true
  }
}
