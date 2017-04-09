//
//  InputToolbarView.swift
//  InstantChat
//
//  Created by Luke Zhao on 2015-05-18.
//  Copyright (c) 2015 SoySauce. All rights reserved.
//

import UIKit
import AVFoundation
import MCollectionView

@objc protocol InputToolbarViewDelegate: InputAccessoryFollowViewDelegate {
  func send(_ text: String)
  func inputToolbarViewNeedFrameUpdate()
}

class InputToolbarView: MCell {
  var textView: UITextView!
  var sendButton: UIImageView!
  var showingPlaceholder = true
  var keyboardFrame: CGRect? {
    return accessoryView.keyboardFrame
  }
  var accessoryView: InputAccessoryFollowView!
  weak var delegate: InputToolbarViewDelegate? {
    didSet {
      accessoryView.delegate = delegate
    }
  }

  override init(frame: CGRect) {
    super.init(frame: frame)

    sendButton = UIImageView(image: UIImage(named: "ic_send"))
    sendButton.tintColor = UIColor(white: 0.6, alpha: 1.0)
    sendButton.contentMode = .center
    addSubview(sendButton)

    textView = UITextView(frame: CGRect.zero)
    addSubview(textView)

    layer.shadowOffset = CGSize.zero
    layer.shadowRadius = 30
    layer.shadowColor = UIColor(white: 0.3, alpha: 1.0).cgColor
    layer.cornerRadius = 10

    a.register(key: "shadowOpacity",
                     getter: { [weak self] in return self?.layer.shadowOpacity },
                     setter: { [weak self] in self?.layer.shadowOpacity = $0 })
    
    backgroundColor = UIColor(white: 0.97, alpha: 0.97)

    textView.delegate = self
    textView.backgroundColor = .clear
    textView.font = UIFont.systemFont(ofSize: 17)
    textViewDidEndEditing(textView)
    accessoryView = InputAccessoryFollowView()
    accessoryView.autoresizingMask = .flexibleHeight
    textView.inputAccessoryView = accessoryView

    tapGR = UITapGestureRecognizer(target: self, action: #selector(tap))
    addGestureRecognizer(tapGR)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    sendButton.bounds.size = CGSize(width: 44, height: 44)
    sendButton.frame.origin = CGPoint(x: bounds.width - sendButton.frame.width, y: (bounds.height - sendButton.frame.height)/2)
    textView.frame = CGRect(x: 8, y: 8, width: bounds.width - sendButton.frame.width, height: bounds.height - 16)
  }

  var recorder: AVAudioRecorder!
  var recordFileURL: URL!
  var meterTimer: Timer!

  override func tap() {
    if sendButton.frame.contains(tapGR.location(in: self)) {
      sendButtonTapped()
    } else if self.bounds.contains(tapGR.location(in: self)) && !textView.isFirstResponder {
      textView.becomeFirstResponder()
    }
  }

  var shaking = false
  func sendButtonTapped() {
    if !showingPlaceholder && textView.text != ""{
      delegate?.send(textView.text)
      setText("")
    } else {
      if !shaking {
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

  func setText(_ text: String) {
    if text == "" && !textView.isFirstResponder {
      showPlaceHolder()
    } else {
      textView.text = text
      textViewDidChange(textView)
    }
  }

  override func sizeThatFits(_ size: CGSize) -> CGSize {
    let textSize = textView.sizeThatFits(CGSize(width: size.width - 16, height: size.height - 16))
    let newHeight = min(textSize.height + 16, 100)
    return CGSize(width: textSize.width + 16, height: newHeight)
  }
}

extension InputToolbarView: UITextViewDelegate {
  func textViewDidChange(_ textView: UITextView) {
    let size = self.sizeThatFits(CGSize(width: frame.width, height: CGFloat.greatestFiniteMagnitude))
    if size.height != frame.height {
      self.delegate?.inputToolbarViewNeedFrameUpdate()
      self.layoutIfNeeded()
    }
  }
  func textViewDidBeginEditing(_ textView: UITextView) {
    if showingPlaceholder {
      showingPlaceholder = false
      textView.text = nil
      textView.textColor = UIColor(red: 131/255, green: 138/255, blue: 147/255, alpha: 1.0)
    }
  }
  func textViewDidEndEditing(_ textView: UITextView) {
    if textView.text.isEmpty {
      showPlaceHolder()
    }
  }
  func showPlaceHolder() {
    showingPlaceholder = true
    textView.text = "Send message..."
    textView.textColor = UIColor(red: 131/255, green: 138/255, blue: 147/255, alpha: 0.7)
  }
}
