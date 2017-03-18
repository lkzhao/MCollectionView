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

  var collectionView: MCollectionView!
  let inputToolbarView = InputToolbarView()

  var sendingMessage = false
  var messages: [Message] = TestMessages
  var loading = false

  // cell reorder
  var dragingCell: UIView? {
    didSet {
      if let dragingCell = dragingCell {
        collectionView.floatingCells = [dragingCell]
      } else {
        collectionView.floatingCells = []
      }
    }
  }
  var startingDragLocation: CGPoint?
  var startingCellCenter: CGPoint?
  var dragingCellCenter: CGPoint?
  var canReorder = true

  var keyboardHeight: CGFloat {
    if let keyboardFrame = inputToolbarView.keyboardFrame {
      return min(keyboardFrame.minY, view.bounds.height)
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
    collectionView.autoRemoveCells = false
    view.addSubview(collectionView)

    inputToolbarView.delegate = self
    view.addSubview(inputToolbarView)
    inputToolbarView.layer.zPosition = 2000

    layout(false)
    collectionView.reloadData()
    collectionView.scroll(to: .bottom, animate:false)
  }

  func layout(_ animate: Bool = true) {
    let isAtBottom = collectionView.isAt(.bottom)
    collectionView.frame = view.bounds
    let inputPadding: CGFloat = 10
    let inputSize = inputToolbarView.sizeThatFits(CGSize(width: view.bounds.width - 2 * inputPadding, height: view.bounds.height))
    let inputToolbarFrame = CGRect(x: inputPadding, y: keyboardHeight - inputSize.height - inputPadding, width: view.bounds.width - 2*inputPadding, height: inputSize.height)
    if animate {
      inputToolbarView.m_animate("center", to: inputToolbarFrame.center, stiffness: 300, damping: 25)
      inputToolbarView.m_animate("bounds", to: inputToolbarFrame.bounds, stiffness: 300, damping: 25)
    } else {
      inputToolbarView.bounds = inputToolbarFrame.bounds
      inputToolbarView.center = inputToolbarFrame.center
    }
    collectionView.contentInset = UIEdgeInsetsMake(topLayoutGuide.length + 30, 0, view.bounds.height - inputToolbarFrame.minY + 20, 0)
    if isAtBottom {
      collectionView.scroll(to: .bottom, animate: animate)
    }
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    layout()
  }
}

// collectionview datasource and layout
extension MessagesViewController: MCollectionViewDelegate {
  func numberOfSectionsInCollectionView(_ collectionView: MCollectionView) -> Int {
    return 1
  }

  func collectionView(_ collectionView: MCollectionView, numberOfItemsInSection section: Int) -> Int {
    return messages.count
  }

  func collectionView(_ collectionView: MCollectionView, viewForIndexPath indexPath: IndexPath, initialFrame: CGRect) -> UIView {
    let v = collectionView.dequeueReusableView(MessageTextCell.self) ?? MessageTextCell()
    v.message = messages[(indexPath as NSIndexPath).item]
    v.center = initialFrame.center
    v.bounds = initialFrame.bounds
    v.layer.zPosition = CGFloat((indexPath as NSIndexPath).item) * 200
    v.delegate = self
    return v
  }

  func collectionView(_ collectionView: MCollectionView, identifierForIndexPath indexPath: IndexPath) -> String {
    return messages[(indexPath as NSIndexPath).item].identifier
  }

  func collectionView(_ collectionView: MCollectionView, frameForIndexPath indexPath: IndexPath) -> CGRect {
    var yHeight: CGFloat = 0
    var xOffset: CGFloat = 10
    let message = messages[(indexPath as NSIndexPath).item]
    var cellFrame = MessageTextCell.frameForMessage(messages[(indexPath as NSIndexPath).item], containerWidth: collectionView.frame.width - 2 * xOffset)
    if (indexPath as NSIndexPath).item != 0 {
      let lastMessage = messages[(indexPath as NSIndexPath).item-1]
      let lastFrame = collectionView.frameForIndexPath(IndexPath(item: (indexPath as NSIndexPath).item - 1, section: (indexPath as NSIndexPath).section))!

      let maxWidth = view.bounds.width - 20
      if message.type == .image &&
        lastMessage.type == .image && message.alignment == lastMessage.alignment {
        if message.alignment == .left && lastFrame.maxX + cellFrame.width + 2 < maxWidth {
          yHeight = lastFrame.minY
          xOffset = lastFrame.maxX + 2
        } else if message.alignment == .right && lastFrame.minX - cellFrame.width - 2 > view.bounds.width - maxWidth {
          yHeight = lastFrame.minY
          xOffset = lastFrame.minX - 2 - cellFrame.width
          cellFrame.origin.x = 0
        } else {
          yHeight = lastFrame.maxY + message.verticalPaddingBetweenMessage(lastMessage)
        }
      } else {
        yHeight = lastFrame.maxY + message.verticalPaddingBetweenMessage(lastMessage)
      }
    }
    cellFrame.origin.x += xOffset
    cellFrame.origin.y = yHeight
    return cellFrame
  }

  func collectionView(_ collectionView: MCollectionView, didInsertCellView cellView: UIView, atIndexPath indexPath: IndexPath) {
    let frame = collectionView.frameForIndexPath(indexPath)!
    if sendingMessage && (indexPath as NSIndexPath).item == messages.count - 1 {
      // we just sent this message, lets animate it from inputToolbarView to it's position
      cellView.center = collectionView.contentView.convert(inputToolbarView.center, from: view)
      cellView.bounds = inputToolbarView.bounds
      cellView.alpha = 0
      cellView.m_animate("alpha", to: 1.0, damping: 25)
      cellView.m_animate("bounds", to: frame.bounds, stiffness: 300, damping: 30)
    } else if (collectionView.visibleFrame.intersects(frame)) {
      if messages[(indexPath as NSIndexPath).item].alignment == .left {
        let center = cellView.center
        cellView.center = CGPoint(x: center.x - view.bounds.width, y: center.y)
        cellView.m_animate("center", to: center, stiffness:250, damping: 20)
      } else if messages[(indexPath as NSIndexPath).item].alignment == .right {
        let center = cellView.center
        cellView.center = CGPoint(x: center.x + view.bounds.width, y: center.y)
        cellView.m_animate("center", to: center, stiffness:250, damping: 20)
      } else {
        cellView.alpha = 0
        cellView.m_setValues([0], forCustomProperty: "scale")
        cellView.m_animate("alpha", to: 1, stiffness:250, damping: 25)
        cellView.m_animate("scale", to: 1, stiffness:250, damping: 25)
      }
    }
  }

  func collectionView(_ collectionView: MCollectionView, didDeleteCellView cellView: UIView, atIndexPath indexPath: IndexPath) {
    cellView.m_animate("alpha", to: 0, stiffness:250, damping: 25)
    cellView.m_animate("scale", to: 0, stiffness:250, damping: 25) {
      cellView.removeFromSuperview()
    }
  }
  func collectionView(_ collectionView: MCollectionView, didReloadCellView cellView: UIView, atIndexPath indexPath: IndexPath) {
    if let cellView = cellView as? MessageTextCell, let frame = collectionView.frameForIndexPath(indexPath) {
      cellView.message = messages[(indexPath as NSIndexPath).item]
      if cellView != dragingCell {
        cellView.m_animate("bounds", to:frame.bounds, stiffness: 150, damping:20, threshold: 1)
        cellView.m_animate("center", to:frame.center, stiffness: 150, damping:20, threshold: 1)
        cellView.m_animate("scale", to: 1, stiffness:250, damping: 25)
        cellView.layer.zPosition = CGFloat((indexPath as NSIndexPath).item) * 100
      }
    }
  }

  func collectionView(_ collectionView: MCollectionView, cellView: UIView, didUpdateScreenPositionForIndexPath indexPath: IndexPath, screenPosition: CGPoint) {
    if let dragingCellCenter = dragingCellCenter, cellView == dragingCell {
      cellView.m_animate("center", to:collectionView.contentView.convert(dragingCellCenter, from: view), stiffness: 500, damping: 25)
    }
  }
}

// For sending new messages
extension MessagesViewController: InputToolbarViewDelegate {
  func inputAccessoryViewDidUpdateFrame(_ frame: CGRect) {
    let oldContentInset = collectionView.contentInset
    self.viewDidLayoutSubviews()
    if oldContentInset != collectionView.contentInset {
      collectionView.scroll(to: .bottom)
    }
  }
  func send(_ text: String) {
    messages.append(Message(true, content: text))

    sendingMessage = true
    collectionView.reloadData()
    sendingMessage = false

    collectionView.scroll(to: .bottom)
    delay(1.0) {
      self.messages.append(Message(false, content: text))
      self.collectionView.reloadData()
      self.collectionView.scroll(to: .bottom)
    }
  }
  func inputToolbarViewNeedFrameUpdate() {
    layout(true)
  }
}

// For reordering
extension MessagesViewController: MessageTextCellDelegate {
  func messageCellDidBeginHolding(_ cell: MessageTextCell, gestureRecognizer: UILongPressGestureRecognizer) {
    if dragingCell != nil {
      return
    }
    cell.tilt3D = true
    startingDragLocation = gestureRecognizer.location(in: collectionView) + collectionView.contentOffset
    startingCellCenter = cell.center
    dragingCell = cell
    dragingCellCenter = startingCellCenter
    cell.layer.zPosition = CGFloat(messages.count + 100)*1000

    messageCellDidMoveWhileHolding(cell, gestureRecognizer: gestureRecognizer)
  }
  func messageCellDidMoveWhileHolding(_ cell: MessageTextCell, gestureRecognizer: UILongPressGestureRecognizer) {
    if cell != dragingCell {
      return
    }
    if let index = (collectionView.indexPathOfView(cell) as NSIndexPath?)?.item {
      var center = startingCellCenter!
      let newLocation = gestureRecognizer.location(in: collectionView) + collectionView.contentOffset
      center = center + newLocation - startingDragLocation!
      var velocity = CGPoint.zero
      dragingCellCenter = view.convert(center, from:collectionView.contentView)
      let fingerPosition = gestureRecognizer.location(in: view)
      if fingerPosition.y < 80 && collectionView.contentOffset.y > 0 {
        velocity.y = -(80 - fingerPosition.y) * 30
      } else if fingerPosition.y > view.bounds.height - 80 &&
        collectionView.contentOffset.y < collectionView.offsetAt(.bottom) {
        velocity.y = (fingerPosition.y - (view.bounds.height - 80)) * 30
      } else if let toIndex = (collectionView.indexPathForItemAtPoint(center) as NSIndexPath?)?.item, toIndex != index && canReorder {
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
  func messageCellDidEndHolding(_ cell: MessageTextCell, gestureRecognizer: UILongPressGestureRecognizer) {
    if cell != dragingCell {
      return
    }
    if let index = (collectionView.indexPathOfView(cell) as NSIndexPath?)?.item {
      // one last check if we need to move
      var center = startingCellCenter!
      let newLocation = gestureRecognizer.location(in: collectionView) + collectionView.contentOffset
      center = center + newLocation - startingDragLocation!
      if let toIndex = (collectionView.indexPathForItemAtPoint(center) as NSIndexPath?)?.item, toIndex != index && canReorder {
        canReorder = false
        delay(0.5) {
          self.canReorder = true
        }
        moveMessageAtIndex(index, toIndex: toIndex)
        center = collectionView.frameForIndexPath(IndexPath(item: toIndex, section: 0))!.center
      } else {
        center = collectionView.frameForIndexPath(IndexPath(item: index, section: 0))!.center
      }
      dragingCellCenter = nil
      dragingCell = nil
      cell.tilt3D = false
      cell.layer.zPosition = CGFloat(index)*1000
      cell.m_animate("center", to:center, stiffness: 150, damping: 15)
    }
  }

  func messageCellDidTap(_ cell: MessageTextCell) {

  }

  func moveMessageAtIndex(_ index: Int, toIndex: Int) {
    if index == toIndex {
      return
    }
    let m = messages.remove(at: index)
    messages.insert(m, at: toIndex)
    collectionView.reloadData()
  }
}

extension MessagesViewController: MScrollViewDelegate {
  func scrollViewScrolled(_ scrollView: MScrollView) {
    // dismiss keyboard
    if inputToolbarView.textView.isFirstResponder {
      if scrollView.draging && scrollView.panGestureRecognizer.velocity(in: scrollView).y > 100 {
        inputToolbarView.textView.resignFirstResponder()
      }
    }

    // PULL TO LOAD MORE
    // load more messages if we scrolled to the top
    if scrollView.contentOffset.y < 400 && loading == false {
      loading = true
      delay(0.5) { // Simulate network request
        var newMessage: [Message] = []
        for i in TestMessages {
          newMessage.append(i.copy())
        }
        let currentOffsetDiff = self.collectionView.frames[0][0].minY - self.collectionView.contentOffset.y
        self.messages = newMessage + self.messages
        print("load new messages count:\(self.messages.count)")
        self.collectionView.reloadData {
          let offset = self.collectionView.frames[0][newMessage.count].minY - currentOffsetDiff
          self.collectionView.contentOffset.y = offset
        }
        self.loading = false
      }
    }
    inputToolbarView.showShadow = scrollView.contentOffset.y < scrollView.offsetAt(.bottom) - 10 || inputToolbarView.textView.isFirstResponder
  }
}
