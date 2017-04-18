//
//  MessagesViewController.swift
//  MCollectionViewExample
//
//  Created by YiLun Zhao on 2016-02-12.
//  Copyright © 2016 lkzhao. All rights reserved.
//

import UIKit
import MCollectionView
import ALTextInputBar

class MessagesViewController: UIViewController {

  var collectionView: MCollectionView!

  var sendingMessage = false
  var messages: [Message] = TestMessages
  var loading = false

  let textInputBar = ALTextInputBar()
  let keyboardObserver = ALKeyboardObservingView()

  override var inputAccessoryView: UIView? {
    return keyboardObserver
  }

  override var canBecomeFirstResponder: Bool {
    return true
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = UIColor(white: 0.97, alpha: 1.0)
    view.clipsToBounds = true
    collectionView = MCollectionView(frame:view.bounds)
    collectionView.collectionDelegate = self
    collectionView.wabble = true
    collectionView.autoRemoveCells = false
    collectionView.delegate = self
    collectionView.keyboardDismissMode = .interactive
    view.addSubview(collectionView)

    let button = UIButton(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
    button.setImage(UIImage(named:"ic_send")!, for: .normal)
    button.addTarget(self, action: #selector(send), for: .touchUpInside)
    button.sizeToFit()
    button.tintColor = .lightBlue
    textInputBar.rightView = button
    textInputBar.textView.tintColor = .lightBlue
    textInputBar.defaultHeight = 54
    textInputBar.delegate = self
    textInputBar.keyboardObserver = keyboardObserver
    textInputBar.frame = CGRect(x: 0, y: view.frame.height - textInputBar.defaultHeight, width: view.frame.width, height: textInputBar.defaultHeight)
    keyboardObserver.isUserInteractionEnabled = false
    view.addSubview(textInputBar)
    NotificationCenter.default.addObserver(self, selector: #selector(keyboardFrameChanged(notification:)), name: NSNotification.Name(rawValue: ALKeyboardFrameDidChangeNotification), object: nil)
  }

  func keyboardFrameChanged(notification: NSNotification) {
    if let userInfo = notification.userInfo {
      let frame = userInfo[UIKeyboardFrameEndUserInfoKey] as! CGRect
      textInputBar.frame.origin.y = frame.minY
      viewDidLayoutSubviews()
    }
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    textInputBar.frame.size.width = view.bounds.width
    let isAtBottom = collectionView.contentOffset.y >= collectionView.offsetFrame.maxY - 10
    collectionView.frame = view.bounds
    collectionView.contentInset = UIEdgeInsetsMake(topLayoutGuide.length + 30,
                                                   10,
                                                   max(textInputBar.defaultHeight, view.bounds.height - textInputBar.frame.minY) + 20,
                                                   10)
    collectionView.scrollIndicatorInsets = UIEdgeInsetsMake(topLayoutGuide.length, 0, max(textInputBar.defaultHeight, view.bounds.height - textInputBar.frame.minY), 0)
    if !collectionView.hasReloaded {
      collectionView.reloadData() {
        return CGPoint(x: self.collectionView.contentOffset.x,
                       y: self.collectionView.offsetFrame.maxY)
      }
    }
    if isAtBottom {
      if collectionView.hasReloaded {
        collectionView.yaal_contentOffset.animateTo(CGPoint(x: collectionView.contentOffset.x,
                                                            y: collectionView.offsetFrame.maxY))
      } else {
        collectionView.yaal_contentOffset.setTo(CGPoint(x: collectionView.contentOffset.x,
                                                        y: collectionView.offsetFrame.maxY))
      }
    }
  }
}

// collectionview datasource and layout
extension MessagesViewController: MCollectionViewDelegate {
  func numberOfItemsInCollectionView(_ collectionView: MCollectionView) -> Int {
    return messages.count
  }

  func collectionView(_ collectionView: MCollectionView, viewForIndex index: Int) -> UIView {
    let v = collectionView.dequeueReusableView(MessageCell.self) ?? MessageCell()
    v.message = messages[index]
    return v
  }

  func collectionView(_ collectionView: MCollectionView, identifierForIndex index: Int) -> String {
    return messages[index].identifier
  }

  func collectionView(_ collectionView: MCollectionView, frameForIndex index: Int) -> CGRect {
    var yHeight: CGFloat = 0
    var xOffset: CGFloat = 0
    let maxWidth = view.bounds.width - 20
    let message = messages[index]
    var cellFrame = MessageCell.frameForMessage(messages[index], containerWidth: maxWidth)
    if index != 0 {
      let lastMessage = messages[index-1]
      let lastFrame = collectionView.frameForCell(at: index - 1)!

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

  func collectionView(_ collectionView: MCollectionView, didInsertCellView cellView: UIView, atIndex index: Int) {
    guard collectionView.hasReloaded else { return }
    let frame = collectionView.frameForCell(at: index)!
    if sendingMessage && index == messages.count - 1 {
      // we just sent this message, lets animate it from inputToolbarView to it's position
      cellView.frame = collectionView.convert(textInputBar.bounds, from: textInputBar)
      cellView.alpha = 0
      cellView.yaal_alpha.animateTo(1.0)
      cellView.yaal_bounds.animateTo(frame.bounds, stiffness: 400, damping: 40)
    } else if (collectionView.visibleFrame.intersects(frame)) {
      if messages[index].alignment == .left {
        let center = cellView.center
        cellView.center = CGPoint(x: center.x - view.bounds.width, y: center.y)
        cellView.yaal_center.animateTo(center, stiffness:250, damping: 20)
      } else if messages[index].alignment == .right {
        let center = cellView.center
        cellView.center = CGPoint(x: center.x + view.bounds.width, y: center.y)
        cellView.yaal_center.animateTo(center, stiffness:250, damping: 20)
      } else {
        cellView.alpha = 0
        cellView.yaal_scale.from(0).animateTo(1)
        cellView.yaal_alpha.animateTo(1)
      }
    }
  }

  func collectionView(_ collectionView: MCollectionView, didDeleteCellView cellView: UIView, atIndex index: Int) {
    cellView.yaal_alpha.animateTo(0)
    cellView.yaal_scale.animateTo(0) { finished in
      cellView.removeFromSuperview()
    }
  }

  func collectionView(_ collectionView: MCollectionView, didReloadCellView cellView: UIView, atIndex index: Int) {
    if let cellView = cellView as? MessageCell, let frame = collectionView.frameForCell(at: index) {
      cellView.message = messages[index]
      if !collectionView.isFloating(cell: cellView) {
        cellView.yaal_bounds.animateTo(frame.bounds, stiffness: 150, damping:20, threshold: 1)
        cellView.yaal_center.animateTo(frame.center, stiffness: 150, damping:20, threshold: 1)
        cellView.yaal_scale.animateTo(1)
      }
    }
  }

  func collectionView(_ collectionView: MCollectionView, moveItemAt index: Int, to: Int) -> Bool {
    messages.insert(messages.remove(at: index), at: to)
    return true
  }

  func collectionView(_ collectionView: MCollectionView, willDrag cell: UIView, at index: Int) -> Bool {
    if let cell = cell as? DynamicView {
      cell.tiltAnimation = true
      cell.tapAnimation = false
      cell.yaal_scale.animateTo(1.1)
      cell.yaal_rotationX.animateTo(0, stiffness: 150, damping: 20)
      cell.yaal_rotationY.animateTo(0, stiffness: 150, damping: 20)
      cell.layer.yaal_zPosition.animateTo(100, damping: 30)
    }
    return true
  }

  func collectionView(_ collectionView: MCollectionView, didDrag cell: UIView, at index: Int) {
    if let cell = cell as? DynamicView {
      cell.tiltAnimation = false
      cell.tapAnimation = true
      cell.yaal_scale.animateTo(1)
      cell.layer.yaal_zPosition.animateTo(0, damping: 30)
    }
  }
}

// For sending new messages
extension MessagesViewController: ALTextInputBarDelegate {
  func send() {
    let text = textInputBar.text!
    textInputBar.text = ""
    messages.append(Message(true, content: text))

    sendingMessage = true
    collectionView.reloadData()
    collectionView.scrollTo(edge: .bottom, animated:true)
    sendingMessage = false

    delay(1.0) {
      self.messages.append(Message(false, content: text))
      self.collectionView.reloadData()
      self.collectionView.scrollTo(edge: .bottom, animated:true)
    }
  }
}

extension MessagesViewController: UIScrollViewDelegate {
  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    // PULL TO LOAD MORE
    // load more messages if we scrolled to the top
    if collectionView.hasReloaded,
      scrollView.contentOffset.y < 500,
      !loading {
      loading = true
      delay(0.5) { // Simulate network request
        let newMessages = TestMessages.map{ $0.copy() }
        self.messages = newMessages + self.messages
        let bottomOffset = self.collectionView.offsetFrame.maxY - self.collectionView.contentOffset.y
        self.collectionView.reloadData() {
          return CGPoint(x: self.collectionView.contentOffset.x,
                         y: self.collectionView.offsetFrame.maxY - bottomOffset)
        }
        self.loading = false
      }
    }
  }
}
