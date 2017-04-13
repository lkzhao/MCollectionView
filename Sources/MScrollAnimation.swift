//
//  MScrollAnimation.swift
//  MCollectionViewExample
//
//  Created by Luke on 3/18/17.
//  Copyright © 2017 lkzhao. All rights reserved.
//

import UIKit
import Animate

class MScrollAnimation: Animation {
  weak var scrollView: MScrollView?
  init(scrollView: MScrollView) {
    self.scrollView = scrollView
    super.init()
  }

  var targetOffsetX: CGFloat?
  var targetOffsetY: CGFloat?
  var velocity = CGPoint.zero
  var damping: CGPoint = CGPoint(x: 3, y: 3)
  var threshold: CGFloat = 0.1
  var stiffness: CGPoint = CGPoint(x: 50, y: 50)

  func animateDone() {
    guard let scrollView = scrollView else { return }
    targetOffsetX = nil
    targetOffsetY = nil
    // default value
    stiffness = CGPoint(x: 50, y: 50)
    damping = CGPoint(x: 3, y: 3)

    if let yTarget = scrollView.yEdgeTarget() {
      // initially out of bound
      targetOffsetY = yTarget
      stiffness.y = 100
      damping.y = 20
    } else if scrollView.paged && scrollView.verticalScroll {
      let height = scrollView.bounds.height
      let velocityFactor: CGFloat = (scrollView.scrollVelocity.y/5).clamp(-height/2, height/2)
      let page = Int((scrollView.contentOffset.y + height/2 + velocityFactor) / height)
      let finalOffsetY = CGFloat(page) * height
      if finalOffsetY >= scrollView.contentFrame.minY && finalOffsetY <= scrollView.contentFrame.maxY {
        if scrollView.pageIndexBeforeDrag != page {
          scrollView.scrollDelegate?.scrollView?(scrollView, willSwitchFromPage:scrollView.pageIndexBeforeDrag, toPage:page)
        }
        targetOffsetY = finalOffsetY
        stiffness.y = 100
        damping.y = 20
      }
    }

    if let xTarget = scrollView.xEdgeTarget() {
      targetOffsetX = xTarget
      stiffness.x = 100
      damping.x = 20
    } else if scrollView.paged && scrollView.horizontalScroll {
      let width = scrollView.bounds.width
      let velocityFactor: CGFloat = (scrollView.scrollVelocity.x/5).clamp(-width/2, width/2)
      let page = Int((scrollView.contentOffset.x + width/2 + velocityFactor) / width)
      let finalOffsetX = CGFloat(page) * width
      if finalOffsetX >= scrollView.contentFrame.minX && finalOffsetX <= scrollView.contentFrame.maxX {
        if scrollView.pageIndexBeforeDrag != page {
          scrollView.scrollDelegate?.scrollView?(scrollView, willSwitchFromPage:scrollView.pageIndexBeforeDrag, toPage:page)
        }
        targetOffsetX = finalOffsetX
        stiffness.x = 100
        damping.x = 20
      }
    }

    start()
  }

  func animateToTargetOffset(_ target: CGPoint, stiffness: CGFloat = 1000, damping: CGFloat = 30) {
    targetOffsetY = target.y
    targetOffsetX = target.x

    // default value
    self.stiffness = CGPoint(x: stiffness, y: stiffness)
    self.damping = CGPoint(x: damping, y: damping)

    start()
  }

  override func willStart() {
    super.willStart()
    scrollView?.willStartScroll()
  }

  override func didEnd(finished: Bool) {
    super.didEnd(finished: finished)
    scrollView?.didEndScroll()
  }

  override func didUpdate() {
    super.didUpdate()
    scrollView?.didScroll()
  }

  override func update(dt: TimeInterval) {
    guard let scrollView = scrollView else { return }
    let offset = scrollView.contentOffset
    let yTarget = scrollView.yEdgeTarget()
    let xTarget = scrollView.xEdgeTarget()
    let bounces = scrollView.bounces

    // Force
    var targetOffset = CGPoint(x: targetOffsetX ?? offset.x, y: targetOffsetY ?? offset.y)
    let Fspring = -stiffness * (offset - targetOffset)

    // Damping
    let Fdamper = -damping * velocity

    let a = Fspring + Fdamper

    var newV = velocity + a * CGFloat(dt)
    var newOffset = offset + newV * CGFloat(dt)

    if let yTarget = yTarget {
      if !bounces {
        newOffset.y = yTarget
        newV.y = 0
      } else if targetOffsetY == nil {
        targetOffset.y = yTarget
        targetOffsetY = yTarget
        stiffness.y = 100
        damping.y = 20
      }
    }
    if let xTarget = xTarget {
      if !bounces {
        newOffset.x = xTarget
        newV.x = 0
      } else if targetOffsetX == nil {
        targetOffset.x = xTarget
        targetOffsetX = xTarget
        stiffness.x = 100
        damping.x = 20
      }
    }

    let lowVelocity = abs(newV.x) < threshold && abs(newV.y) < threshold
    if lowVelocity && abs(targetOffset.x - newOffset.x) < threshold && abs(targetOffset.y - newOffset.y) < threshold {
      velocity = CGPoint.zero
      scrollView.contentOffset = targetOffset
      targetOffsetX = nil
      targetOffsetY = nil
      finish()
    } else {
      velocity = newV
      scrollView.contentOffset = newOffset
    }
  }
}
