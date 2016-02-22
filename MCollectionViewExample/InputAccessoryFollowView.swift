//
//  InputAccessoryFollowView.swift
//  InstantChat
//
//  Created by Luke Zhao on 2015-05-19.
//  Copyright (c) 2015 SoySauce. All rights reserved.
//

import UIKit
@objc protocol InputAccessoryFollowViewDelegate{
  func inputAccessoryViewDidUpdateFrame(frame:CGRect)
}
class InputAccessoryFollowView: UIView {
  weak var delegate:InputAccessoryFollowViewDelegate?

  override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = .clearColor()
    userInteractionEnabled = false
  }

  required init(coder aDecoder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
  }
  
  var observedSuperview:UIView?
  override func willMoveToSuperview(newSuperview: UIView?) {
    removeSuperviewObserver()
    if let s = newSuperview{
      addSuperviewObserver(s)
    }
    super.willMoveToSuperview(newSuperview)
  }
  func addSuperviewObserver(superview:UIView){
    superview.addObserver(self, forKeyPath: "center", options: NSKeyValueObservingOptions(), context: nil)
    observedSuperview = superview
  }
  func removeSuperviewObserver(){
    if let os = observedSuperview{
      os.removeObserver(self, forKeyPath: "center")
      observedSuperview = nil
    }
  }
  deinit{
    removeSuperviewObserver()
  }

  override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
    delegate?.inputAccessoryViewDidUpdateFrame(superview!.frame)
  }

}
