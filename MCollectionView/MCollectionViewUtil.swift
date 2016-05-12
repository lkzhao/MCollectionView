//
//  MCollectionViewUtil.swift
//  MCollectionView
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


func delay(delay:Double, closure:()->()) {
  dispatch_after(
    dispatch_time(
      DISPATCH_TIME_NOW,
      Int64(delay * Double(NSEC_PER_SEC))
    ),
    dispatch_get_main_queue(), closure)
}


//
//  https://gist.github.com/CanTheAlmighty/70b3bf66eb1f2a5cee28
//

struct DictionaryTwoWay<S:Hashable,T:Hashable> : DictionaryLiteralConvertible
{
  // Literal convertible
  typealias Key   = S
  typealias Value = T
  
  // Real storage
  var st : [S : T] = [:]
  var ts : [T : S] = [:]
  
  init(leftRight st : [S:T])
  {
    var ts : [T:S] = [:]
    
    for (key,value) in st
    {
      ts[value] = key
    }
    
    self.st = st
    self.ts = ts
  }
  
  init(rightLeft ts : [T:S])
  {
    var st : [S:T] = [:]
    
    for (key,value) in ts
    {
      st[value] = key
    }
    
    self.st = st
    self.ts = ts
  }
  
  init(dictionaryLiteral elements: (Key, Value)...)
  {
    for element in elements
    {
      st[element.0] = element.1
      ts[element.1] = element.0
    }
  }
  
  init() { }
  
  subscript(key : S) -> T?
    {
    get
    {
      return st[key]
    }
    
    set(val)
    {
      if let val = val
      {
        st[key] = val
        ts[val] = key
      }
    }
  }
  
  subscript(key : T) -> S?
    {
    get
    {
      return ts[key]
    }
    
    set(val)
    {
      if let val = val
      {
        ts[key] = val
        st[val] = key
      }
    }
  }
  
  mutating func remove(key: S) {
    if let item = st.removeValueForKey(key){
      ts.removeValueForKey(item)
    }
  }
  mutating func remove(key: T) {
    if let item = ts.removeValueForKey(key){
      st.removeValueForKey(item)
    }
  }
}
