//
//  MScrollView.swift
//  MCollectionView
//
//  Created by YiLun Zhao on 2016-02-20.
//  Copyright © 2016 lkzhao. All rights reserved.
//

import UIKit
import MotionAnimation
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func >= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l >= r
  default:
    return !(lhs < rhs)
  }
}


@objc public protocol MScrollViewDelegate{
  @objc optional func scrollViewWillBeginDraging(_ scrollView:MScrollView)
  @objc optional func scrollViewDidEndDraging(_ scrollView:MScrollView)
  @objc optional func scrollViewWillStartScroll(_ scrollView:MScrollView)
  @objc optional func scrollViewScrolled(_ scrollView:MScrollView)
  @objc optional func scrollViewDidEndScroll(_ scrollView:MScrollView)
  @objc optional func scrollViewDidDrag(_ scrollView: MScrollView)
  @objc optional func scrollView(_ scrollView: MScrollView, willSwitchFromPage fromPage:Int, toPage: Int)
}

class ScrollAnimation:MotionAnimation{
  weak var scrollView:MScrollView?
  init(scrollView:MScrollView) {
    self.scrollView = scrollView
    super.init(playImmediately: false)
  }
  var targetOffsetX:CGFloat?
  var targetOffsetY:CGFloat?
  var velocity = CGPoint.zero
  var damping:CGPoint = CGPoint(x: 3, y: 3)
  var threshold:CGFloat = 0.1
  var stiffness:CGPoint = CGPoint(x: 50, y: 50)
  
  var initiallyOutOfBound = false
  func animateDone(){
    guard let scrollView = scrollView else { return }
    targetOffsetX = nil
    targetOffsetY = nil
    // default value
    stiffness = CGPoint(x: 50, y: 50)
    damping = CGPoint(x: 3, y: 3)

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
      if finalOffsetY >= scrollView.contentFrame.minY && finalOffsetY <= scrollView.contentFrame.maxY {
        if scrollView.pageIndexBeforeDrag != page{
          scrollView.scrollDelegate?.scrollView?(scrollView, willSwitchFromPage:scrollView.pageIndexBeforeDrag, toPage:page)
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
      if finalOffsetX >= scrollView.contentFrame.minX && finalOffsetX <= scrollView.contentFrame.maxX{
        if scrollView.pageIndexBeforeDrag != page{
          scrollView.scrollDelegate?.scrollView?(scrollView, willSwitchFromPage:scrollView.pageIndexBeforeDrag, toPage:page)
        }
        targetOffsetX = finalOffsetX
        stiffness.x = 100
        damping.x = 20
      }
    }

    play()
  }
  
  func animateToTargetOffset(_ target:CGPoint, stiffness: CGFloat = 1000, damping:CGFloat = 30){
    targetOffsetY = target.y
    targetOffsetX = target.x
    // default value
    self.stiffness = CGPoint(x: stiffness, y: stiffness)
    self.damping = CGPoint(x: damping, y: damping)

    play()
  }
  
  override func stop() {
    super.stop()
    velocity = CGPoint.zero
  }

  fileprivate var offset:CGPoint = CGPoint.zero
  fileprivate var yTarget:CGFloat?
  fileprivate var xTarget:CGFloat?
  fileprivate var bounces:Bool = false
  override func willUpdate(){
    offset = scrollView?.contentOffset ?? CGPoint.zero
    yTarget = scrollView?.yEdgeTarget()
    xTarget = scrollView?.xEdgeTarget()
    bounces = scrollView?.bounces ?? false
  }
  override func didUpdate(){
    scrollView?.contentOffset = offset
  }

  override func update(_ dt:CGFloat) -> Bool{
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
      velocity = CGPoint.zero
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



open class MScrollView: UIView {
  open weak var scrollDelegate:MScrollViewDelegate?
  open var panGestureRecognizer:UIPanGestureRecognizer!
  open var scrollVelocity:CGPoint{
    return scrollAnimation.velocity
  }
  open var contentOffset:CGPoint = CGPoint.zero{
    didSet{
      contentView.transform = CGAffineTransform.identity.translatedBy(x: -contentOffset.x, y: -contentOffset.y)
      didScroll()
    }
  }
  open var contentFrame:CGRect {
    get{
      return CGRect(center: contentView.center, size: contentView.bounds.size)
    }
    set{
      #if DEBUG
        print("contentFrame changed: \(contentFrame) -> \(newValue)")
      #endif
      let oldSize = contentView.bounds.size
      let newSize = newValue.size
      contentView.bounds = newValue.bounds
      contentView.center = newValue.center

      // content shrinks. we might need to move the contentOffset to fill empty space
      if oldSize.width > newSize.width || oldSize.height > newSize.height {
        adjustContentOffsetIfNecessary()
      }
    }
  }
  open var containerFrame:CGRect{
    return UIEdgeInsetsInsetRect(contentFrame, -contentInset)
  }
  open var contentInset:UIEdgeInsets = UIEdgeInsets.zero{
    didSet{
      #if DEBUG
        print("contentInset changed: \(oldValue) -> \(contentInset)")
      #endif
      contentOffset = CGPoint(x: contentOffset.x - contentInset.left + oldValue.left, y: contentOffset.y - contentInset.top + oldValue.top)

      // inset shrinks. we might need to move the contentOffset to fill empty space
      if contentInset.top < oldValue.top || contentInset.bottom < oldValue.bottom || contentInset.left < oldValue.left || contentInset.right < oldValue.right {
        adjustContentOffsetIfNecessary()
      }
    }
  }
  open var visibleFrame:CGRect{
    return CGRect(origin: CGPoint(x: contentOffset.x - contentInset.left, y: contentOffset.y - contentInset.top), size: bounds.size)
  }

  open var currentPageIndex:Int{
    if verticalScroll && !horizontalScroll{
      let height = bounds.height
      let page = Int( (contentOffset.y + height/2) / height )
      return page
    } else if horizontalScroll && !verticalScroll{
      let width = bounds.width
      let page = Int( (contentOffset.x + width/2) / width )
      return page
    }
    return 0
  }
  
  open let contentView:UIView = UIView(frame: CGRect.zero)
  var scrollAnimation:ScrollAnimation!
  
  open var verticalScroll:Bool = true
  open var alwaysBounceVertical:Bool = false
  open var horizontalScroll:Bool = false
  open var alwaysBounceHorizontal:Bool = false
  open var bounces = true
  open var paged = false
  open fileprivate(set) var draging = false
  
  public override init(frame: CGRect) {
    super.init(frame: frame)
    commoninit()
  }
  
  public required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    commoninit()
  }
  
  func commoninit(){
    addSubview(contentView)
    
    scrollAnimation = ScrollAnimation(scrollView: self)
    scrollAnimation.onCompletion = { [weak self] animation in
      self?.didEndScroll()
    }
    scrollAnimation.willStartPlaying = { [weak self] animation in
      self?.willStartScroll()
    }
    
    panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(scroll))
    panGestureRecognizer.delegate = self
    addGestureRecognizer(panGestureRecognizer)
  }
  
  func yEdgeTarget(_ offset:CGPoint? = nil) -> CGFloat?{
    let yOffset = (offset ?? self.contentOffset).y
    if !verticalScroll{
      return nil
    }
    let yMax = max(containerFrame.minY, containerFrame.maxY - bounds.size.height)
    if yOffset <= containerFrame.minY {
      return containerFrame.minY
    } else if yOffset >= yMax {
      return yMax
    }
    return nil
  }
  
  func xEdgeTarget(_ offset:CGPoint? = nil) -> CGFloat?{
    let xOffset = (offset ?? self.contentOffset).x
    if !horizontalScroll{
      return nil
    }
    let xMax = max(containerFrame.minX, containerFrame.maxX - bounds.width)
    if xOffset <= containerFrame.minX {
      return containerFrame.minX
    } else if xOffset >= xMax {
      return xMax
    }
    return nil
  }
  
  var startingContentOffset:CGPoint?
  var startingDragLocation = CGPoint.zero
  var dragLocation = CGPoint.zero
  var pageIndexBeforeDrag = 0
  func scroll(_ pan:UIPanGestureRecognizer){
    switch pan.state{
    case .began:
      pageIndexBeforeDrag = self.currentPageIndex
      scrollAnimation.stop()
      startingContentOffset = contentOffset
      dragLocation = pan.location(in: self)
      startingDragLocation = dragLocation
      scrollDelegate?.scrollViewWillBeginDraging?(self)
      draging = true
      break
    case .changed:
      dragLocation = pan.location(in: self)
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
      scrollDelegate?.scrollViewDidDrag?(self)
      scrollAnimation.animateToTargetOffset(newContentOffset)
    default:
      scrollAnimation.animateDone()
      draging = false
      scrollDelegate?.scrollViewDidEndDraging?(self)
      break
    }
  }
  
  open override func layoutSubviews() {
    super.layoutSubviews()
    adjustContentOffsetIfNecessary()
  }

  func adjustContentOffsetIfNecessary(){
    if !draging && scrollAnimation.targetOffsetX == nil && scrollAnimation.targetOffsetY == nil{
      scrollAnimation.animateDone()
    }
  }
  
  open func scrollToFrameVisible(_ frame:CGRect){
    
  }

  open func scrollToPage(_ index:Int, animate:Bool = false){
    let target = horizontalScroll ? CGPoint(x: CGFloat(index) * bounds.width, y: 0) : CGPoint(x: 0, y: CGFloat(index) * bounds.height)
    if animate{
      scrollAnimation.animateToTargetOffset(target, stiffness: 200, damping: 20)
    } else {
      scrollAnimation.stop()
      contentOffset = target
    }
  }

  open func scrollToBottom(_ animate:Bool = false){
    if draging || containerFrame.height < bounds.height{
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
  open var isAtBottom:Bool{
    return contentOffset.y >= bottomOffset.y || scrollAnimation.targetOffsetY >= bottomOffset.y
  }
  open var bottomOffset:CGPoint{
    return CGPoint(x: 0, y: containerFrame.maxY - bounds.size.height)
  }
  
  func didScroll(){
    scrollDelegate?.scrollViewScrolled?(self)
  }
  func didEndScroll(){
    scrollDelegate?.scrollViewDidEndScroll?(self)
  }
  func willStartScroll(){
    scrollDelegate?.scrollViewWillStartScroll?(self)
  }
}

extension MScrollView:UIGestureRecognizerDelegate{
    open override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let superValue = super.gestureRecognizerShouldBegin(gestureRecognizer)
        if gestureRecognizer == panGestureRecognizer && superValue {
            let v = panGestureRecognizer.velocity(in: self.contentView)
            if verticalScroll && !horizontalScroll {
                return (alwaysBounceVertical || containerFrame.height > bounds.height) && abs(v.y) >= abs(v.x)
            } else if horizontalScroll && !verticalScroll{
                return (alwaysBounceHorizontal || containerFrame.width > bounds.width) && abs(v.y) <= abs(v.x)
            } else {
                return verticalScroll && horizontalScroll
            }
        }
        return superValue
    }
}
