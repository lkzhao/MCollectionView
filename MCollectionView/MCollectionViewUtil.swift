//
//  MCollectionViewUtil.swift
//  MCollectionView
//
//  Created by YiLun Zhao on 2016-01-17.
//  Copyright © 2016 lkzhao. All rights reserved.
//

import UIKit

public extension CGFloat {
  func clamp(_ a: CGFloat, _ b: CGFloat) -> CGFloat {
    return self < a ? a : (self > b ? b : self)
  }
}

public extension CGPoint {
  func translate(_ dx: CGFloat, dy: CGFloat) -> CGPoint {
    return CGPoint(x: self.x+dx, y: self.y+dy)
  }

  func transform(_ t: CGAffineTransform) -> CGPoint {
    return self.applying(t)
  }

  func distance(_ b: CGPoint) -> CGFloat {
    return sqrt(pow(self.x-b.x, 2)+pow(self.y-b.y, 2))
  }
}
public func +(left: CGPoint, right: CGPoint) -> CGPoint {
  return CGPoint(x: left.x + right.x, y: left.y + right.y)
}
public func -(left: CGPoint, right: CGPoint) -> CGPoint {
  return CGPoint(x: left.x - right.x, y: left.y - right.y)
}
public func /(left: CGPoint, right: CGFloat) -> CGPoint {
  return CGPoint(x: left.x/right, y: left.y/right)
}
public func *(left: CGPoint, right: CGFloat) -> CGPoint {
  return CGPoint(x: left.x*right, y: left.y*right)
}
public func *(left: CGFloat, right: CGPoint) -> CGPoint {
  return right * left
}
public func *(left: CGPoint, right: CGPoint) -> CGPoint {
  return CGPoint(x: left.x*right.x, y: left.y*right.y)
}
public prefix func -(point: CGPoint) -> CGPoint {
  return CGPoint.zero - point
}
public func /(left: CGSize, right: CGFloat) -> CGSize {
  return CGSize(width: left.width/right, height: left.height/right)
}
public func -(left: CGPoint, right: CGSize) -> CGPoint {
  return CGPoint(x: left.x - right.width, y: left.y - right.height)
}

public prefix func -(inset: UIEdgeInsets) -> UIEdgeInsets {
  return UIEdgeInsets(top: -inset.top, left: -inset.left, bottom: -inset.bottom, right: -inset.right)
}

public extension CGRect {
  var leftEdgeValue: CGFloat {
    return origin.x
  }
  var rightEdgeValue: CGFloat {
    return origin.x + size.width
  }
  var topEdgeValue: CGFloat {
    return origin.y
  }
  var bottomEdgeValue: CGFloat {
    return origin.y + size.height
  }
  var edges: UIEdgeInsets {
    return UIEdgeInsets(top: topEdgeValue, left: leftEdgeValue, bottom: bottomEdgeValue, right: rightEdgeValue)
  }
  var center: CGPoint {
    return CGPoint(x: origin.x + size.width/2, y: origin.y + size.height/2)
  }
  var bounds: CGRect {
    return CGRect(origin: CGPoint.zero, size: size)
  }
  init(center: CGPoint, size: CGSize) {
    self.origin = center - size / 2
    self.size = size
  }
}

public func delay(_ delay: Double, closure:@escaping ()->Void) {
  DispatchQueue.main.asyncAfter(
    deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
}

//
//  https://gist.github.com/CanTheAlmighty/70b3bf66eb1f2a5cee28
//

struct DictionaryTwoWay<S:Hashable, T:Hashable> : ExpressibleByDictionaryLiteral {
  // Literal convertible
  typealias Key   = S
  typealias Value = T

  // Real storage
  var st: [S : T] = [:]
  var ts: [T : S] = [:]

  init(leftRight st: [S:T]) {
    var ts: [T:S] = [:]

    for (key, value) in st {
      ts[value] = key
    }

    self.st = st
    self.ts = ts
  }

  init(rightLeft ts: [T:S]) {
    var st: [S:T] = [:]

    for (key, value) in ts {
      st[value] = key
    }

    self.st = st
    self.ts = ts
  }

  init(dictionaryLiteral elements: (Key, Value)...) {
    for element in elements {
      st[element.0] = element.1
      ts[element.1] = element.0
    }
  }

  init() { }

  subscript(key: S) -> T? {
    get {
      return st[key]
    }

    set(val) {
      if let val = val {
        st[key] = val
        ts[val] = key
      }
    }
  }

  subscript(key: T) -> S? {
    get {
      return ts[key]
    }

    set(val) {
      if let val = val {
        ts[key] = val
        st[val] = key
      }
    }
  }

  mutating func remove(_ key: S) {
    if let item = st.removeValue(forKey: key) {
      ts.removeValue(forKey: item)
    }
  }
  mutating func remove(_ key: T) {
    if let item = ts.removeValue(forKey: key) {
      st.removeValue(forKey: item)
    }
  }
}
