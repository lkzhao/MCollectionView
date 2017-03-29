//
//  File.swift
//  MCollectionView
//
//  Created by Luke on 3/27/17.
//  Copyright © 2017 lkzhao. All rights reserved.
//

import UIKit
import pop
import Animate

internal let animator:SpringAnimator = AnimateSpringAnimator()

protocol SpringAnimator {
  func animate(view:UIView, target: CGPoint)
  func stop(view:UIView)
}

class UIKitDynamicAnimator: SpringAnimator {
  let animator = UIDynamicAnimator()
  let resistanceBehavior = UIDynamicItemBehavior(items: [])

  var attachments:[UIView: UIAttachmentBehavior] = [:]

  init() {
    resistanceBehavior.resistance = 30.0
    resistanceBehavior.elasticity = 0
    animator.addBehavior(resistanceBehavior)
  }

  func animate(view:UIView, target: CGPoint) {
    if let attachment = attachments[view] {
      attachment.anchorPoint = target
    } else {
      let attachment = UIAttachmentBehavior(item: view, attachedToAnchor: target)
      attachments[view] = attachment
      attachment.frequency = 5
      attachment.damping = 1
      attachment.length = 0
      animator.addBehavior(attachment)

      resistanceBehavior.addItem(view)
    }
  }

  func stop(view:UIView) {
    if let attachment = attachments[view] {
      animator.removeBehavior(attachment)
      attachments[view] = nil
      resistanceBehavior.removeItem(view)
    }
  }
}

class AnimateSpringAnimator: SpringAnimator {
  func animate(view:UIView, target: CGPoint) {
    view.animate.center.to(target, stiffness:150, damping:20, threshold:1)
  }

  func stop(view:UIView) {
    view.animate.center.stop()
  }
}

class PopSpringAnimator: SpringAnimator {
  func animate(view:UIView, target: CGPoint) {
    if let springAnim = view.pop_animation(forKey: "center") as? POPSpringAnimation {
      springAnim.toValue = NSValue(cgPoint: target)
    } else {
      let springAnim = POPSpringAnimation(propertyNamed: kPOPViewCenter)!
      springAnim.toValue = NSValue(cgPoint: target)
      springAnim.springBounciness = 0
      view.pop_add(springAnim, forKey: "center")
    }
  }

  func stop(view:UIView) {
    view.pop_removeAnimation(forKey: "center")
  }
}
