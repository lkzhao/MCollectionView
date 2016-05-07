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
  func send(audio:NSURL, length:NSTimeInterval)
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
    self.m_defineCustomProperty("shadowOpacity", initialValues: [0]) { (values) -> Void in
      self.layer.shadowOpacity = Float(values[0])
    }
    backgroundColor = UIColor(white: 0.97, alpha: 0.97)
    
    textView.delegate = self
    textView.backgroundColor = .clearColor()
    textView.font = UIFont.systemFontOfSize(17)
    textViewDidEndEditing(textView)
    accessoryView = InputAccessoryFollowView()
    accessoryView.autoresizingMask = .FlexibleHeight
    textView.inputAccessoryView = accessoryView
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

//  override func press(){
//    switch pressGR.state{
//    case .Began:
//      self.m_animate("scale", to: 0.95, damping: 10)
//    case .Changed:
//      break
//    default:
//      self.m_animate("scale", to: 1.0, damping: 10)
//      if CGRectContainsPoint(sendButton.frame, pressGR.locationInView(self)){
//        sendButtonTapped()
//      } else if CGRectContainsPoint(self.bounds, pressGR.locationInView(self)) && !textView.isFirstResponder() {
//        textView.becomeFirstResponder()
//      }
//    }
//  }

  var shaking = false
  func sendButtonTapped(){
    if !showingPlaceholder && textView.text != ""{
      delegate?.send(textView.text)
      setText("")
    } else {
      if !shaking{
        shaking = true
        let originalCenter = center
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
  @IBAction func cancelRecording(sender: UIButton) {
    self.recorder.stop()
  }
  @IBAction func endRecording(sender: UIButton) {
    let length = self.recorder.currentTime
    self.recorder.stop()
    delegate?.send(recordFileURL, length: length)
  }
  @IBAction func startRecording(sender: AnyObject) {
    AVAudioSession.sharedInstance().requestRecordPermission({(granted: Bool)-> Void in
      if granted {
        self.setupRecorder()
        self.recorder.record()
        print("start recording")
        self.meterTimer = NSTimer.scheduledTimerWithTimeInterval(0.1,
          target:self,
          selector:"updateAudioMeter",
          userInfo:nil,
          repeats:true)
      } else {
        print("Permission to record not granted")
      }
    })
  }
  func updateAudioMeter(){
    
  }
  func setupRecorder(){
//    var tmpDir = "file://\(NSTemporaryDirectory())"
//    let fileName = NSUUID().UUIDString
//    recordFileURL = NSURL(string: tmpDir.stringByAppendingPathComponent(fileName))
//    var recordSettings:[NSObject:AnyObject] = [
//      AVFormatIDKey: kAudioFormatMPEG4AAC,
//      AVEncoderAudioQualityKey : AVAudioQuality.Medium.rawValue,
//      AVEncoderBitRateKey : 64000,
//      AVNumberOfChannelsKey: 2,
//      AVSampleRateKey : 44100.0
//    ]
//    var error: NSError?
//    self.recorder = AVAudioRecorder(URL: recordFileURL, settings: recordSettings, error: &error)
//    if let e = error {
//      println(e.localizedDescription)
//    } else {
//      recorder.delegate = self
//      recorder.meteringEnabled = true
//      recorder.prepareToRecord() // creates/overwrites the file at soundFileURL
//    }
  }
  @IBAction func recordButtonDragExit(sender: UIButton) {
  }
  @IBAction func recordButtonDragEnter(sender: UIButton) {
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

extension InputToolbarView: AVAudioRecorderDelegate{
  func audioRecorderDidFinishRecording(recorder: AVAudioRecorder, successfully flag: Bool) {
    print("Record finished. Success:\(flag)")
  }
  func audioRecorderEncodeErrorDidOccur(recorder: AVAudioRecorder, error: NSError?) {
    print("Record Error: \(error?.localizedDescription)")
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