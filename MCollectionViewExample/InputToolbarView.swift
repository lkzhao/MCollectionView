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
  var sendButton:UIButton!
  var keyboardFrame:CGRect?{
    return accessoryView.keyboardFrame
  }
  var accessoryView:InputAccessoryFollowView!
  weak var delegate:InputToolbarViewDelegate?{
    didSet{
      accessoryView.delegate = delegate
    }
  }
  
  var showShadow:Bool = false{
    didSet{
      if showShadow != oldValue{
        self.m_animate("shadowOpacity", to: [(showShadow ? 0.3 : 0)], stiffness: 100, damping: 20)
      }
    }
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    
    sendButton = UIButton(type: UIButtonType.System)
    sendButton.tintColor = UIColor(white: 0.6, alpha: 1.0)
    sendButton.setImage(UIImage(named: "ic_send"), forState: .Normal)
    sendButton.addTarget(self, action: "sendButtonTapped:", forControlEvents: .TouchUpInside)
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
    backgroundColor = UIColor(white: 1.0, alpha: 0.97)
    
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
  
  func sendButtonTapped(sender:UIButton){
    delegate?.send(textView.text)
    setText("")
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
    textView.text = text
    textViewDidChange(textView)
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
  
  override func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
    return !self.textView.isFirstResponder()
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
    if textView.textColor != UIColor(red: 131/255, green: 138/255, blue: 147/255, alpha: 1.0) {
      textView.text = nil
      textView.textColor = UIColor(red: 131/255, green: 138/255, blue: 147/255, alpha: 1.0)
    }
  }
  func textViewDidEndEditing(textView: UITextView) {
    if textView.text.isEmpty {
      textView.text = "Your messages..."
      textView.textColor = UIColor(red: 131/255, green: 138/255, blue: 147/255, alpha: 0.7)

    }
  }
}