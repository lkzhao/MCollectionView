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

import UIKit

public extension UIDevice {
  
  var modelName: String {
    var systemInfo = utsname()
    uname(&systemInfo)
    let machineMirror = Mirror(reflecting: systemInfo.machine)
    let identifier = machineMirror.children.reduce("") { identifier, element in
      guard let value = element.value as? Int8 where value != 0 else { return identifier }
      return identifier + String(UnicodeScalar(UInt8(value)))
    }
    
    switch identifier {
    case "iPod5,1":                                 return "iPod Touch 5"
    case "iPod7,1":                                 return "iPod Touch 6"
    case "iPhone3,1", "iPhone3,2", "iPhone3,3":     return "iPhone 4"
    case "iPhone4,1":                               return "iPhone 4s"
    case "iPhone5,1", "iPhone5,2":                  return "iPhone 5"
    case "iPhone5,3", "iPhone5,4":                  return "iPhone 5c"
    case "iPhone6,1", "iPhone6,2":                  return "iPhone 5s"
    case "iPhone7,2":                               return "iPhone 6"
    case "iPhone7,1":                               return "iPhone 6 Plus"
    case "iPhone8,1":                               return "iPhone 6s"
    case "iPhone8,2":                               return "iPhone 6s Plus"
    case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4":return "iPad 2"
    case "iPad3,1", "iPad3,2", "iPad3,3":           return "iPad 3"
    case "iPad3,4", "iPad3,5", "iPad3,6":           return "iPad 4"
    case "iPad4,1", "iPad4,2", "iPad4,3":           return "iPad Air"
    case "iPad5,3", "iPad5,4":                      return "iPad Air 2"
    case "iPad2,5", "iPad2,6", "iPad2,7":           return "iPad Mini"
    case "iPad4,4", "iPad4,5", "iPad4,6":           return "iPad Mini 2"
    case "iPad4,7", "iPad4,8", "iPad4,9":           return "iPad Mini 3"
    case "iPad5,1", "iPad5,2":                      return "iPad Mini 4"
    case "iPad6,7", "iPad6,8":                      return "iPad Pro"
    case "AppleTV5,3":                              return "Apple TV"
    case "i386", "x86_64":                          return "Simulator"
    default:                                        return identifier
    }
  }

}

func isHighPerformance() -> Bool{
  switch UIDevice().modelName{
  case "iPhone 6s", "iPhone 6s Plus", "iPhone 6", "iPhone 6 Plus":
    return true
  default:
    return true
  }
}

let kIsHighPerformanceDevice = isHighPerformance()