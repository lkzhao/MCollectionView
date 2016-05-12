//
//  MCell.swift
//  MCollectionViewExample
//
//  Created by YiLun Zhao on 2016-02-21.
//  Copyright © 2016 lkzhao. All rights reserved.
//

import UIKit

typealias TapHandler = (MCell)->Void

class MCell: UIView {
  var onTap:TapHandler?{
    didSet{
      if tapGR == nil {
        tapGR = UITapGestureRecognizer(target: self, action: #selector(tap))
        addGestureRecognizer(tapGR)
      }
    }
  }
  
  var tapAnimation = true
  var tapGR:UITapGestureRecognizer!
  
  var xyRotation:CGPoint = CGPointZero{
    didSet{
      layer.transform = makeTransform3D()
    }
  }
  var rotation:CGFloat = 0{
    didSet{
      layer.transform = makeTransform3D()
    }
  }
  var scale:CGFloat = 1{
    didSet{
      layer.transform = makeTransform3D()
    }
  }
  
  func makeTransform3D() -> CATransform3D{
    var t = CATransform3DIdentity
    t.m34 = 1.0 / -500;
    t = CATransform3DRotate(t, xyRotation.x, 1.0, 0, 0)
    t = CATransform3DRotate(t, xyRotation.y, 0, 1.0, 0)
    t = CATransform3DRotate(t, rotation, 0, 0, 1.0)
    let k = Float((abs(xyRotation.x) + abs(xyRotation.y)) / CGFloat(M_PI) / 1.5)
    layer.opacity = 1 - k
    return CATransform3DScale(t, scale, scale, 1.0)
  }
  
  var shadowColor:UIColor = UIColor(white:0.5, alpha:0.5){
    didSet{
      updateShadow()
    }
  }
  var showShadow:Bool = false{
    didSet{
      updateShadow()
    }
  }
  
  func updateShadow(){
    if showShadow {
      layer.shadowOffset = CGSizeMake(0, 5)
      layer.shadowOpacity = 0.3
      layer.shadowRadius = 8
      layer.shadowColor = shadowColor.CGColor
      layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: layer.cornerRadius).CGPath
    } else {
      layer.shadowOpacity = 0
    }
  }
  override init(frame: CGRect) {
    super.init(frame: frame)
    layer.shouldRasterize = true
    layer.rasterizationScale = UIScreen.mainScreen().scale
    opaque = true
    
    self.m_defineCustomProperty("scale", getter: { [weak self] values in
      self?.scale.toCGFloatValues(&values)
      }, setter:{ [weak self] values in
        self?.scale = values[0]
      })
    
    self.m_defineCustomProperty("xyRotation", getter: { [weak self] values in
      self?.xyRotation.toCGFloatValues(&values)
    }, setter:{ [weak self] values in
      self?.xyRotation = CGPoint.fromCGFloatValues(values)
    })

    self.m_addVelocityUpdateCallback("center") { [weak self] (v:CGPoint) in
      self?.velocityUpdated(v)
    }
  }
  
  var tilt3D = false{
    didSet{
      if tilt3D == false && xyRotation != CGPointZero{
        self.m_animate("xyRotation", to:CGPointZero, stiffness: 200, damping: 20, threshold: 0.001)
      }
    }
  }
  func velocityUpdated(velocity: CGPoint) {
    if tilt3D {
      let maxRotate = CGFloat(M_PI)/6
      let rotateX = -(velocity.y / 3000).clamp(-maxRotate,maxRotate)
      let rotateY = (velocity.x / 3000).clamp(-maxRotate,maxRotate)
      self.m_animate("xyRotation", to:CGPointMake(rotateX, rotateY), stiffness: 400, damping: 20, threshold: 0.001)
    }
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override var bounds: CGRect{
    didSet{
      if showShadow {
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: layer.cornerRadius).CGPath
      }
    }
  }
  
  func tap(){
    onTap?(self)
  }
  
  private(set) var holding = false
  override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
    super.touchesBegan(touches, withEvent: event)
    if let touch = touches.first where tapAnimation{
      var loc = touch.locationInView(self)
      loc = CGPointMake(loc.x.clamp(0, bounds.width), loc.y.clamp(0, bounds.height))
      loc = loc - bounds.center
      let rotation = CGPointMake(-loc.y / bounds.height, loc.x / bounds.width)
      if #available(iOS 9.0, *) {
        let force = touch.maximumPossibleForce == 0 ? 1 : touch.force
        self.m_animate("scale", to: 0.95 - force*0.01, stiffness: 150, damping: 7)
        self.m_animate("xyRotation", to: rotation * (0.21 + force * 0.04), stiffness: 150, damping: 7)
      } else {
        self.m_animate("scale", to: 0.94, stiffness: 150, damping: 7)
        self.m_animate("xyRotation", to: rotation * 0.25, stiffness: 150, damping: 7)
      }
    }
    holding = true
  }
  override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
    super.touchesMoved(touches, withEvent: event)
    if let touch = touches.first where tapAnimation {
      var loc = touch.locationInView(self)
      loc = CGPointMake(loc.x.clamp(0, bounds.width), loc.y.clamp(0, bounds.height))
      loc = loc - bounds.center
      let rotation = CGPointMake(-loc.y / bounds.height, loc.x / bounds.width)
      if #available(iOS 9.0, *) {
        let force = touch.maximumPossibleForce == 0 ? 1 : touch.force
        self.m_animate("scale", to: 0.95 - force * 0.01, stiffness: 150, damping: 7)
        self.m_animate("xyRotation", to: rotation * (0.21 + force * 0.04), stiffness: 150, damping: 7)
      } else {
        self.m_animate("xyRotation", to: rotation * 0.25, stiffness: 150, damping: 7)
      }
    }
  }
  override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
    super.touchesEnded(touches, withEvent: event)
    if tapAnimation {
      self.m_animate("scale", to: 1.0, stiffness: 150, damping: 7)
      self.m_animate("xyRotation", to: CGPointZero, stiffness: 150, damping: 7)
    }
    holding = false
  }
  override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
    super.touchesCancelled(touches, withEvent: event)
    if tapAnimation {
      self.m_animate("scale", to: 1.0, stiffness: 150, damping: 7)
      self.m_animate("xyRotation", to: CGPointZero, stiffness: 150, damping: 7)
    }
    holding = false
  }
}