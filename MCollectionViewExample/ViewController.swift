//
//  ViewController.swift
//  MCollectionViewExample
//
//  Created by YiLun Zhao on 2016-02-12.
//  Copyright © 2016 lkzhao. All rights reserved.
//

import UIKit
import MotionAnimation


class ViewController: UIViewController, MCollectionViewDataSource, MScrollViewDelegate {

  var collectionView:ElasticCollectionView!
  let inputToolbarView = InputToolbarView()
  
  var messages:[Message] = [
    Message(announcement: "MCollectionView"),
    Message(true, content: "Test Content"),
    Message(true, content: "Test Content"),
    Message(false, content: "Test Content"),
    Message(true, content: "Test Content"),
    Message(false, content: "Test Content"),
    Message(false, content: "Test Content"),
    Message(false, content: "Test Content"),
    Message(true, content: "Test Content"),
    Message(true, content: "Test Content"),
    Message(true, content: "Test Content"),
    Message(true, content: "Test Content"),
    Message(false, content: "Test Content"),
    Message(true, content: "Test Content"),
    Message(false, content: "Test Content"),
    Message(false, content: "Test Content"),
    Message(false, content: "Test Content"),
    Message(true, content: "Test Content"),
    Message(true, content: "Test Content"),
    Message(true, content: "Test Content"),
    Message(true, content: "Test Content"),
    Message(false, content: "Test Content"),
    Message(announcement: "June 9th 11:30 PM"),
    Message(true, content: "Test Content"),
    Message(false, content: "Test Content"),
    Message(false, content: "Test Content"),
    Message(false, content: "Test Content"),
    Message(true, content: "Test Content"),
    Message(true, content: "Test Content"),
    Message(true, content: "Test Content"),
    Message(true, content: "Test Content"),
    Message(false, content: "Test Content"),
    Message(true, content: "Test Content"),
    Message(false, content: "Test Content"),
    Message(false, content: "Test Content"),
    Message(false, content: "Test Content"),
    Message(true, content: "Test Content"),
    Message(true, content: "Test Content"),
    Message(true, content: "Test Content"),
    Message(false, content: "Test Content"),
    Message(false, content: "Test Content"),
    Message(false, content: "Test Content"),
    Message(true, content: "Test Content"),
    Message(true, content: "Test Content"),
    Message(true, content: "Test Content"),
    Message(true, content: "Test Content"),
    Message(announcement: "Yesterday 11:30 PM"),
    Message(false, content: "Test Content"),
    Message(true, content: "Test Content"),
    Message(false, content: "Test Content"),
    Message(false, content: "Test Content"),
    Message(false, content: "Test Content"),
    Message(true, content: "Test Content"),
    Message(true, content: "Test Content"),
    Message(true, content: "Test Content"),
    Message(true, content: "Test Content"),
    Message(false, content: "Test Content"),
    Message(true, content: "Test Content"),
    Message(false, content: "Test Content"),
    Message(false, content: "Test Content"),
    Message(false, content: "Test Content"),
    Message(true, content: "Test Content"),
    Message(true, content: "Test Content"),
    Message(announcement: "Today 9:30 AM"),
    Message(true, content: "Test ContentTest Content"),
    Message(true, content: "Test ContentTest ContentTest ContentTest Content"),
    Message(false, content: "Test Content"),
    Message(true, content: "Test Content"),
    Message(false, content: "Test Content"),
    Message(false, content: "Test ContentTest ContentTest ContentTest ContentTest ContentTest ContentTest ContentTest ContentTest ContentTest ContentTest ContentTest Content"),
    Message(false, content: "Test Content"),
    Message(true, content: "Test Content"),
    Message(true, content: "Test ContentTest ContentTest ContentTest ContentTest Content"),
    Message(true, status: "Delivered"),
  ]
  override func viewDidLoad() {
    super.viewDidLoad()
    view.layer.cornerRadius = 5
    view.backgroundColor = UIColor(white: 0.97, alpha: 1.0)
    collectionView = ElasticCollectionView(frame:view.bounds)
    collectionView.dataSource = self
    collectionView.delegate = self
    view.addSubview(collectionView)
    collectionView.contentInset = UIEdgeInsetsMake(30, 0, 20+54, 0)
    collectionView.reloadData()
    collectionView.scrollToBottom()
    inputToolbarView.frame = CGRectMake(0,view.bounds.height-54,view.bounds.width,54)
    inputToolbarView.delegate = self
    view.addSubview(inputToolbarView)
  }
  
  
  

  
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
    var yHeight = index == 0 ? 0 : CGRectGetMaxY(collectionView.frames[index-1])
    if index != 0{
      yHeight += messages[index].verticalPaddingBetweenMessage(messages[index-1])
    }
    return MessageTextCell.frameForMessage(messages[index], yPosition: yHeight, containerWidth: collectionView.frame.width)
  }
  
  func scrollViewDidScroll(scrollView: MScrollView) {
  }

  func scrollViewDidEndScroll(scrollView: MScrollView) {
  }

  func scrollViewWillStartScroll(scrollView: MScrollView) {
  }
  
  override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
    let isAtBottom = collectionView.isAtBottom
    coordinator.animateAlongsideTransition({ (context) -> Void in
      let bounds = self.view.bounds
      self.collectionView.frame = bounds
      self.inputToolbarView.frame = CGRectMake(0,bounds.height-54,bounds.width,54)
      if isAtBottom{
        self.collectionView.scrollToBottom()
      }
    }, completion: nil)
  }
}

extension ViewController: InputToolbarViewDelegate{
  func inputAccessoryViewDidUpdateFrame(frame:CGRect){
    inputToolbarView.frame.origin = CGPointMake(0, CGRectGetMinY(frame))
    collectionView.contentInset.bottom = view.bounds.height - CGRectGetMinY(inputToolbarView.frame) + 20
    collectionView.scrollToBottom()
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
  func inputToolbarView(view: InputToolbarView, didUpdateHeight height: CGFloat) {
//    let newBottomInset = height + bottomConstraint.constant
//    let diff = newBottomInset - collectionView.contentInset.bottom
//    collectionView.contentOffset.y += diff
//    collectionView.contentInset.bottom = newBottomInset
    //    collectionView.scrollIndicatorInsets.bottom = newBottomInset
    let isAtBottom = collectionView.isAtBottom
    collectionView.contentInset.bottom = self.view.bounds.height - height + 20
    if isAtBottom{
      collectionView.scrollToBottom(true)
    }
  }
}

class TestCollectionVC: UIViewController, MCollectionViewDataSource {
  var collectionView:MCollectionView!
  override func viewDidLoad() {
    super.viewDidLoad()
    collectionView = MCollectionView(frame:view.frame)
    collectionView.dataSource = self;
    view.addSubview(collectionView)
    collectionView.reloadData()
  }
  func numberOfItemsInCollectionView(collectionView:MCollectionView) -> Int{
    return 200
  }
  func collectionView(collectionView:MCollectionView, viewForIndex index:Int) -> UIView{
    let v = UIView(frame: self.collectionView(collectionView, frameForIndex: index))
    v.backgroundColor = UIColor.lightGrayColor()
    //    v.alpha = 0
    //    v.m_animate("alpha", to: 1)
    return v
  }
  func collectionView(collectionView:MCollectionView, frameForIndex index:Int) -> CGRect{
    let columns = 15
    let cellSize = CGSizeMake(100, 100)
    let x = CGFloat(20 + CGFloat(index % columns) * CGFloat(cellSize.width + 20))
    let y = CGFloat(30 + CGFloat(index / columns) * CGFloat(cellSize.height + 20))
    return CGRectMake(x, y, cellSize.width, cellSize.height)
  }
}
