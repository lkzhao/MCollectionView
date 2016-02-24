//
//  ViewController.swift
//  MCollectionViewExample
//
//  Created by YiLun Zhao on 2016-02-12.
//  Copyright © 2016 lkzhao. All rights reserved.
//

import UIKit
import MotionAnimation

class ViewController: UIViewController {

  var collectionView:ElasticCollectionView!
  let inputToolbarView = InputToolbarView()
  
  var messages:[Message] = TestMessages
  var animateLayout = false

  var keyboardFrame:CGRect{
    return inputToolbarView.keyboardFrame ?? CGRectMake(0, view.frame.height+1, view.frame.width, view.frame.height/2)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    if kIsHighPerformanceDevice{
      view.backgroundColor = UIColor(white: 0.97, alpha: 1.0)
    }

    collectionView = ElasticCollectionView(frame:view.bounds)
    collectionView.dataSource = self
    collectionView.delegate = self
    view.addSubview(collectionView)

    inputToolbarView.delegate = self
    view.addSubview(inputToolbarView)
    
    collectionView.reloadData()
    viewDidLayoutSubviews()
    collectionView.scrollToBottom()
    animateLayout = true
  }
  
  // screen rotation
  override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
    let isAtBottom = collectionView.isAtBottom
    coordinator.animateAlongsideTransition({ (context) -> Void in
      self.viewDidLayoutSubviews()
      if isAtBottom{
        self.collectionView.scrollToBottom()
      }
    }, completion: nil)
  }

  // layout
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    collectionView.frame = view.bounds
    let inputPadding:CGFloat = 10
    let inputSize = inputToolbarView.sizeThatFits(CGSizeMake(view.bounds.width - 2 * inputPadding, view.bounds.height))
    let inputToolbarFrame = CGRectMake(inputPadding, keyboardFrame.minY - inputSize.height - inputPadding, view.bounds.width - 2*inputPadding, inputSize.height)
    if animateLayout{
      inputToolbarView.m_animate("center", to: inputToolbarFrame.center, stiffness: 400, damping: 25)
      inputToolbarView.m_animate("bounds", to: inputToolbarFrame.bounds, stiffness: 400, damping: 25)
    }else{
      inputToolbarView.center = inputToolbarFrame.center
      inputToolbarView.bounds = inputToolbarFrame.bounds
    }
    collectionView.contentInset = UIEdgeInsetsMake(30, 0, view.bounds.height - CGRectGetMinY(inputToolbarFrame) + 20, 0)
  }
}

extension ViewController: MCollectionViewDataSource{
  func numberOfItemsInCollectionView(collectionView:MCollectionView) -> Int{
    return messages.count
  }
  
  func collectionView(collectionView:MCollectionView, viewForIndex index:Int) -> UIView{
    let v = (collectionView.dequeueReusableViewWithIdentifier("MessageTextCell") ?? MessageTextCell()) as! MessageTextCell
    let frame = collectionView.frames[index]
    v.center = frame.center
    v.bounds = frame.bounds
    v.message = messages[index]
    v.layer.zPosition = CGFloat(index)
    return v
  }
  
  func collectionView(collectionView:MCollectionView, frameForIndex index:Int) -> CGRect{
    var yHeight:CGFloat = 0
    var xOffset:CGFloat = 10
    let message = messages[index]
    var cellFrame = MessageTextCell.frameForMessage(messages[index], containerWidth: collectionView.frame.width - 2 * xOffset)
    if index != 0{
      let lastMessage = messages[index-1]
      let lastFrame = collectionView.frames[index-1]
      
      if message.type == .Image &&
        lastMessage.type == .Image && message.alignment == lastMessage.alignment{
          if message.alignment == .Left && CGRectGetMaxX(lastFrame) + cellFrame.width + 2 < 300{
            yHeight = CGRectGetMinY(lastFrame)
            xOffset = CGRectGetMaxX(lastFrame) + 2
          } else if message.alignment == .Right && CGRectGetMinX(lastFrame) - cellFrame.width - 2 > view.bounds.width - 300{
            yHeight = CGRectGetMinY(lastFrame)
            xOffset = CGRectGetMinX(lastFrame) - 2 - cellFrame.width
            cellFrame.origin.x = 0
          } else{
            yHeight = CGRectGetMaxY(lastFrame) + message.verticalPaddingBetweenMessage(lastMessage)
          }
      } else {
        yHeight = CGRectGetMaxY(lastFrame) + message.verticalPaddingBetweenMessage(lastMessage)
      }
    }
    cellFrame.origin.x += xOffset
    cellFrame.origin.y = yHeight
    return cellFrame
  }
}

extension ViewController: InputToolbarViewDelegate{
  func inputAccessoryViewDidUpdateFrame(frame:CGRect){
    self.viewDidLayoutSubviews()
    let animate = collectionView.bottomOffset.y - collectionView.contentOffset.y < view.bounds.height
    collectionView.scrollToBottom(animate)
  }
  func send(audio: NSURL, length: NSTimeInterval) {
//    let msg = chat.sendAudioMessage(audio, length:length)
//    chat(chat, didReceiveNewMessage: msg)
//    scrollToEnd()
  }
  func send(text: String) {
    messages.append(Message(true,content: text))
    collectionView.reloadData()
    let animate = collectionView.bottomOffset.y - collectionView.contentOffset.y < view.bounds.height
    collectionView.scrollToBottom(animate)
  }
  func inputToolbarViewNeedFrameUpdate() {
    let isAtBottom = collectionView.isAtBottom
    self.viewDidLayoutSubviews()
    if isAtBottom{
      collectionView.scrollToBottom(true)
    }
  }
}

extension ViewController: MScrollViewDelegate{
  func scrollViewDidScroll(scrollView: MScrollView) {
    if inputToolbarView.textView.isFirstResponder(){
      if scrollView.draging && scrollView.panGestureRecognizer.velocityInView(scrollView).y > 100{
        inputToolbarView.textView.resignFirstResponder()
      }
    }
    inputToolbarView.showShadow = scrollView.contentOffset.y < scrollView.bottomOffset.y - 10 || inputToolbarView.textView.isFirstResponder()
  }
  
  func scrollViewDidEndScroll(scrollView: MScrollView) {}
  func scrollViewWillStartScroll(scrollView: MScrollView) {}
  func scrollViewDidEndDraging(scrollView: MScrollView) {}
  func scrollViewWillBeginDraging(scrollView: MScrollView) {}
}
