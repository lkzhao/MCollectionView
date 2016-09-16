//
//  MCell.swift
//  MCollectionViewExample
//
//  Created by YiLun Zhao on 2016-02-21.
//  Copyright © 2016 lkzhao. All rights reserved.
//

import UIKit

public typealias TapHandler = (MCell)->Void

open class MCell: UIView {
  open var onTap:TapHandler?{
    didSet{
      if tapGR == nil {
        tapGR = UITapGestureRecognizer(target: self, action: #selector(tap))
        addGestureRecognizer(tapGR)
      }
    }
  }
  
  open var tapAnimation = true
  open var tapGR:UITapGestureRecognizer!
  
  open var tilt3D = false{
    didSet{
      if tilt3D == false && xyRotation != CGPoint.zero{
        self.m_animate("xyRotation", to:CGPoint.zero, stiffness: 200, damping: 20, threshold: 0.001)
      }
    }
  }

  open var xyRotation:CGPoint = CGPoint.zero{
    didSet{
      layer.transform = makeTransform3D()
    }
  }
  open var rotation:CGFloat = 0{
    didSet{
      layer.transform = makeTransform3D()
    }
  }
  open var scale:CGFloat = 1{
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
  
  open var shadowColor:UIColor = UIColor(white:0.5, alpha:0.5){
    didSet{
      updateShadow()
    }
  }
  open var showShadow:Bool = false{
    didSet{
      updateShadow()
    }
  }
  
  func updateShadow(){
    if showShadow {
      layer.shadowOffset = CGSize(width: 0, height: 5)
      layer.shadowOpacity = 0.3
      layer.shadowRadius = 8
      layer.shadowColor = shadowColor.cgColor
      layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: layer.cornerRadius).cgPath
    } else {
      layer.shadowOpacity = 0
    }
  }
  public override init(frame: CGRect) {
    super.init(frame: frame)
    layer.shouldRasterize = true
    layer.rasterizationScale = UIScreen.main.scale
    isOpaque = true
    
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
  
  func velocityUpdated(_ velocity: CGPoint) {
    if tilt3D {
      let maxRotate = CGFloat(M_PI)/6
      let rotateX = -(velocity.y / 3000).clamp(-maxRotate,maxRotate)
      let rotateY = (velocity.x / 3000).clamp(-maxRotate,maxRotate)
      self.m_animate("xyRotation", to:CGPoint(x: rotateX, y: rotateY), stiffness: 400, damping: 20, threshold: 0.001)
    }
  }
  
  public required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  open override var bounds: CGRect{
    didSet{
      if showShadow {
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: layer.cornerRadius).cgPath
      }
    }
  }
  
  func tap(){
    onTap?(self)
  }
  
  open fileprivate(set) var holding = false
  open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    super.touchesBegan(touches, with: event)
    if let touch = touches.first , tapAnimation{
      var loc = touch.location(in: self)
      loc = CGPoint(x: loc.x.clamp(0, bounds.width), y: loc.y.clamp(0, bounds.height))
      loc = loc - bounds.center
      let rotation = CGPoint(x: -loc.y / bounds.height, y: loc.x / bounds.width)
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
  open override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    super.touchesMoved(touches, with: event)
    if let touch = touches.first , tapAnimation {
      var loc = touch.location(in: self)
      loc = CGPoint(x: loc.x.clamp(0, bounds.width), y: loc.y.clamp(0, bounds.height))
      loc = loc - bounds.center
      let rotation = CGPoint(x: -loc.y / bounds.height, y: loc.x / bounds.width)
      if #available(iOS 9.0, *) {
        let force = touch.maximumPossibleForce == 0 ? 1 : touch.force
        self.m_animate("scale", to: 0.95 - force * 0.01, stiffness: 150, damping: 7)
        self.m_animate("xyRotation", to: rotation * (0.21 + force * 0.04), stiffness: 150, damping: 7)
      } else {
        self.m_animate("xyRotation", to: rotation * 0.25, stiffness: 150, damping: 7)
      }
    }
  }
  open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    super.touchesEnded(touches, with: event)
    if tapAnimation {
      self.m_animate("scale", to: 1.0, stiffness: 150, damping: 7)
      self.m_animate("xyRotation", to: CGPoint.zero, stiffness: 150, damping: 7)
    }
    holding = false
  }
  open override func touchesCancelled(_ touches: Set<UITouch>?, with event: UIEvent?) {
    super.touchesCancelled(touches!, with: event)
    if tapAnimation {
      self.m_animate("scale", to: 1.0, stiffness: 150, damping: 7)
      self.m_animate("xyRotation", to: CGPoint.zero, stiffness: 150, damping: 7)
    }
    holding = false
  }
}
