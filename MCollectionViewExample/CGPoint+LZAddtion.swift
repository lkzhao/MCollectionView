//
//  CGPoint+Util.swift
//  DynamicView
//
//  Created by YiLun Zhao on 2016-01-17.
//  Copyright © 2016 lkzhao. All rights reserved.
//

import UIKit

extension CGFloat{
  func clamp(a:CGFloat, _ b:CGFloat) -> CGFloat{
    return self < a ? a : (self > b ? b : self)
  }
}

extension CGPoint{
  func translate(dx:CGFloat, dy:CGFloat) -> CGPoint{
    return CGPointMake(self.x+dx, self.y+dy)
  }
  
  func transform(t:CGAffineTransform) -> CGPoint{
    return CGPointApplyAffineTransform(self, t)
  }
  
  func distance(b:CGPoint)->CGFloat{
    return sqrt(pow(self.x-b.x,2)+pow(self.y-b.y,2));
  }
}
func +(left: CGPoint, right: CGPoint) -> CGPoint {
  return CGPointMake(left.x + right.x, left.y + right.y)
}
func -(left: CGPoint, right: CGPoint) -> CGPoint {
  return CGPointMake(left.x - right.x, left.y - right.y)
}
func /(left: CGPoint, right: CGFloat) -> CGPoint {
  return CGPointMake(left.x/right, left.y/right)
}
func *(left: CGPoint, right: CGFloat) -> CGPoint {
  return CGPointMake(left.x*right, left.y*right)
}
func *(left: CGFloat, right: CGPoint) -> CGPoint {
  return right * left
}
func *(left: CGPoint, right: CGPoint) -> CGPoint {
  return CGPointMake(left.x*right.x, left.y*right.y)
}
prefix func -(point:CGPoint) -> CGPoint {
  return CGPointZero - point
}

extension CGRect{
  var leftEdgeValue:CGFloat{
    return origin.x
  }
  var rightEdgeValue:CGFloat{
    return origin.x + size.width
  }
  var topEdgeValue:CGFloat{
    return origin.y
  }
  var bottomEdgeValue:CGFloat{
    return origin.y + size.height
  }
  var edges:UIEdgeInsets{
    return UIEdgeInsetsMake(topEdgeValue, leftEdgeValue, bottomEdgeValue, rightEdgeValue)
  }
  var center:CGPoint{
    return CGPointMake(origin.x + size.width/2, origin.y + size.height/2)
  }
  var bounds:CGRect{
    return CGRect(origin: CGPointZero, size: size)
  }
}


