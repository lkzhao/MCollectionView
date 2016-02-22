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
  func inputToolbarView(view:InputToolbarView, didUpdateHeight height:CGFloat)
}

class InputToolbarView: UIView {
  var textView:UITextView!
  var sendButton:UIButton!
  var accessoryView:InputAccessoryFollowView!
  weak var delegate:InputToolbarViewDelegate?{
    didSet{
      accessoryView.delegate = delegate
    }
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    sendButton = UIButton(type: UIButtonType.System)
    sendButton.setTitle("Send", forState: UIControlState.Normal)
    sendButton.addTarget(self, action: "sendButtonTapped:", forControlEvents: .TouchUpInside)
    addSubview(sendButton)

    textView = UITextView(frame: CGRectZero)
    addSubview(textView)
    
    layer.shadowOffset = CGSizeZero
    layer.shadowOpacity = 0.3
    layer.shadowRadius = 50
    layer.shadowColor = UIColor(white: 0.3, alpha: 1.0).CGColor
    backgroundColor = UIColor(white: 1.0, alpha: 0.97)
    
    textView.delegate = self
    textView.backgroundColor = .clearColor()
    textView.font = UIFont.systemFontOfSize(17)
    textViewDidEndEditing(textView)
    accessoryView = InputAccessoryFollowView(frame: bounds)
    accessoryView.autoresizingMask = .FlexibleHeight
    textView.inputAccessoryView = accessoryView
  }

  required init?(coder aDecoder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    sendButton.frame = CGRectMake(bounds.width - 108, 8, 100, bounds.height - 16)
    textView.frame = CGRectMake(8, 8, bounds.width - 16 - 100, bounds.height - 16)
    accessoryView.frame = bounds
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
    let size = textView.sizeThatFits(CGSizeMake(textView.frame.width, 0))
    let newHeight = min(max(38, size.height), 38*5)
    if newHeight != textView.frame.height{
      print(newHeight, textView.frame.height)
      let newFrame = CGRect(origin: CGPointMake(0, frame.origin.y - (newHeight - textView.frame.height)), size: CGSizeMake(self.frame.width, newHeight+16))
      UIView.animateWithDuration(0.2, animations: { () -> Void in
        self.frame = newFrame
        self.layoutSubviews()
      })
      accessoryView.frame = self.bounds
      accessoryView.superview?.layoutIfNeeded()
      if textView.text.characters.count > 0{
        textView.scrollRangeToVisible(NSMakeRange(textView.text.characters.count-1, 1))
      }
      delegate?.inputToolbarView(self, didUpdateHeight: CGRectGetMinY(newFrame))
    }
  }
  func textViewDidBeginEditing(textView: UITextView) {
    if textView.textColor != UIColor(white: 0.2, alpha: 1.0) {
      textView.text = nil
      textView.textColor = UIColor(white: 0.2, alpha: 1.0)
    }
  }
  func textViewDidEndEditing(textView: UITextView) {
    if textView.text.isEmpty {
      textView.text = "Your messages..."
      textView.textColor = UIColor(red: 131/255, green: 138/255, blue: 147/255, alpha: 1.0)
    }
  }
}