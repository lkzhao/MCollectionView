//
//  MScrollView.swift
//  MCollectionViewExample
//
//  Created by YiLun Zhao on 2016-02-20.
//  Copyright © 2016 lkzhao. All rights reserved.
//

import UIKit
import MotionAnimation

@objc protocol MScrollViewDelegate{
  optional func scrollViewWillBeginDraging(scrollView:MScrollView)
  optional func scrollViewDidEndDraging(scrollView:MScrollView)
  optional func scrollViewWillStartScroll(scrollView:MScrollView)
  optional func scrollViewScrolled(scrollView:MScrollView)
  optional func scrollViewDidEndScroll(scrollView:MScrollView)
  optional func scrollViewDidDrag(scrollView: MScrollView)
  optional func scrollView(scrollView: MScrollView, willSwitchFromPage fromPage:Int, toPage: Int)
}

class ScrollAnimation:MotionAnimation{
  weak var scrollView:MScrollView?
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
    guard let scrollView = scrollView else { return }
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
    } else if scrollView.paged && scrollView.verticalScroll {
      let height = scrollView.bounds.height
      let velocityFactor:CGFloat = (scrollView.scrollVelocity.y/5).clamp(-height/2, height/2)
      let page = Int((scrollView.contentOffset.y + height/2 + velocityFactor) / height)
      let finalOffsetY = CGFloat(page) * height
      if finalOffsetY >= 0 && finalOffsetY <= scrollView.contentSize.height{
        if scrollView.pageIndexBeforeDrag != page{
          scrollView.delegate?.scrollView?(scrollView, willSwitchFromPage:scrollView.pageIndexBeforeDrag, toPage:page)
        }
        targetOffsetY = finalOffsetY
        stiffness.y = 100
        damping.y = 20
      }
    }
    
    if let xTarget = scrollView.xEdgeTarget(){
      targetOffsetX = xTarget
      stiffness.x = 100
      damping.x = 20
    } else if scrollView.paged && scrollView.horizontalScroll {
      let width = scrollView.bounds.width
      let velocityFactor:CGFloat = (scrollView.scrollVelocity.x/5).clamp(-width/2, width/2)
      let page = Int((scrollView.contentOffset.x + width/2 + velocityFactor) / width)
      let finalOffsetX = CGFloat(page) * width
      if finalOffsetX >= 0 && finalOffsetX <= scrollView.contentSize.width{
        if scrollView.pageIndexBeforeDrag != page{
          scrollView.delegate?.scrollView?(scrollView, willSwitchFromPage:scrollView.pageIndexBeforeDrag, toPage:page)
        }
        targetOffsetX = finalOffsetX
        stiffness.x = 100
        damping.x = 20
      }
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
  
  override func stop() {
    super.stop()
    velocity = CGPointZero
  }

  private var offset:CGPoint = CGPointZero
  private var yTarget:CGFloat?
  private var xTarget:CGFloat?
  private var bounces:Bool = false
  override func willUpdate(){
    offset = scrollView?.contentOffset ?? CGPointZero
    yTarget = scrollView?.yEdgeTarget()
    xTarget = scrollView?.xEdgeTarget()
    bounces = scrollView?.bounces ?? false
  }
  override func didUpdate(){
    scrollView?.contentOffset = offset
  }

  override func update(dt:CGFloat) -> Bool{
    // Force
    var targetOffset = CGPoint(x: targetOffsetX ?? offset.x, y: targetOffsetY ?? offset.y)
    let Fspring = -stiffness * (offset - targetOffset)
    
    // Damping
    let Fdamper = -damping * velocity;
    
    let a = Fspring + Fdamper;
    
    var newV = velocity + a * dt;
    var newOffset = offset + newV * dt;
    
    if let yTarget = yTarget{
      if !bounces{
        newOffset.y = yTarget
        newV.y = 0
      }else if targetOffsetY == nil{
        targetOffset.y = yTarget
        targetOffsetY = yTarget
        stiffness.y = 100
        damping.y = 20
      }
    }
    if let xTarget = xTarget{
      if !bounces{
        newOffset.x = xTarget
        newV.x = 0
      }else if targetOffsetX == nil{
        targetOffset.x = xTarget
        targetOffsetX = xTarget
        stiffness.x = 100
        damping.x = 20
      }
    }

    let lowVelocity = abs(newV.x) < threshold && abs(newV.y) < threshold
    if lowVelocity && abs(targetOffset.x - newOffset.x) < threshold && abs(targetOffset.y - newOffset.y) < threshold {
      velocity = CGPointZero
      offset = targetOffset
      targetOffsetX = nil
      targetOffsetY = nil
      return false
    } else {
      velocity = newV
      offset = newOffset
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
      contentView.frame.origin = CGPointMake(-contentOffset.x+contentInset.left, -contentOffset.y+contentInset.top)
      didScroll()
    }
  }
  var contentSize:CGSize{
    get{
      return contentView.frame.size
    }
    set{
      #if DEBUG
        print("contentSize changed: \(contentSize) -> \(newValue)")
      #endif
      let oldSize = contentView.frame.size
      contentView.frame.size = newValue
      if oldSize.width > newValue.width || oldSize.height > newValue.height {
        // only adjust contentOffset if we are setting a smaller size
        adjustContentOffsetIfNecessary()
      }
    }
  }
  var containerSize:CGSize{
    return CGSizeMake(contentSize.width + contentInset.left + contentInset.right, contentSize.height + contentInset.top + contentInset.bottom)
  }
  var contentInset:UIEdgeInsets = UIEdgeInsetsZero{
    didSet{
      #if DEBUG
        print("contentInset changed: \(oldValue) -> \(contentInset)")
      #endif
      contentView.frame.origin = CGPointMake(-contentOffset.x+contentInset.left, -contentOffset.y+contentInset.top)
      if contentInset.top < oldValue.top || contentInset.bottom < oldValue.bottom || contentInset.left < oldValue.left || contentInset.right < oldValue.right {
        adjustContentOffsetIfNecessary()
      }
    }
  }
  var visibleFrame:CGRect{
    return CGRect(origin: CGPointMake(contentOffset.x - contentInset.left, contentOffset.y - contentInset.top), size: bounds.size)
  }

  var currentPageIndex:Int{
    if verticalScroll && !horizontalScroll{
      let height = bounds.height
      let page = Int( (contentOffset.y + height/2) / height )
      return page
    } else if horizontalScroll && !verticalScroll{
      let width = bounds.width
      let page = Int( (contentOffset.x + width/2) / width )
      return page
    }
    fatalError("paged scrollview should only be scrolled in one axis")
  }
  
  var contentView:UIView
  var scrollAnimation:ScrollAnimation!
  
  var verticalScroll:Bool = true
  var alwaysBounceVertical:Bool = false
  var horizontalScroll:Bool = false
  var alwaysBounceHorizontal:Bool = false
  var bounces = true
  
  override init(frame: CGRect) {
    contentView = UIView(frame: CGRectZero)
    super.init(frame: frame)
    addSubview(contentView)
    
    scrollAnimation = ScrollAnimation(scrollView: self)
    scrollAnimation.onCompletion = { [weak self] animation in
      self?.didEndScroll()
    }
    scrollAnimation.willStartPlaying = { [weak self] animation in
      self?.willStartScroll()
    }
    
    panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(scroll(_:)))
    panGestureRecognizer.delegate = self
    addGestureRecognizer(panGestureRecognizer)
  }
  
  func yEdgeTarget(offset:CGPoint? = nil) -> CGFloat?{
    let yOffset = (offset ?? self.contentOffset).y
    if !verticalScroll{
      return nil
    }
    let yMax = max(0, containerSize.height - bounds.size.height)
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
    let xMax = max(0, containerSize.width - bounds.width)
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
  var paged = false
  var pageIndexBeforeDrag = 0
  func scroll(pan:UIPanGestureRecognizer){
    switch pan.state{
    case .Began:
      pageIndexBeforeDrag = self.currentPageIndex
      scrollAnimation.stop()
      startingContentOffset = contentOffset
      dragLocation = pan.locationInView(self)
      startingDragLocation = dragLocation
      delegate?.scrollViewWillBeginDraging?(self)
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
      var newContentOffset = startingContentOffset! - translation
      if let yTarget = yEdgeTarget(newContentOffset){
        newContentOffset.y = newContentOffset.y - (newContentOffset.y - yTarget) / 2
      }
      if let xTarget = xEdgeTarget(newContentOffset){
        newContentOffset.x = newContentOffset.x - (newContentOffset.x - xTarget) / 2
      }
      delegate?.scrollViewDidDrag?(self)
      scrollAnimation.animateToTargetOffset(newContentOffset)
    default:
      scrollAnimation.animateDone()
      draging = false
      delegate?.scrollViewDidEndDraging?(self)
      break
    }
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    adjustContentOffsetIfNecessary()
  }

  func adjustContentOffsetIfNecessary(){
    if !draging{
      scrollAnimation.animateDone()
    }
  }
  
  func scrollToFrameVisible(frame:CGRect){
    
  }

  func scrollToPage(index:Int, animate:Bool = false){
    let target = horizontalScroll ? CGPointMake(CGFloat(index) * bounds.width, 0) : CGPointMake(0, CGFloat(index) * bounds.height)
    if animate{
      scrollAnimation.animateToTargetOffset(target, stiffness: 200, damping: 20)
    } else {
      scrollAnimation.stop()
      contentOffset = target
    }
  }

  func scrollToBottom(animate:Bool = false){
    if draging || containerSize.height < bounds.height{
      return
    }
    let target = bottomOffset
    if animate{
      scrollAnimation.animateToTargetOffset(target, stiffness: 200, damping: 20)
    } else {
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
  
  weak var delegate:MScrollViewDelegate?
  func didScroll(){
    delegate?.scrollViewScrolled?(self)
  }
  func didEndScroll(){
    delegate?.scrollViewDidEndScroll?(self)
  }
  func willStartScroll(){
    delegate?.scrollViewWillStartScroll?(self)
  }
}

extension MScrollView:UIGestureRecognizerDelegate{
    override func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        let superValue = super.gestureRecognizerShouldBegin(gestureRecognizer)
        if gestureRecognizer == panGestureRecognizer && superValue {
            let v = panGestureRecognizer.velocityInView(self.contentView)
            if verticalScroll && !horizontalScroll {
                return (alwaysBounceVertical || containerSize.height > bounds.height) && abs(v.y) >= abs(v.x)
            } else if horizontalScroll && !verticalScroll{
                return (alwaysBounceHorizontal || containerSize.width > bounds.width) && abs(v.y) <= abs(v.x)
            } else {
                return verticalScroll && horizontalScroll
            }
        }
        return superValue
    }
}