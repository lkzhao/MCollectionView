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
  
  var keyboardFrame:CGRect?
  
  init() {
    super.init(frame: CGRectMake(0, 0, 1, 1))
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
    let superFrame = superview!.frame

    // this `observeValueForKeyPath` is wrapped inside a UIView animation some how. 
    // we want to notify our delegate outside the animation so that we dont get 
    // unwanted animation behavior
    dispatch_async(dispatch_get_main_queue()) { () -> Void in
        self.keyboardFrame = CGRectMake(superFrame.origin.x, superFrame.origin.y+1, superFrame.width, superFrame.height-1)
        self.delegate?.inputAccessoryViewDidUpdateFrame(self.keyboardFrame!)
    }
  }

}
