//
//  InputToolbarView.swift
//  InstantChat
//
//  Created by Luke Zhao on 2015-05-18.
//  Copyright (c) 2015 SoySauce. All rights reserved.
//

import UIKit
import AVFoundation

@objc protocol InputToolbarViewDelegate:InputAccessoryFollowViewDelegate{
  func send(text:String)
  func inputToolbarViewNeedFrameUpdate()
}

class InputToolbarView: MCell {
  var textView:UITextView!
  var sendButton:UIImageView!
  var showingPlaceholder = true
  var keyboardFrame:CGRect?{
    return accessoryView.keyboardFrame
  }
  var accessoryView:InputAccessoryFollowView!
  weak var delegate:InputToolbarViewDelegate?{
    didSet{
      accessoryView.delegate = delegate
    }
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    sendButton = UIImageView(image: UIImage(named: "ic_send"))
    sendButton.tintColor = UIColor(white: 0.6, alpha: 1.0)
    sendButton.contentMode = .Center
    addSubview(sendButton)
    
    textView = UITextView(frame: CGRectZero)
    addSubview(textView)
    
    layer.shadowOffset = CGSizeZero
    layer.shadowRadius = 30
    layer.shadowColor = UIColor(white: 0.3, alpha: 1.0).CGColor
    layer.cornerRadius = 10
    self.m_defineCustomProperty("shadowOpacity", initialValues: 0) { (v:CGFloat) -> Void in
      self.layer.shadowOpacity = Float(v)
    }
    backgroundColor = UIColor(white: 0.97, alpha: 0.97)
    
    textView.delegate = self
    textView.backgroundColor = .clearColor()
    textView.font = UIFont.systemFontOfSize(17)
    textViewDidEndEditing(textView)
    accessoryView = InputAccessoryFollowView()
    accessoryView.autoresizingMask = .FlexibleHeight
    textView.inputAccessoryView = accessoryView
    
    
    tapGR = UITapGestureRecognizer(target: self, action: #selector(tap))
    addGestureRecognizer(tapGR)
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    sendButton.bounds.size = CGSizeMake(44, 44)
    sendButton.frame.origin = CGPointMake(bounds.width - sendButton.frame.width, (bounds.height - sendButton.frame.height)/2)
    textView.frame = CGRectMake(8, 8, bounds.width - sendButton.frame.width, bounds.height - 16)
  }
  
  var recorder:AVAudioRecorder!
  var recordFileURL:NSURL!
  var meterTimer:NSTimer!
  
  override func tap() {
    if CGRectContainsPoint(sendButton.frame, tapGR.locationInView(self)){
      sendButtonTapped()
    } else if CGRectContainsPoint(self.bounds, tapGR.locationInView(self)) && !textView.isFirstResponder() {
      textView.becomeFirstResponder()
    }
  }
  
  var shaking = false
  func sendButtonTapped(){
    if !showingPlaceholder && textView.text != ""{
      delegate?.send(textView.text)
      setText("")
    } else {
      if !shaking{
        shaking = true
//        let originalCenter = center
        //        self.animateCenterTo(CGPointMake(originalCenter.x + 10, originalCenter.y), stiffness: 2500, threshold:150) {
        //          self.animateCenterTo(CGPointMake(originalCenter.x - 10, originalCenter.y), stiffness: 2500, threshold:150) {
        //            self.animateCenterTo(CGPointMake(originalCenter.x + 10, originalCenter.y), stiffness: 2500, threshold:150) {
        //              self.animateCenterTo(originalCenter, threshold:1) {
        //                self.shaking = false
        //              }
        //            }
        //          }
        //        }
      }
    }
  }
  
  func setText(text:String){
    if text == "" && !textView.isFirstResponder(){
      showPlaceHolder()
    } else {
      textView.text = text
      textViewDidChange(textView)
    }
  }
  
  override func sizeThatFits(size: CGSize) -> CGSize {
    let textSize = textView.sizeThatFits(CGSizeMake(size.width - 16, size.height - 16))
    let newHeight = min(textSize.height + 16, 100)
    return CGSizeMake(textSize.width + 16, newHeight)
  }
}

extension InputToolbarView: UITextViewDelegate{
  func textViewDidChange(textView: UITextView) {
    let size = self.sizeThatFits(CGSizeMake(frame.width, CGFloat.max))
    if size.height != frame.height{
      self.delegate?.inputToolbarViewNeedFrameUpdate()
      self.layoutIfNeeded()
    }
  }
  func textViewDidBeginEditing(textView: UITextView) {
    if showingPlaceholder {
      showingPlaceholder = false
      textView.text = nil
      textView.textColor = UIColor(red: 131/255, green: 138/255, blue: 147/255, alpha: 1.0)
    }
  }
  func textViewDidEndEditing(textView: UITextView) {
    if textView.text.isEmpty {
      showPlaceHolder()
    }
  }
  func showPlaceHolder(){
    showingPlaceholder = true
    textView.text = "Send message..."
    textView.textColor = UIColor(red: 131/255, green: 138/255, blue: 147/255, alpha: 0.7)
  }
}