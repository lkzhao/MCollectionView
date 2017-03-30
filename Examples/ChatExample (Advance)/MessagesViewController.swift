//
//  MessagesViewController.swift
//  MCollectionViewExample
//
//  Created by YiLun Zhao on 2016-02-12.
//  Copyright © 2016 lkzhao. All rights reserved.
//

import UIKit
import MCollectionView

class MessagesViewController: UIViewController {

  var collectionView: MCollectionView!
  let inputToolbarView = InputToolbarView()

  var sendingMessage = false
  var messages: [Message] = TestMessages
  var loading = false

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
    collectionView.autoRemoveCells = false
    collectionView.anchorPoint = .bottomRight
    view.addSubview(collectionView)

    inputToolbarView.delegate = self
    view.addSubview(inputToolbarView)
    inputToolbarView.layer.zPosition = 2000
  }

  func layout(_ animate: Bool = true) {
    collectionView.frame = view.bounds
    let inputPadding: CGFloat = 10
    let inputSize = inputToolbarView.sizeThatFits(CGSize(width: view.bounds.width - 2 * inputPadding, height: view.bounds.height))
    let inputToolbarFrame = CGRect(x: inputPadding, y: keyboardHeight - inputSize.height - inputPadding, width: view.bounds.width - 2*inputPadding, height: inputSize.height)
    if animate {
      inputToolbarView.animate.center.to(inputToolbarFrame.center, stiffness: 300, damping: 25)
      inputToolbarView.animate.bounds.to(inputToolbarFrame.bounds, stiffness: 300, damping: 25)
    } else {
      inputToolbarView.bounds = inputToolbarFrame.bounds
      inputToolbarView.center = inputToolbarFrame.center
    }
    collectionView.setContentInset(UIEdgeInsetsMake(topLayoutGuide.length + 30,
                                                    10,
                                                    view.bounds.height - inputToolbarFrame.minY + 20,
                                                    10),
                                   animate: animate)
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    layout(!collectionView.isInitialReload)
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
    v.message = messages[indexPath.item]
    v.center = initialFrame.center
    v.bounds = initialFrame.bounds
    v.layer.zPosition = CGFloat(indexPath.item) * 100
    return v
  }

  func collectionView(_ collectionView: MCollectionView, identifierForIndexPath indexPath: IndexPath) -> String {
    return messages[indexPath.item].identifier
  }

  func collectionView(_ collectionView: MCollectionView, frameForIndexPath indexPath: IndexPath) -> CGRect {
    var yHeight: CGFloat = 0
    var xOffset: CGFloat = 0
    let maxWidth = view.bounds.width - 20
    let message = messages[indexPath.item]
    var cellFrame = MessageTextCell.frameForMessage(messages[indexPath.item], containerWidth: maxWidth)
    if indexPath.item != 0 {
      let lastMessage = messages[indexPath.item-1]
      let lastFrame = collectionView.frameForCell(at: IndexPath(item: indexPath.item - 1, section: indexPath.section))!

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
    guard !collectionView.isInitialReload else { return }
    let frame = collectionView.frameForCell(at: indexPath)!
    if sendingMessage && indexPath.item == messages.count - 1 {
      // we just sent this message, lets animate it from inputToolbarView to it's position
      cellView.center = collectionView.contentView.convert(inputToolbarView.center, from: view)
      cellView.bounds = inputToolbarView.bounds
      cellView.alpha = 0
      cellView.animate.alpha.to(1.0)
      cellView.animate.bounds.to(frame.bounds, stiffness: 300, damping: 30)
    } else if (collectionView.visibleFrame.intersects(frame)) {
      if messages[indexPath.item].alignment == .left {
        let center = cellView.center
        cellView.center = CGPoint(x: center.x - view.bounds.width, y: center.y)
        cellView.animate.center.to(center, stiffness:250, damping: 20)
      } else if messages[indexPath.item].alignment == .right {
        let center = cellView.center
        cellView.center = CGPoint(x: center.x + view.bounds.width, y: center.y)
        cellView.animate.center.to(center, stiffness:250, damping: 20)
      } else {
        cellView.alpha = 0
        cellView.animate.scale.from(0).to(1)
        cellView.animate.alpha.to(1)
      }
    }
  }

  func collectionView(_ collectionView: MCollectionView, didDeleteCellView cellView: UIView, atIndexPath indexPath: IndexPath) {
    cellView.animate.alpha.to(0)
    cellView.animate.scale.to(0) { finished in
      cellView.removeFromSuperview()
    }
  }

  func collectionView(_ collectionView: MCollectionView, didReloadCellView cellView: UIView, atIndexPath indexPath: IndexPath) {
    if let cellView = cellView as? MessageTextCell, let frame = collectionView.frameForCell(at: indexPath) {
      cellView.message = messages[indexPath.item]
      if !collectionView.isFloating(cell: cellView) {
        cellView.animate.bounds.to(frame.bounds, stiffness: 150, damping:20, threshold: 1)
        cellView.animate.center.to(frame.center, stiffness: 150, damping:20, threshold: 1)
        cellView.animate.scale.to(1)
        cellView.layer.zPosition = CGFloat(indexPath.item) * 100
      }
    }
  }

  func collectionView(_ collectionView: MCollectionView, moveItemAt indexPath: IndexPath, to: IndexPath) -> Bool {
    messages.insert(messages.remove(at: indexPath.item), at: to.item)
    return true
  }

  func collectionView(_ collectionView: MCollectionView, willDrag cell: UIView, at indexPath: IndexPath) -> Bool {
    if let cell = cell as? MCell {
      cell.tilt3D = true
      cell.tapAnimation = false
      cell.animate.scale.to(1.1)
      cell.animate.rotationX.to(0, stiffness: 150, damping: 20)
      cell.animate.rotationY.to(0, stiffness: 150, damping: 20)
      cell.animate.zPosition.to(CGFloat(messages.count) * 100, stiffness: 150, damping: 20)
    }
    return true
  }

  func collectionView(_ collectionView: MCollectionView, didDrag cell: UIView, at indexPath: IndexPath) {
    if let cell = cell as? MCell {
      cell.tilt3D = false
      cell.tapAnimation = true
      cell.animate.scale.to(1)
      cell.animate.zPosition.to( CGFloat(indexPath.item) * 100, stiffness: 150, damping: 20)
    }
  }
}

// For sending new messages
extension MessagesViewController: InputToolbarViewDelegate {
  func inputAccessoryViewDidUpdateFrame(_ frame: CGRect) {
    self.viewDidLayoutSubviews()
  }
  func send(_ text: String) {
    messages.append(Message(true, content: text))

    sendingMessage = true
    collectionView.reloadData()
    collectionView.scroll(to: .bottom)
    sendingMessage = false

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

extension MessagesViewController: MScrollViewDelegate {
  func scrollViewScrolled(_ scrollView: MScrollView) {
    // dismiss keyboard
    if inputToolbarView.textView.isFirstResponder,
      scrollView.isDraging,
      scrollView.panGestureRecognizer.velocity(in: nil).y > 100
    {
      inputToolbarView.textView.resignFirstResponder()
    }
    inputToolbarView.showShadow = scrollView.contentOffset.y < scrollView.offsetAt(.bottom) - 10 || inputToolbarView.textView.isFirstResponder

    // PULL TO LOAD MORE
    // load more messages if we scrolled to the top
    if scrollView.contentOffset.y < 400 && loading == false {
      loading = true
      delay(0.5) { // Simulate network request
        self.messages = TestMessages.map{ $0.copy() } + self.messages
        print("load new messages count:\(self.messages.count)")
        self.collectionView.reloadData()
        self.loading = false
      }
    }
  }
}
