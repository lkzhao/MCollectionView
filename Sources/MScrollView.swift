//
//  MScrollView.swift
//  MCollectionView
//
//  Created by YiLun Zhao on 2016-02-20.
//  Copyright © 2016 lkzhao. All rights reserved.
//

import UIKit
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
  public weak var scrollDelegate: MScrollViewDelegate?


  public enum AnchorPoint {
    case topLeft
    case bottomRight
  }

  // anchorPoint determine the behavior of contentOffset when contentSize/contentInset/frame change.
  // consider a vertical scroll view with many objects on screen:
  //   for .topLeft anchorPoint: 
  //     adding an object at the top will push other objects down on screen
  //     adding an object at the bottom will have no effect other objects
  //   for .bottomRight anchorPoint:
  //     adding an object at the top will have no effect other objects
  //     adding an object at the bottom will push other objects up
  public var anchorPoint: AnchorPoint = .topLeft

  public var panGestureRecognizer: UIPanGestureRecognizer!

  public var scrollVelocity: CGPoint {
    return scrollAnimation.velocity
  }

  public let contentView: UIView = UIView(frame: CGRect.zero)

  open var verticalScroll: Bool = true
  open var alwaysBounceVertical: Bool = false
  open var horizontalScroll: Bool = false
  open var alwaysBounceHorizontal: Bool = false
  open var bounces = true
  open var paged = false
  open fileprivate(set) var isDraging = false

  internal var scrollAnimation: MScrollAnimation!
  internal var lastTranslation: CGPoint?
  internal var dragLocation = CGPoint.zero
  internal var pageIndexBeforeDrag = 0

  public var contentOffset: CGPoint = CGPoint.zero {
    didSet {
      contentView.transform = CGAffineTransform.identity.translatedBy(x: -contentOffset.x, y: -contentOffset.y)
    }
  }

  /// raw value for contentFrame
  private var _contentFrame:CGRect {
    get {
      return CGRect(center: contentView.center, size: contentView.bounds.size)
    }
    set {
      #if DEBUG
        print("contentFrame changed: \(contentFrame) -> \(newValue)")
      #endif
      contentView.bounds = newValue.bounds
      contentView.center = newValue.center
    }
  }
  /// raw value for contentInset
  private var _contentInset:UIEdgeInsets = UIEdgeInsets.zero {
    didSet {
      #if DEBUG
        print("contentInset changed: \(oldValue) -> \(contentInset)")
      #endif
    }
  }

  // public access for contentFrame
  public var contentFrame: CGRect{
    get {
      return _contentFrame
    }
    set {
      setContentFrame(newValue)
    }
  }
  // public access for contentInset
  public var contentInset: UIEdgeInsets {
    get {
      return _contentInset
    }
    set {
      setContentInset(newValue)
    }
  }

  public var containerFrame: CGRect {
    return UIEdgeInsetsInsetRect(contentFrame, -contentInset)
  }

  public var visibleFrame: CGRect {
    return CGRect(origin: contentOffset, size: bounds.size)
  }

  public var currentTargetOffset: CGPoint {
    return CGPoint(x: scrollAnimation.targetOffsetX ?? contentOffset.x,
                   y: scrollAnimation.targetOffsetY ?? contentOffset.y)
  }

  override open var frame:CGRect {
    didSet {
      if anchorPoint == .bottomRight {
        let newSize = frame.size
        let oldSize = oldValue.size
        setContentOffset(CGPoint(x: contentOffset.x - newSize.width + oldSize.width,
                                 y: contentOffset.y - newSize.height + oldSize.height))
      }
    }
  }

  public func setContentOffset(_ targetOffset: CGPoint, clampToEdges:Bool = true, animate: Bool = false) {
    var targetOffset = targetOffset
    if clampToEdges {
      targetOffset = CGPoint(x: targetOffset.x.clamp(offsetAt(.left), offsetAt(.right)),
                             y: targetOffset.y.clamp(offsetAt(.top), offsetAt(.bottom)))
    }
    if animate {
      scrollAnimation.animateToTargetOffset(targetOffset, stiffness: 300, damping: 30)
    } else {
      // in case of not animating, if there is a ongoing scroll animation,
      // we update its target relative to the new contentOffset
      let contentOffsetDiff = targetOffset - contentOffset
      if let targetY = scrollAnimation.targetOffsetY {
        scrollAnimation.targetOffsetY = targetY + contentOffsetDiff.y
      }
      if let targetX = scrollAnimation.targetOffsetX {
        scrollAnimation.targetOffsetX = targetX + contentOffsetDiff.x
      }
      contentOffset = targetOffset
    }
  }

  public func setContentInset(_ targetInset: UIEdgeInsets, clampToEdges:Bool = true, animate: Bool = false) {
    let oldValue = contentInset
    let targetOffset: CGPoint
    let currentOffset: CGPoint = currentTargetOffset
    if anchorPoint == .topLeft {
      targetOffset = CGPoint(x: currentOffset.x - targetInset.left + oldValue.left,
                             y: currentOffset.y - targetInset.top + oldValue.top)
    } else {
      targetOffset = CGPoint(x: currentOffset.x + targetInset.right - oldValue.right,
                             y: currentOffset.y + targetInset.bottom - oldValue.bottom)
    }
    _contentInset = targetInset
    setContentOffset(targetOffset,
                     clampToEdges: clampToEdges,
                     animate: animate)
  }

  public func setContentFrame(_ targetFrame: CGRect, clampToEdges:Bool = true, animate: Bool = false) {
    let oldSize = contentView.bounds.size
    let newSize = targetFrame.size
    let targetOffset: CGPoint
    if anchorPoint == .topLeft {
      targetOffset = self.contentOffset
    } else {
      targetOffset = CGPoint(x: newSize.width - oldSize.width + contentOffset.x,
                             y: newSize.height - oldSize.height + contentOffset.y)
    }
    _contentFrame = targetFrame
    setContentOffset(targetOffset,
                     clampToEdges: clampToEdges,
                     animate: animate)
  }

  public var currentPageIndex: Int {
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

  public override init(frame: CGRect) {
    super.init(frame: frame)
    commoninit()
  }

  public required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    commoninit()
  }

  func commoninit() {
    clipsToBounds = true
    addSubview(contentView)

    scrollAnimation = MScrollAnimation(scrollView: self)

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

  func handlePanGesture(_ pan: UIPanGestureRecognizer) {
    switch pan.state {
    case .began:
      pageIndexBeforeDrag = self.currentPageIndex
      scrollAnimation.stop()
      scrollDelegate?.scrollViewWillBeginDraging?(self)
      isDraging = true
      fallthrough
    case .changed:
      dragLocation = pan.location(in: self)
      let currentTranslation = pan.translation(in: self)
      var translation = currentTranslation - (lastTranslation ?? .zero)
      lastTranslation = currentTranslation
      if !horizontalScroll {
        translation.x = 0
      }
      if !verticalScroll {
        translation.y = 0
      }
      var newContentOffset = currentTargetOffset - translation
      if newContentOffset.y > offsetAt(.bottom) || newContentOffset.y < offsetAt(.top) {
        newContentOffset.y = newContentOffset.y + translation.y / 2
      }
      if newContentOffset.x > offsetAt(.right) || newContentOffset.x < offsetAt(.left) {
        newContentOffset.x = newContentOffset.x + translation.x / 2
      }
      scrollDelegate?.scrollViewDidDrag?(self)
      scrollAnimation.animateToTargetOffset(newContentOffset)
    default:
      lastTranslation = nil
      scrollAnimation.animateDone()
      isDraging = false
      scrollDelegate?.scrollViewDidEndDraging?(self)
      break
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

  open func scrollToFrameVisible(_ frame: CGRect) {
    // TODO
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

  public func scroll(to edge: Edge, animate: Bool = true) {
    if isDraging ||
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
