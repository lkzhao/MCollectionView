//
//  MScrollView.swift
//  MCollectionView
//
//  Created by YiLun Zhao on 2016-02-20.
//  Copyright © 2016 lkzhao. All rights reserved.
//

import UIKit
import MotionAnimation
import UIKit.UIGestureRecognizerSubclass

class ImmediatePanGestureRecognizer: UIPanGestureRecognizer {
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
    if (state == .began) {
      return
    }
    super.touchesBegan(touches, with: event)
    state = .began
  }
}

open class MScrollView: UIView {
  open weak var scrollDelegate: MScrollViewDelegate?


  public enum AnchorPoint {
    case topLeft
    case bottomRight
  }

  // anchorPoint determine the behavior of contentOffset when contentSize or contentInset change.
  // consider a vertical scroll view with many objects on screen:
  //   for .topLeft anchorPoint: 
  //     adding an object at the top will push other objects down on screen
  //     adding an object at the bottom will have no effect other objects
  //   for .bottomRight anchorPoint:
  //     adding an object at the top will have no effect other objects
  //     adding an object at the bottom will push other objects up
  public var anchorPoint: AnchorPoint = .topLeft

  open var panGestureRecognizer: UIPanGestureRecognizer!
  open var scrollVelocity: CGPoint {
    return scrollAnimation.velocity
  }
  open var contentOffset: CGPoint = CGPoint.zero {
    didSet {
      contentView.transform = CGAffineTransform.identity.translatedBy(x: -contentOffset.x, y: -contentOffset.y)
      didScroll()
    }
  }
  open var contentFrame: CGRect {
    get {
      return CGRect(center: contentView.center, size: contentView.bounds.size)
    }
    set {
      #if DEBUG
        print("contentFrame changed: \(contentFrame) -> \(newValue)")
      #endif
      let oldSize = contentView.bounds.size
      let newSize = newValue.size
      contentView.bounds = newValue.bounds
      contentView.center = newValue.center

      if anchorPoint == .bottomRight {
        var targetOffset = CGPoint(x: newSize.width - oldSize.width + contentOffset.x, y: newSize.height - oldSize.height + contentOffset.y)
        targetOffset = CGPoint(x: min(targetOffset.x, offsetAt(.right)) , y: min(targetOffset.y, offsetAt(.bottom)))
        _setContentOffset(targetOffset)
      }

      // content shrinks. we might need to move the contentOffset to fill empty space
      if oldSize.width > newSize.width || oldSize.height > newSize.height {
        adjustContentOffsetIfNecessary()
      }
    }
  }
  open var containerFrame: CGRect {
    return UIEdgeInsetsInsetRect(contentFrame, -contentInset)
  }
  open var contentInset: UIEdgeInsets = UIEdgeInsets.zero {
    didSet {
      #if DEBUG
        print("contentInset changed: \(oldValue) -> \(contentInset)")
      #endif
      if anchorPoint == .topLeft {
        _setContentOffset(CGPoint(x: contentOffset.x - contentInset.left + oldValue.left, y: contentOffset.y - contentInset.top + oldValue.top))
      } else {
        _setContentOffset(CGPoint(x: contentOffset.x + contentInset.right - oldValue.right, y: contentOffset.y + contentInset.bottom - oldValue.bottom))
      }

      // inset shrinks. we might need to move the contentOffset to fill empty space
      if contentInset.top < oldValue.top || contentInset.bottom < oldValue.bottom || contentInset.left < oldValue.left || contentInset.right < oldValue.right {
        adjustContentOffsetIfNecessary()
      }
    }
  }
  open var visibleFrame: CGRect {
    return CGRect(origin: contentOffset, size: bounds.size)
  }

  func _setContentOffset(_ offset: CGPoint) {
    let contentOffsetDiff = offset - contentOffset
    if let targetY = scrollAnimation.targetOffsetY {
      scrollAnimation.targetOffsetY = targetY + contentOffsetDiff.y
    }
    if let targetX = scrollAnimation.targetOffsetX {
      scrollAnimation.targetOffsetX = targetX + contentOffsetDiff.x
    }
    contentOffset = offset
  }

  open var currentPageIndex: Int {
    if verticalScroll && !horizontalScroll {
      let height = bounds.height
      let page = Int( (contentOffset.y + height/2) / height )
      return page
    } else if horizontalScroll && !verticalScroll {
      let width = bounds.width
      let page = Int( (contentOffset.x + width/2) / width )
      return page
    }
    return 0
  }

  open let contentView: UIView = UIView(frame: CGRect.zero)
  var scrollAnimation: MScrollAnimation!

  open var verticalScroll: Bool = true
  open var alwaysBounceVertical: Bool = false
  open var horizontalScroll: Bool = false
  open var alwaysBounceHorizontal: Bool = false
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

  func commoninit() {
    addSubview(contentView)

    scrollAnimation = MScrollAnimation(scrollView: self)
    scrollAnimation.onCompletion = { [weak self] animation in
      self?.didEndScroll()
    }
    scrollAnimation.willStartPlaying = { [weak self] animation in
      self?.willStartScroll()
    }

    panGestureRecognizer = ImmediatePanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
    panGestureRecognizer.delegate = self
    addGestureRecognizer(panGestureRecognizer)
  }

  func yEdgeTarget(_ offset: CGPoint? = nil) -> CGFloat? {
    let yOffset = (offset ?? self.contentOffset).y
    if !verticalScroll {
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

  func xEdgeTarget(_ offset: CGPoint? = nil) -> CGFloat? {
    let xOffset = (offset ?? self.contentOffset).x
    if !horizontalScroll {
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

  var startingContentOffset: CGPoint?
  var startingDragLocation = CGPoint.zero
  var dragLocation = CGPoint.zero
  var pageIndexBeforeDrag = 0
  func handlePanGesture(_ pan: UIPanGestureRecognizer) {
    switch pan.state {
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
      if !horizontalScroll {
        translation.x = 0
      }
      if !verticalScroll {
        translation.y = 0
      }
      var newContentOffset = startingContentOffset! - translation
      if let yTarget = yEdgeTarget(newContentOffset) {
        newContentOffset.y = newContentOffset.y - (newContentOffset.y - yTarget) / 2
      }
      if let xTarget = xEdgeTarget(newContentOffset) {
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

  func adjustContentOffsetIfNecessary() {
    if !draging && scrollAnimation.targetOffsetX == nil && scrollAnimation.targetOffsetY == nil {
      scrollAnimation.animateDone()
    }
  }

  open func scrollToFrameVisible(_ frame: CGRect) {

  }

  open func scrollToPage(_ index: Int, animate: Bool = false) {
    let target = horizontalScroll ? CGPoint(x: CGFloat(index) * bounds.width, y: 0) : CGPoint(x: 0, y: CGFloat(index) * bounds.height)
    if animate {
      scrollAnimation.animateToTargetOffset(target, stiffness: 200, damping: 20)
    } else {
      scrollAnimation.stop()
      contentOffset = target
    }
  }

  func didScroll() {
    scrollDelegate?.scrollViewScrolled?(self)
  }
  func didEndScroll() {
    scrollDelegate?.scrollViewDidEndScroll?(self)
  }
  func willStartScroll() {
    scrollDelegate?.scrollViewWillStartScroll?(self)
  }
}

extension MScrollView {
  var allowToScrollVertically: Bool {
    return verticalScroll && (alwaysBounceVertical || containerFrame.height > bounds.height)
  }

  var allowToScrollHorizontally: Bool {
    return horizontalScroll && (alwaysBounceHorizontal || containerFrame.width > bounds.width)
  }

  public enum Edge {
    case top, left, bottom, right
  }

  public func isVertical(edge: Edge) -> Bool {
    return edge == .top || edge == .bottom
  }

  public func contentOffset(at edge: Edge) -> CGPoint {
    if isVertical(edge: edge) {
      return CGPoint(x: contentOffset.x, y: offsetAt(edge))
    } else {
      return CGPoint(x: offsetAt(edge), y: contentOffset.y)
    }
  }

  public func scroll(to edge: Edge, animate: Bool = true) {
    if draging ||
      (isVertical(edge: edge) && !allowToScrollVertically) ||
      (!isVertical(edge: edge) && !allowToScrollHorizontally) {
      return
    }
    let target = contentOffset(at: edge)
    if animate {
      scrollAnimation.animateToTargetOffset(target, stiffness: 200, damping: 20)
    } else {
      scrollAnimation.stop()
      contentOffset = target
    }
  }

  public func isAt(_ edge: Edge) -> Bool {
    switch edge {
    case .top:
      return scrollAnimation.targetOffsetY ?? contentOffset.y <= offsetAt(edge)
    case .bottom:
      return scrollAnimation.targetOffsetY ?? contentOffset.y >= offsetAt(edge)
    case .left:
      return scrollAnimation.targetOffsetX ?? contentOffset.x <= offsetAt(edge)
    case .right:
      return scrollAnimation.targetOffsetX ?? contentOffset.x >= offsetAt(edge)
    }
  }

  open func offsetAt(_ edge: Edge) -> CGFloat {
    switch edge {
    case .top:
      return containerFrame.minY
    case .bottom:
      return containerFrame.maxY - bounds.size.height
    case .left:
      return containerFrame.minX
    case .right:
      return containerFrame.maxX - bounds.size.width
    }
  }

  open func scroll(with velocity:CGPoint) {
    scrollAnimation.velocity = velocity
    scrollAnimation.animateDone()
  }
}

extension MScrollView:UIGestureRecognizerDelegate {
  open override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    let superValue = super.gestureRecognizerShouldBegin(gestureRecognizer)
    if gestureRecognizer == panGestureRecognizer && superValue {
      let velocity = panGestureRecognizer.velocity(in: self.contentView)
      if abs(velocity.y) > abs(velocity.x) {
        return allowToScrollVertically
      } else if abs(velocity.y) < abs(velocity.x) {
        return allowToScrollHorizontally
      } else {
        return allowToScrollVertically || allowToScrollHorizontally
      }
    }
    return superValue
  }
}
