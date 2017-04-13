//
//  MoveManager.swift
//  MCollectionView
//
//  Created by Luke on 3/20/17.
//  Copyright © 2017 lkzhao. All rights reserved.
//

import UIKit

class MoveContext: NSObject {
  var gesture: UILongPressGestureRecognizer
  var cell: UIView
  var collectionView: MCollectionView

  var startingLocationDiffInCell: CGPoint
  var canReorder = true

  init(gesture: UILongPressGestureRecognizer, cell: UIView, in collectionView: MCollectionView) {
    self.gesture = gesture
    self.cell = cell
    self.collectionView = collectionView
    startingLocationDiffInCell = gesture.location(in: cell.superview) - cell.center
    super.init()

    gesture.addTarget(self, action: #selector(handleLongPress(gestureRecognizer:)))
  }

  func handleLongPress(gestureRecognizer: UILongPressGestureRecognizer) {
    guard gestureRecognizer == gesture, gesture.state == .changed else { return }

    if let index = collectionView.indexPath(for: cell) {
      let location = gestureRecognizer.location(in: collectionView)
      cell.yaal_center.animateTo(location - startingLocationDiffInCell, stiffness: 1000, damping: 30)

      var scrollVelocity = CGPoint.zero
      if location.y < collectionView.contentInset.top + 80 && collectionView.contentOffset.y > collectionView.offsetAt(.top) {
        scrollVelocity.y = -(collectionView.contentInset.top + 80 - location.y) * 30
      } else if location.y > collectionView.bounds.height - collectionView.contentInset.bottom - 80 ,
        collectionView.contentOffset.y < collectionView.offsetAt(.bottom) {
        scrollVelocity.y = (location.y - (collectionView.bounds.height - collectionView.contentInset.bottom - 80)) * 30
      }

      if location.x < collectionView.contentInset.left + 80 && collectionView.contentOffset.x > collectionView.offsetAt(.left) {
        scrollVelocity.x = -(collectionView.contentInset.left + 80 - location.x) * 30
      } else if location.x > collectionView.bounds.width - collectionView.contentInset.right - 80 ,
        collectionView.contentOffset.x < collectionView.offsetAt(.right) {
        scrollVelocity.x = (location.x - (collectionView.bounds.width - collectionView.contentInset.right - 80)) * 30
      }

      if scrollVelocity != .zero {
        collectionView.scroll(with: scrollVelocity)
      } else if canReorder,
        !collectionView.isDraging,
        let toIndex = collectionView.indexPathForCell(at: gestureRecognizer.location(in: collectionView.contentView)),
        toIndex != index,
        collectionView.collectionDelegate?.collectionView?(collectionView, moveItemAt: index, to: toIndex) == true
      {
        canReorder = false
        delay(0.1) {
          self.canReorder = true
        }
        collectionView.reloadData()
      }
    }
  }
}

class MoveManager: NSObject {
  weak var collectionView: MCollectionView? {
    didSet {
      addNextLongPressGesture()
    }
  }

  var contexts: [UILongPressGestureRecognizer: MoveContext] = [:]

  func addNextLongPressGesture() {
    if let collectionView = collectionView {
      let nextLongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(gestureRecognizer:)))
      nextLongPressGestureRecognizer.delegate = self
      nextLongPressGestureRecognizer.minimumPressDuration = 0.5
      collectionView.addGestureRecognizer(nextLongPressGestureRecognizer)
    }
  }

  func handleLongPress(gestureRecognizer: UILongPressGestureRecognizer) {
    guard let collectionView = collectionView else { return }
    switch gestureRecognizer.state {
    case .began:
      if let indexPath = collectionView.indexPathForCell(at: gestureRecognizer.location(in: collectionView.contentView)),
        let cell = collectionView.cell(at: indexPath),
        !collectionView.isFloating(cell: cell),
        collectionView.collectionDelegate?.collectionView?(collectionView, willDrag: cell, at: indexPath) == true {
        collectionView.panGestureRecognizer.isEnabled = false
        collectionView.panGestureRecognizer.isEnabled = true
        collectionView.float(cell: cell)
        contexts[gestureRecognizer] = MoveContext(gesture: gestureRecognizer, cell: cell, in: collectionView)
      } else {
        gestureRecognizer.isEnabled = false
        gestureRecognizer.isEnabled = true
      }
      break
    case .changed:
      break
    default:
      gestureRecognizer.view?.removeGestureRecognizer(gestureRecognizer)
      if let moveContext = contexts[gestureRecognizer] {
        contexts[gestureRecognizer] = nil
        let cell = moveContext.cell
        if let index = collectionView.indexPath(for: cell), collectionView.isFloating(cell: cell) {
          collectionView.unfloat(cell: cell)
          collectionView.collectionDelegate?.collectionView?(collectionView, didDrag: cell, at: index)
        }
      }
      break
    }
  }
}

extension MoveManager: UIGestureRecognizerDelegate {
  func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    addNextLongPressGesture()
    return true
  }

  func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
    return otherGestureRecognizer.delegate === self || otherGestureRecognizer is ImmediatePanGestureRecognizer
  }
}
