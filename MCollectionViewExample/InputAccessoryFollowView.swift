//
//  InputAccessoryFollowView.swift
//  InstantChat
//
//  Created by Luke Zhao on 2015-05-19.
//  Copyright (c) 2015 SoySauce. All rights reserved.
//

import UIKit
@objc protocol InputAccessoryFollowViewDelegate{
  func inputAccessoryViewDidUpdateFrame(_ frame:CGRect)
}
class InputAccessoryFollowView: UIView {
  weak var delegate:InputAccessoryFollowViewDelegate?
  
  var keyboardFrame:CGRect?
  
  init() {
    super.init(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
    backgroundColor = .clear
    isUserInteractionEnabled = false
  }

  required init(coder aDecoder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
  }
  
  var observedSuperview:UIView?
  override func willMove(toSuperview newSuperview: UIView?) {
    removeSuperviewObserver()
    if let s = newSuperview{
      addSuperviewObserver(s)
    }
    super.willMove(toSuperview: newSuperview)
  }
  func addSuperviewObserver(_ superview:UIView){
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

  override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
    let superFrame = superview!.frame

    // this `observeValueForKeyPath` is wrapped inside a UIView animation some how. 
    // we want to notify our delegate outside the animation so that we dont get 
    // unwanted animation behavior
    DispatchQueue.main.async { () -> Void in
        self.keyboardFrame = CGRect(x: superFrame.origin.x, y: superFrame.origin.y+1, width: superFrame.width, height: superFrame.height-1)
        self.delegate?.inputAccessoryViewDidUpdateFrame(self.keyboardFrame!)
    }
  }

}
