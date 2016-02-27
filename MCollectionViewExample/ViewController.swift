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

  var collectionView:MCollectionView!
  let inputToolbarView = InputToolbarView()

  var sendingMessages:Set<Int> = []
  var messages:[Message] = TestMessages
  var animateLayout = false
  
  // cell reorder
  var dragingCell:UIView?
  var startingDragLocation:CGPoint?
  var startingCellCenter:CGPoint?
  var dragingCellCenter:CGPoint?

  var keyboardHeight:CGFloat{
    if let keyboardFrame = inputToolbarView.keyboardFrame{
      return min(CGRectGetMinY(keyboardFrame), view.bounds.height)
    }
    return view.bounds.height
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    #if DEBUG
      MotionAnimator.sharedInstance.debugEnabled = true
    #endif
    if kIsHighPerformanceDevice{
      view.backgroundColor = UIColor(white: 0.97, alpha: 1.0)
    }
    anchorPoint = CGPointMake(view.bounds.center.x, view.bounds.center.y/2)
    collectionView = MCollectionView(frame:view.bounds)
    collectionView.dataSource = self
    collectionView.delegate = self
    collectionView.autoLayoutOnUpdate = false
    view.addSubview(collectionView)

    inputToolbarView.delegate = self
    view.addSubview(inputToolbarView)

    // stress test
//    for j in 0...200{
//      for i in TestMessages{
//        messages.append(i.copy())
//      }
//    }
    print("Message count:\(messages.count)")
    viewDidLayoutSubviews()
    collectionView.reloadData() {
      self.collectionView.scrollToBottom()
    }
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
    anchorPoint = CGPointMake(view.bounds.center.x, view.bounds.center.y/2)
    collectionView.frame = view.bounds
    let inputPadding:CGFloat = 10
    let inputSize = inputToolbarView.sizeThatFits(CGSizeMake(view.bounds.width - 2 * inputPadding, view.bounds.height))
    let inputToolbarFrame = CGRectMake(inputPadding, keyboardHeight - inputSize.height - inputPadding, view.bounds.width - 2*inputPadding, inputSize.height)
    if animateLayout{
      inputToolbarView.animateCenterTo(inputToolbarFrame.center, stiffness: 300, damping: 25)
      inputToolbarView.m_animate("bounds", to: inputToolbarFrame.bounds, stiffness: 300, damping: 25)
    }else{
      inputToolbarView.center = inputToolbarFrame.center
      inputToolbarView.bounds = inputToolbarFrame.bounds
    }
    collectionView.contentInset = UIEdgeInsetsMake(30, 0, view.bounds.height - CGRectGetMinY(inputToolbarFrame) + 20, 0)
  }

  override func prefersStatusBarHidden() -> Bool {
    return true
  }

  /* anchorPoint is usually where the user drags
   * it is used to determine the relative offset for each cell
   * when draging, the cell closer to the anchorPoint will have a lower offset
   * and vice versa.
   * value should be within view.bounds
   */
  var anchorPoint:CGPoint!
  func adjustedRect(index:Int) -> CGRect{
    let screenDragLocation = collectionView.contentOffset + anchorPoint
    let cellFrame = collectionView.frames[index]
    //        let cellOffset = abs(cellFrame.center.y - screenDragLocation.y) * collectionView.scrollVelocity / 5000
    let cellOffset = cellFrame.center.distance(screenDragLocation) * collectionView.scrollVelocity / 5000
    return CGRect(origin: cellFrame.origin + cellOffset, size: cellFrame.size)
  }

  func adjustedScale(index:Int) -> CGFloat{
    let cellFrame = collectionView.frames[index]
    let screenLocation = cellFrame.center - collectionView.contentOffset
    if screenLocation.y < 25{
      return min(1,0.5 + (screenLocation.y / 50)*0.5)
    } else if screenLocation.y > collectionView.bounds.size.height - 50 {
      return min(1,0.5 + ((collectionView.bounds.size.height - screenLocation.y) / 50)*0.5)
    }
    return 1.0
  }

  var loading = false
}

extension ViewController: MCollectionViewDataSource{
  func numberOfItemsInCollectionView(collectionView:MCollectionView) -> Int{
    return messages.count
  }

  func collectionView(collectionView:MCollectionView, viewForIndex index:Int) -> UIView{
    let v = (collectionView.dequeueReusableViewWithIdentifier("MessageTextCell") ?? MessageTextCell()) as! MessageTextCell
    let frame = collectionView.frames[index]
    v.message = messages[index]
    v.center = frame.center
    v.bounds = frame.bounds
    v.layer.zPosition = CGFloat(index)
    v.delegate = self
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

  func collectionView(collectionView: MCollectionView, identifierForIndex index: Int) -> String {
    return messages[index].identifier
  }

  func collectionView(collectionView: MCollectionView, didInsertCellView cellView: UIView, atIndex index: Int) {
    if sendingMessages.contains(index){
      // we just sent this message, lets animate it from inputToolbarView to it's position
      cellView.center = collectionView.contentView.convertPoint(inputToolbarView.center, fromView: view)
      cellView.bounds = inputToolbarView.bounds
      cellView.alpha = 0
      cellView.m_animate("bounds", to: collectionView.frames[index].bounds, stiffness: 200, damping: 20) {
        self.sendingMessages.remove(index)
      }
      cellView.m_animate("alpha", to: 1.0, damping: 25)
      // no need to animate center, it is done in `didUpdateScreenPositionForIndex`
    } else {
      cellView.alpha = 0
      cellView.m_setValues([0], forCustomProperty: "scale")
      cellView.m_animate("alpha", to: 1, stiffness:250, damping: 25)
      cellView.m_animate("scale", to: 1, stiffness:250, damping: 25)
    }
  }

  func collectionView(collectionView: MCollectionView, didDeleteCellView cellView: UIView, atIndex index: Int) {
    cellView.m_animate("alpha", to: 0, stiffness:250, damping: 25)
    cellView.m_animate("scale", to: 0, stiffness:250, damping: 25) {
      cellView.removeFromSuperview()
    }
  }

  func collectionView(collectionView:MCollectionView, cellView:UIView, didAppearForIndex index:Int){

  }
  func collectionView(collectionView:MCollectionView, cellView:UIView, willDisappearForIndex index:Int){}
  func collectionView(collectionView:MCollectionView, cellView:UIView, didUpdateScreenPositionForIndex index:Int, screenPosition:CGPoint)
  {
    if cellView != dragingCell{
      cellView.animateCenterTo(adjustedRect(index).center, stiffness: 150, damping:20, threshold: 1)
    } else {
      cellView.animateCenterTo(dragingCellCenter!, stiffness: 500, damping:25)
    }
  }
}

extension ViewController: InputToolbarViewDelegate{
  func inputAccessoryViewDidUpdateFrame(frame:CGRect){
    let oldContentInset = collectionView.contentInset
    self.viewDidLayoutSubviews()
    if oldContentInset != collectionView.contentInset{
      anchorPoint = CGPointMake(view.bounds.center.x, view.bounds.center.y/2)
      collectionView.scrollToBottom(true)
    }
  }
  func send(audio: NSURL, length: NSTimeInterval) {
    //    let msg = chat.sendAudioMessage(audio, length:length)
    //    chat(chat, didReceiveNewMessage: msg)
    //    scrollToEnd()
  }
  func send(text: String) {
    let sendingMessage = Message(true,content: text);
    sendingMessages.insert(messages.count)
    messages.append(sendingMessage)
    collectionView.reloadData()
    collectionView.scrollToBottom(true)
  }
  func inputToolbarViewNeedFrameUpdate() {
    let isAtBottom = collectionView.isAtBottom
    self.viewDidLayoutSubviews()
    if isAtBottom{
      collectionView.scrollToBottom(true)
    }
  }
}

extension ViewController: MessageTextCellDelegate{
  func messageCellDidBeginHolding(cell: MessageTextCell, gestureRecognizer: UILongPressGestureRecognizer) {
    startingDragLocation = gestureRecognizer.locationInView(collectionView) + collectionView.contentOffset
    startingCellCenter = cell.center
    dragingCell = cell
    cell.layer.zPosition = CGFloat(500)
  }
  func messageCellDidEndHolding(cell: MessageTextCell, gestureRecognizer: UILongPressGestureRecognizer) {
    if let index = collectionView.indexOfView(cell){
      let center = collectionView.frames[index].center
      cell.animateCenterTo(center)
      dragingCell = nil
      cell.layer.zPosition = CGFloat(index)
    }
  }
  func messageCellDidMoveWhileHolding(cell: MessageTextCell, gestureRecognizer: UILongPressGestureRecognizer) {
    if let index = collectionView.indexOfView(cell){
      var center = startingCellCenter!
      let newLocation = gestureRecognizer.locationInView(collectionView) + collectionView.contentOffset
      center = center + newLocation - startingDragLocation!
      if let toIndex = collectionView.indexForItemAtPoint(center) where toIndex != index{
        messages.insert(messages.removeAtIndex(index), atIndex: toIndex)
        collectionView.reloadData()
      }
      var velocity = CGPointZero
      if cell.frame.minY - collectionView.contentOffset.y < 100{
        velocity.y = -500
      } else if cell.frame.maxY - collectionView.contentOffset.y > collectionView.bounds.height - collectionView.contentInset.bottom - 100{
        velocity.y = 500
      }
      collectionView.scrollAnimation.velocity = velocity
      collectionView.scrollAnimation.animateDone()
      dragingCellCenter = center
    }
  }
  func messageCellDidTap(cell: MessageTextCell) {
    if let index = self.collectionView.indexOfView(cell){
      self.messages.removeAtIndex(index)
      self.collectionView.reloadData()
    }
  }
}
extension ViewController: MScrollViewDelegate{
  func scrollViewDidScroll(scrollView: MScrollView) {
    if inputToolbarView.textView.isFirstResponder(){
      if scrollView.draging && scrollView.panGestureRecognizer.velocityInView(scrollView).y > 100{
        inputToolbarView.stopAllAnimation()
        inputToolbarView.textView.resignFirstResponder()
      }
    }
    if scrollView.contentOffset.y < 200{
      if loading == false{
        loading = true
        NSTimer.schedule(delay: 0.5, handler: { (timer) in
          var newMessage:[Message] = []
          for i in TestMessages{
            newMessage.append(i.copy())
          }
          let currentOffsetDiff = self.collectionView.frames[0].minY - self.collectionView.contentOffset.y
          self.messages = newMessage + self.messages
          print("load new messages count:\(self.messages.count)")
          self.collectionView.reloadData() {
            let offset = self.collectionView.frames[newMessage.count].minY - currentOffsetDiff
            self.collectionView.contentOffset.y = offset
          }
          self.loading = false
        })
      }
    }
    inputToolbarView.showShadow = scrollView.contentOffset.y < scrollView.bottomOffset.y - 10 || inputToolbarView.textView.isFirstResponder()
  }

  func scrollViewDidEndScroll(scrollView: MScrollView) {}
  func scrollViewWillStartScroll(scrollView: MScrollView) {}
  func scrollViewDidEndDraging(scrollView: MScrollView) {}
  func scrollViewDidDrag(scrollView: MScrollView) {
    anchorPoint = scrollView.dragLocation
  }
  func scrollViewWillBeginDraging(scrollView: MScrollView) {

  }
}
