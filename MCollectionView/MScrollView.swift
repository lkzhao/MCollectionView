//
//  MScrollView.swift
//  MCollectionViewExample
//
//  Created by YiLun Zhao on 2016-02-20.
//  Copyright © 2016 lkzhao. All rights reserved.
//

import UIKit
import MotionAnimation

protocol MScrollViewDelegate{
  func scrollViewWillBeginDraging(scrollView:MScrollView)
  func scrollViewDidEndDraging(scrollView:MScrollView)
  func scrollViewWillStartScroll(scrollView:MScrollView)
  func scrollViewDidScroll(scrollView:MScrollView)
  func scrollViewDidEndScroll(scrollView:MScrollView)
}
let debug = true

func p(items:Any...){
  if debug{
    print(items)
  }
}

class ScrollAnimation:MotionAnimation{
  var scrollView:MScrollView
  init(scrollView:MScrollView) {
    self.scrollView = scrollView
    super.init(playImmediately: false)
  }
  var targetOffsetX:CGFloat?
  var targetOffsetY:CGFloat?
  var velocity = CGPointZero
  var damping:CGPoint = CGPointMake(3, 3)
  var threshold:CGFloat = 0.1
  var stiffness:CGPoint = CGPointMake(50, 50)
  
  var initiallyOutOfBound = false
  func animateDone(){
    targetOffsetX = nil
    targetOffsetY = nil
    // default value
    stiffness = CGPointMake(50, 50)
    damping = CGPointMake(3, 3)
    
    if let yTarget = scrollView.yEdgeTarget(){
      // initially out of bound
      targetOffsetY = yTarget
      stiffness.y = 100
      damping.y = 20
    }
    
    if let xTarget = scrollView.xEdgeTarget(){
      targetOffsetX = xTarget
      stiffness.x = 100
      damping.x = 20
    }

    play()
  }
  
  func animateToTargetOffset(target:CGPoint, stiffness: CGFloat = 1000, damping:CGFloat = 30){
    targetOffsetY = target.y
    targetOffsetX = target.x
    // default value
    self.stiffness = CGPointMake(stiffness, stiffness)
    self.damping = CGPointMake(damping, damping)

    play()
  }

  override func play() {
    p("Play")
    super.play()
  }
  
  override func stop() {
    p("Stop")
    super.stop()
    velocity = CGPointZero
  }
  
  override func update(dt:CGFloat) -> Bool{
    let offset = scrollView.contentOffset
    
    // Force
    var targetOffset = CGPoint(x: targetOffsetX ?? offset.x, y: targetOffsetY ?? offset.y)
    let Fspring = -stiffness * (offset - targetOffset)
    
    // Damping
    let Fdamper = -damping * velocity;
    
    let a = Fspring + Fdamper;
    
    let newV = velocity + a * dt;
    var newOffset = offset + newV * dt;
    
    if let yTarget = scrollView.yEdgeTarget() where targetOffsetY == nil{
      targetOffset.y = yTarget
      if !scrollView.bounce{
        newOffset.y = yTarget
        velocity.y = 0
      }else{
        targetOffsetY = yTarget
        stiffness.y = 50
        damping.y = 10
      }
    }
    if let xTarget = scrollView.xEdgeTarget() where targetOffsetX == nil{
      targetOffset.x = xTarget
      if !scrollView.bounce{
        newOffset.x = xTarget
        velocity.x = 0
      }else{
        targetOffsetX = xTarget
        stiffness.x = 50
        damping.x = 10
      }
    }

    let lowVelocity = abs(newV.x) < threshold && abs(newV.y) < threshold
    if lowVelocity && abs(targetOffset.x - newOffset.x) < threshold && abs(targetOffset.y - newOffset.y) < threshold {
      p("Set to target: \(targetOffset)")
      velocity = CGPointZero
      scrollView.contentOffset = targetOffset
      targetOffsetX = nil
      targetOffsetY = nil
      return false
    } else {
      p("step: \(newOffset)")
      velocity = newV
      scrollView.contentOffset = newOffset
      return true
    }
  }
}



class MScrollView: UIView {
  var panGestureRecognizer:UIPanGestureRecognizer!
  var scrollVelocity:CGPoint{
    return scrollAnimation.velocity
  }
  var contentOffset:CGPoint = CGPointZero{
    didSet{
      p("contentOffset changed: \(oldValue) -> \(contentOffset)")
      contentView.frame.origin = CGPointMake(-contentOffset.x+contentInset.left, -contentOffset.y+contentInset.top)
      didScroll()
    }
  }
  var contentSize:CGSize{
    get{
      return contentView.frame.size
    }
    set{
      p("contentSize changed: \(contentSize) -> \(newValue)")
      contentView.frame.size = newValue
    }
  }
  var containerSize:CGSize{
    return CGSizeMake(contentSize.width + contentInset.left + contentInset.right, contentSize.height + contentInset.top + contentInset.bottom)
  }
  var contentInset:UIEdgeInsets = UIEdgeInsetsZero{
    didSet{
      p("contentInset changed: \(oldValue) \(contentInset)")
    }
  }
  var visibleFrame:CGRect{
    return CGRect(origin: contentOffset, size: bounds.size)
  }
  
  var contentView:UIView
  var scrollAnimation:ScrollAnimation!
  
  var verticalScroll:Bool{
    return contentSize.height > bounds.size.height
  }
  var horizontalScroll:Bool{
    return contentSize.width > bounds.size.width
  }
  var bounce = true
  
  override init(frame: CGRect) {
    contentView = UIView(frame: CGRectZero)
    super.init(frame: frame)
    addSubview(contentView)
    
    scrollAnimation = ScrollAnimation(scrollView: self)
    scrollAnimation.onCompletion = { animation in
      self.didEndScroll()
    }
    scrollAnimation.willStartPlaying = { animation in
      self.willStartScroll()
    }
    
    panGestureRecognizer = UIPanGestureRecognizer(target: self, action: "scroll:")
    addGestureRecognizer(panGestureRecognizer)
  }
  
  func yEdgeTarget(offset:CGPoint? = nil) -> CGFloat?{
    let yOffset = (offset ?? self.contentOffset).y
    if !verticalScroll{
      return nil
    }
    let yMax = containerSize.height - bounds.size.height
    if yOffset <= 0{
      return 0
    } else if yOffset >= yMax {
      return yMax
    }
    return nil
  }
  
  func xEdgeTarget(offset:CGPoint? = nil) -> CGFloat?{
    let xOffset = (offset ?? self.contentOffset).x
    if !horizontalScroll{
      return nil
    }
    let xMax = containerSize.width - bounds.width
    if xOffset <= 0{
      return 0
    } else if xOffset >= xMax {
      return xMax
    }
    return nil
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  var startingContentOffset:CGPoint?
  var startingDragLocation = CGPointZero
  var dragLocation = CGPointZero
  var draging = false
  func scroll(pan:UIPanGestureRecognizer){
    switch pan.state{
    case .Began:
      scrollAnimation.stop()
      startingContentOffset = contentOffset
      dragLocation = pan.locationInView(self)
      startingDragLocation = dragLocation
      delegate?.scrollViewWillBeginDraging(self)
      draging = true
      break
    case .Changed:
      dragLocation = pan.locationInView(self)
      var translation = dragLocation - startingDragLocation
      if !horizontalScroll{
        translation.x = 0
      }
      if !verticalScroll{
        translation.y = 0
      }
      p("PanGR changed, startingContentOffset: \(startingContentOffset!) translation:\(translation)")
      var newContentOffset = startingContentOffset! - translation
//      if let yTarget = yEdgeTarget(newContentOffset){
//        newContentOffset.y = newContentOffset.y - (newContentOffset.y - yTarget) / 3
//      }
//      if let xTarget = xEdgeTarget(newContentOffset){
//        newContentOffset.x = newContentOffset.x - (newContentOffset.x - xTarget) / 3
//      }
      scrollAnimation.animateToTargetOffset(newContentOffset)
    default:
      scrollAnimation.animateDone()
      draging = false
      delegate?.scrollViewDidEndDraging(self)
      break
    }
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    if !scrollAnimation.playing && !draging{
      scrollAnimation.animateDone()
    }
  }
  
  func scrollToFrameVisible(frame:CGRect){
    
  }

  func scrollToBottom(animate:Bool = false){
    if draging{
      return
    }
    p("scroll to bottom animate:\(animate)")
//    p("\(NSThread.callStackSymbols())")
    let target = bottomOffset
    if animate{
      scrollAnimation.animateToTargetOffset(target, stiffness: 200, damping: 20)
    }else{
      scrollAnimation.stop()
      contentOffset = target
    }
  }
  var isAtBottom:Bool{
    return contentOffset.y >= bottomOffset.y || scrollAnimation.targetOffsetY >= bottomOffset.y
  }
  var bottomOffset:CGPoint{
    return CGPointMake(0, containerSize.height - bounds.size.height)
  }
  
  var delegate:MScrollViewDelegate?
  func didScroll(){
    delegate?.scrollViewDidScroll(self)
  }
  func didEndScroll(){
    delegate?.scrollViewDidEndScroll(self)
  }
  func willStartScroll(){
    delegate?.scrollViewWillStartScroll(self)
  }
}
