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
      let location = gestureRecognizer.location(in: nil)
      cell.m_animate("center", to:location - startingLocationDiffInCell, stiffness: 500, damping: 25)

      var scrollVelocity = CGPoint.zero
      if location.y < 80 && collectionView.contentOffset.y > 0 {
        scrollVelocity.y = -(80 - location.y) * 30
      } else if location.y > collectionView.bounds.height - 80 &&
        collectionView.contentOffset.y < collectionView.offsetAt(.bottom) {
        scrollVelocity.y = (location.y - (collectionView.bounds.height - 80)) * 30
      } else if let toIndex = collectionView.indexPathForCell(at: gestureRecognizer.location(in: collectionView.contentView)),
        toIndex != index,
        canReorder,
        collectionView.collectionDelegate?.collectionView?(collectionView, moveItemAt: index, to: toIndex) == true {
        canReorder = false
        delay(0.1) {
          self.canReorder = true
        }
        collectionView.reloadData()
      }
      collectionView.scroll(with: scrollVelocity)
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
      collectionView.panGestureRecognizer.require(toFail: nextLongPressGestureRecognizer)
    }
  }

  func handleLongPress(gestureRecognizer: UILongPressGestureRecognizer) {
    guard let collectionView = collectionView else { return }
    switch gestureRecognizer.state {
    case .began:
      if let indexPath = collectionView.indexPathForCell(at: gestureRecognizer.location(in: collectionView.contentView)),
        let cell = collectionView.cell(at: indexPath),
        !collectionView.isFloating(cell: cell),
        collectionView.collectionDelegate?.collectionView?(collectionView, canMoveItemAt: indexPath) == true {
        collectionView.float(cell: cell)
        contexts[gestureRecognizer] = MoveContext(gesture: gestureRecognizer, cell: cell, in: collectionView)
      }
      break
    case .changed:
      break
    default:
      gestureRecognizer.view?.removeGestureRecognizer(gestureRecognizer)
      if let moveContext = contexts[gestureRecognizer] {
        collectionView.unfloat(cell: moveContext.cell)
        contexts[gestureRecognizer] = nil
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
    return otherGestureRecognizer.delegate === self
  }
}