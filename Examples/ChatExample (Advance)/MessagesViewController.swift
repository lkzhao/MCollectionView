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
    collectionView.wabble = true
    collectionView.autoRemoveCells = false
    collectionView.delegate = self
    view.addSubview(collectionView)

    inputToolbarView.delegate = self
    view.addSubview(inputToolbarView)
    inputToolbarView.layer.zPosition = 2000
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
  }

  func layout(animate: Bool = true) {
    let inputPadding: CGFloat = 10
    collectionView.frame = view.bounds
    let inputSize = inputToolbarView.sizeThatFits(CGSize(width: view.bounds.width - 2 * inputPadding, height: view.bounds.height))
    let inputToolbarFrame = CGRect(x: inputPadding, y: keyboardHeight - inputSize.height - inputPadding, width: view.bounds.width - 2*inputPadding, height: inputSize.height)
    if animate {
      inputToolbarView.yaal_center.animateTo(inputToolbarFrame.center, stiffness: 300, damping: 25)
      inputToolbarView.yaal_bounds.animateTo(inputToolbarFrame.bounds, stiffness: 300, damping: 25)
    } else {
      inputToolbarView.bounds = inputToolbarFrame.bounds
      inputToolbarView.center = inputToolbarFrame.center
    }
    collectionView.contentInset = UIEdgeInsetsMake(topLayoutGuide.length + 30,
                                                   10,
                                                   view.bounds.height - inputToolbarFrame.minY + 20,
                                                   10)
    if !collectionView.hasReloaded {
      collectionView.reloadData() {
        return CGPoint(x: self.collectionView.contentOffset.x,
                       y: self.collectionView.offsetFrame.maxY)
      }
    }
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    layout(animate: collectionView.hasReloaded)
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
    guard collectionView.hasReloaded else { return }
    let frame = collectionView.frameForCell(at: indexPath)!
    if sendingMessage && indexPath.item == messages.count - 1 {
      // we just sent this message, lets animate it from inputToolbarView to it's position
      cellView.center = collectionView.convert(inputToolbarView.center, from: view)
      cellView.bounds = inputToolbarView.bounds
      cellView.alpha = 0
      cellView.yaal_alpha.animateTo(1.0)
      cellView.yaal_bounds.animateTo(frame.bounds, stiffness: 400, damping: 40)
    } else if (collectionView.visibleFrame.intersects(frame)) {
      if messages[indexPath.item].alignment == .left {
        let center = cellView.center
        cellView.center = CGPoint(x: center.x - view.bounds.width, y: center.y)
        cellView.yaal_center.animateTo(center, stiffness:250, damping: 20)
      } else if messages[indexPath.item].alignment == .right {
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

  func collectionView(_ collectionView: MCollectionView, didDeleteCellView cellView: UIView, atIndexPath indexPath: IndexPath) {
    cellView.yaal_alpha.animateTo(0)
    cellView.yaal_scale.animateTo(0) { finished in
      cellView.removeFromSuperview()
    }
  }

  func collectionView(_ collectionView: MCollectionView, didReloadCellView cellView: UIView, atIndexPath indexPath: IndexPath) {
    if let cellView = cellView as? MessageTextCell, let frame = collectionView.frameForCell(at: indexPath) {
      cellView.message = messages[indexPath.item]
      if !collectionView.isFloating(cell: cellView) {
        cellView.yaal_bounds.animateTo(frame.bounds, stiffness: 150, damping:20, threshold: 1)
        cellView.yaal_center.animateTo(frame.center, stiffness: 150, damping:20, threshold: 1)
        cellView.yaal_scale.animateTo(1)
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
      cell.yaal_scale.animateTo(1.1)
      cell.yaal_rotationX.animateTo(0, stiffness: 150, damping: 20)
      cell.yaal_rotationY.animateTo(0, stiffness: 150, damping: 20)
      cell.layer.yaal_zPosition.animateTo(CGFloat(messages.count) * 100, stiffness: 150, damping: 20)
    }
    return true
  }

  func collectionView(_ collectionView: MCollectionView, didDrag cell: UIView, at indexPath: IndexPath) {
    if let cell = cell as? MCell {
      cell.tilt3D = false
      cell.tapAnimation = true
      cell.yaal_scale.animateTo(1)
      cell.layer.yaal_zPosition.animateTo( CGFloat(indexPath.item) * 100, stiffness: 150, damping: 20)
    }
  }
}

// For sending new messages
extension MessagesViewController: InputToolbarViewDelegate {
  func inputAccessoryViewDidUpdateFrame(_ frame: CGRect) {
    inputToolbarView.showShadow = collectionView.contentOffset.y < collectionView.offsetFrame.maxY - 10 || inputToolbarView.textView.isFirstResponder
    viewDidLayoutSubviews()
    collectionView.yaal_contentOffset.animateTo(CGPoint(x: collectionView.contentOffset.x,
                                                        y: collectionView.offsetFrame.maxY))
  }
  func send(_ text: String) {
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
  func inputToolbarViewNeedFrameUpdate() {
    layout(animate: true)
  }
}

extension MessagesViewController: UIScrollViewDelegate {
  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    inputToolbarView.showShadow = collectionView.contentOffset.y < collectionView.offsetFrame.maxY - 10 || inputToolbarView.textView.isFirstResponder

    // PULL TO LOAD MORE
    // load more messages if we scrolled to the top
    if collectionView.hasReloaded,
      scrollView.contentOffset.y < 400,
      !loading {
      loading = true
      delay(0.5) { // Simulate network request
        self.messages = TestMessages.map{ $0.copy() } + self.messages
        print("load new messages count:\(self.messages.count)")
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
