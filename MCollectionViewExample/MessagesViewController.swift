//
//  MessagesViewController.swift
//  MCollectionViewExample
//
//  Created by YiLun Zhao on 2016-02-12.
//  Copyright © 2016 lkzhao. All rights reserved.
//

import UIKit
import MotionAnimation

class MessagesViewController: UIViewController {

  var collectionView:MCollectionView!
  let inputToolbarView = InputToolbarView()

  var sendingMessages:Set<Int> = []
  var messages:[Message] = TestMessages
  var loading = false
  
  // cell reorder
  var dragingCell:UIView?{
    didSet{
      if let dragingCell = dragingCell{
        collectionView.floatingCells = [dragingCell]
      } else {
        collectionView.floatingCells = []
      }
    }
  }
  var startingDragLocation:CGPoint?
  var startingCellCenter:CGPoint?
  var dragingCellCenter:CGPoint?
  var canReorder = true

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
    view.backgroundColor = UIColor(white: 0.97, alpha: 1.0)
    view.clipsToBounds = true
    collectionView = MCollectionView(frame:view.bounds)
    collectionView.collectionDelegate = self
    collectionView.scrollDelegate = self
    collectionView.wabble = true
    collectionView.optimizeForContinuousLayout = true
    view.addSubview(collectionView)

    inputToolbarView.delegate = self
    view.addSubview(inputToolbarView)
    inputToolbarView.layer.zPosition = 2000
    
    layout(false)
    collectionView.reloadData()
  }
  
  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    collectionView.scrollToBottom()
  }

  func layout(animate:Bool = true){
    let isAtBottom = collectionView.isAtBottom
    collectionView.frame = view.bounds
    let inputPadding:CGFloat = 10
    let inputSize = inputToolbarView.sizeThatFits(CGSizeMake(view.bounds.width - 2 * inputPadding, view.bounds.height))
    let inputToolbarFrame = CGRectMake(inputPadding, keyboardHeight - inputSize.height - inputPadding, view.bounds.width - 2*inputPadding, inputSize.height)
    if animate {
      inputToolbarView.m_animate("center", to: inputToolbarFrame.center, stiffness: 300, damping: 25)
      inputToolbarView.m_animate("bounds", to: inputToolbarFrame.bounds, stiffness: 300, damping: 25)
    } else {
      inputToolbarView.bounds = inputToolbarFrame.bounds;
      inputToolbarView.center = inputToolbarFrame.center;
    }
    collectionView.contentInset = UIEdgeInsetsMake(topLayoutGuide.length + 30, 0, view.bounds.height - CGRectGetMinY(inputToolbarFrame) + 20, 0)
    if isAtBottom{
      collectionView.scrollToBottom()
    }
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    layout()
  }
}


// collectionview datasource and layout
extension MessagesViewController: MCollectionViewDelegate{
  func numberOfSectionsInCollectionView(collectionView: MCollectionView) -> Int {
    return 1
  }
  
  func collectionView(collectionView: MCollectionView, numberOfItemsInSection section: Int) -> Int {
    return messages.count
  }
  
  func collectionView(collectionView: MCollectionView, viewForIndexPath indexPath: NSIndexPath, initialFrame: CGRect) -> UIView {
    let v = collectionView.dequeueReusableView(MessageTextCell) ?? MessageTextCell()
    v.message = messages[indexPath.item]
    v.center = initialFrame.center
    v.bounds = initialFrame.bounds
    v.layer.zPosition = CGFloat(indexPath.item) * 200
    v.delegate = self
    return v
  }
  
  func collectionView(collectionView: MCollectionView, identifierForIndexPath indexPath: NSIndexPath) -> String {
    return messages[indexPath.item].identifier
  }
  
  func collectionView(collectionView: MCollectionView, frameForIndexPath indexPath: NSIndexPath) -> CGRect {
    var yHeight:CGFloat = 0
    var xOffset:CGFloat = 10
    let message = messages[indexPath.item]
    var cellFrame = MessageTextCell.frameForMessage(messages[indexPath.item], containerWidth: collectionView.frame.width - 2 * xOffset)
    if indexPath.item != 0{
      let lastMessage = messages[indexPath.item-1]
      let lastFrame = collectionView.frameForIndexPath(NSIndexPath(forItem: indexPath.item - 1, inSection: indexPath.section))!
      
      let maxWidth = view.bounds.width - 20
      if message.type == .Image &&
        lastMessage.type == .Image && message.alignment == lastMessage.alignment{
        if message.alignment == .Left && CGRectGetMaxX(lastFrame) + cellFrame.width + 2 < maxWidth{
          yHeight = CGRectGetMinY(lastFrame)
          xOffset = CGRectGetMaxX(lastFrame) + 2
        } else if message.alignment == .Right && CGRectGetMinX(lastFrame) - cellFrame.width - 2 > view.bounds.width - maxWidth{
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
  
  func collectionView(collectionView: MCollectionView, didInsertCellView cellView: UIView, atIndexPath indexPath: NSIndexPath) {
    if sendingMessages.contains(indexPath.item){
      // we just sent this message, lets animate it from inputToolbarView to it's position
      cellView.center = collectionView.contentView.convertPoint(inputToolbarView.center, fromView: view)
      cellView.bounds = inputToolbarView.bounds
      cellView.alpha = 0
      let frame = collectionView.frameForIndexPath(indexPath)
      cellView.m_animate("bounds", to: frame!.bounds, stiffness: 300, damping: 30) {
        self.sendingMessages.remove(indexPath.item)
      }
      cellView.m_animate("alpha", to: 1.0, damping: 25)
      //      cellView.m_animate("center",to:frame!.center, stiffness: 150, damping:20, threshold: 1)
    } else if messages[indexPath.item].alignment == .Left{
      let center = cellView.center
      cellView.center = CGPointMake(center.x - view.bounds.width, center.y)
      cellView.m_animate("center", to: center, stiffness:250, damping: 20)
    } else if messages[indexPath.item].alignment == .Right{
      let center = cellView.center
      cellView.center = CGPointMake(center.x + view.bounds.width, center.y)
      cellView.m_animate("center", to: center, stiffness:250, damping: 20)
    } else {
      cellView.alpha = 0
      cellView.m_setValues([0], forCustomProperty: "scale")
      cellView.m_animate("alpha", to: 1, stiffness:250, damping: 25)
      cellView.m_animate("scale", to: 1, stiffness:250, damping: 25)
    }
  }
  
  func collectionView(collectionView: MCollectionView, didDeleteCellView cellView: UIView, atIndexPath indexPath: NSIndexPath) {
    cellView.m_animate("alpha", to: 0, stiffness:250, damping: 25)
    cellView.m_animate("scale", to: 0, stiffness:250, damping: 25) {
      cellView.removeFromSuperview()
    }
  }
  func collectionView(collectionView: MCollectionView, didReloadCellView cellView: UIView, atIndexPath indexPath: NSIndexPath) {
    if let cellView = cellView as? MessageTextCell, frame = collectionView.frameForIndexPath(indexPath){
      cellView.message = messages[indexPath.item]
      if cellView != dragingCell {
        cellView.m_animate("bounds", to:frame.bounds, stiffness: 150, damping:20, threshold: 1)
        cellView.m_animate("center", to:frame.center, stiffness: 150, damping:20, threshold: 1)
        cellView.m_animate("scale", to: 1, stiffness:250, damping: 25)
        cellView.layer.zPosition = CGFloat(indexPath.item) * 100
      }
    }
  }
  
  func collectionView(collectionView: MCollectionView, cellView: UIView, didUpdateScreenPositionForIndexPath indexPath: NSIndexPath, screenPosition: CGPoint) {
    if let dragingCellCenter = dragingCellCenter where cellView == dragingCell{
      cellView.m_animate("center", to:collectionView.contentView.convertPoint(dragingCellCenter, fromView: view), stiffness: 500, damping: 25)
    }
  }
}

// For sending new messages
extension MessagesViewController: InputToolbarViewDelegate{
  func inputAccessoryViewDidUpdateFrame(frame:CGRect){
    let oldContentInset = collectionView.contentInset
    self.viewDidLayoutSubviews()
    if oldContentInset != collectionView.contentInset{
      collectionView.scrollToBottom(true)
    }
  }
  func send(text: String) {
    let sendingMessage = Message(true,content: text);
    sendingMessages.insert(messages.count)
    messages.append(sendingMessage)
    collectionView.reloadData()
    collectionView.scrollToBottom(true)
    delay(1.0) { 
      self.messages.append(Message(false,content: text))
      self.collectionView.reloadData()
      self.collectionView.scrollToBottom(true)
    }
  }
  func inputToolbarViewNeedFrameUpdate() {
    let isAtBottom = collectionView.isAtBottom
    self.viewDidLayoutSubviews()
    if isAtBottom{
      collectionView.scrollToBottom(true)
    }
  }
}


// For reordering
extension MessagesViewController: MessageTextCellDelegate{
  func messageCellDidBeginHolding(cell:MessageTextCell, gestureRecognizer: UILongPressGestureRecognizer) {
    if dragingCell != nil{
      return
    }
    cell.tilt3D = true
    startingDragLocation = gestureRecognizer.locationInView(collectionView) + collectionView.contentOffset
    startingCellCenter = cell.center
    dragingCell = cell
    dragingCellCenter = startingCellCenter
    cell.layer.zPosition = CGFloat(messages.count + 100)*1000
    
    messageCellDidMoveWhileHolding(cell, gestureRecognizer: gestureRecognizer)
  }
  func messageCellDidMoveWhileHolding(cell:MessageTextCell, gestureRecognizer: UILongPressGestureRecognizer) {
    if cell != dragingCell{
      return
    }
    if let index = collectionView.indexPathOfView(cell)?.item{
      var center = startingCellCenter!
      let newLocation = gestureRecognizer.locationInView(collectionView) + collectionView.contentOffset
      center = center + newLocation - startingDragLocation!
      var velocity = CGPointZero
      dragingCellCenter = view.convertPoint(center, fromView:collectionView.contentView)
      let fingerPosition = gestureRecognizer.locationInView(view)
      if fingerPosition.y < 80 && collectionView.contentOffset.y > 0{
        velocity.y = -(80 - fingerPosition.y) * 30
      } else if fingerPosition.y > view.bounds.height - 80 &&
        collectionView.contentOffset.y + collectionView.bounds.height < collectionView.containerSize.height{
        velocity.y = (fingerPosition.y - (view.bounds.height - 80)) * 30
      } else if let toIndex = collectionView.indexPathForItemAtPoint(center)?.item where toIndex != index && canReorder{
        canReorder = false
        delay(0.5) {
          self.canReorder = true
        }
        moveMessageAtIndex(index, toIndex: toIndex)
      }
      collectionView.scrollAnimation.velocity = velocity
      collectionView.scrollAnimation.animateDone()
    }
  }
  func messageCellDidEndHolding(cell:MessageTextCell, gestureRecognizer: UILongPressGestureRecognizer) {
    if cell != dragingCell{
      return
    }
    if let index = collectionView.indexPathOfView(cell)?.item{
      // one last check if we need to move
      var center = startingCellCenter!
      let newLocation = gestureRecognizer.locationInView(collectionView) + collectionView.contentOffset
      center = center + newLocation - startingDragLocation!
      if let toIndex = collectionView.indexPathForItemAtPoint(center)?.item where toIndex != index && canReorder{
        canReorder = false
        delay(0.5) {
          self.canReorder = true
        }
        moveMessageAtIndex(index, toIndex: toIndex)
        center = collectionView.frameForIndexPath(NSIndexPath(forItem: toIndex, inSection: 0))!.center
      } else {
        center = collectionView.frameForIndexPath(NSIndexPath(forItem: index, inSection: 0))!.center
      }
      dragingCellCenter = nil
      dragingCell = nil
      cell.tilt3D = false
      cell.layer.zPosition = CGFloat(index)*1000
      cell.m_animate("center", to:center, stiffness: 150, damping: 15)
    }
  }
  
  func messageCellDidTap(cell: MessageTextCell) {
    
  }

  func moveMessageAtIndex(index:Int, toIndex:Int){
    if index == toIndex {
      return
    }
    let m = messages.removeAtIndex(index)
    messages.insert(m, atIndex: toIndex)
    collectionView.reloadData()
  }
}

extension MessagesViewController: MScrollViewDelegate{
  func scrollViewScrolled(scrollView: MScrollView) {
    // dismiss keyboard
    if inputToolbarView.textView.isFirstResponder(){
      if scrollView.draging && scrollView.panGestureRecognizer.velocityInView(scrollView).y > 100{
        inputToolbarView.textView.resignFirstResponder()
      }
    }
    
    // PULL TO LOAD MORE
    // load more messages if we scrolled to the top
    if scrollView.contentOffset.y < 400 && loading == false{
      loading = true
      delay(0.5){ // Simulate network request
        var newMessage:[Message] = []
        for i in TestMessages{
          newMessage.append(i.copy())
        }
        let currentOffsetDiff = self.collectionView.frames[0][0].minY - self.collectionView.contentOffset.y
        self.messages = newMessage + self.messages
        print("load new messages count:\(self.messages.count)")
        self.collectionView.reloadData() {
          let offset = self.collectionView.frames[0][newMessage.count].minY - currentOffsetDiff
          self.collectionView.contentOffset.y = offset
        }
        self.loading = false
      }
    }
    inputToolbarView.showShadow = scrollView.contentOffset.y < scrollView.bottomOffset.y - 10 || inputToolbarView.textView.isFirstResponder()
  }
}
