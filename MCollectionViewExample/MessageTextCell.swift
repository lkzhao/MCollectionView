//
//  MessageTextCell.swift
//  MCollectionViewExample
//
//  Created by YiLun Zhao on 2016-02-20.
//  Copyright © 2016 lkzhao. All rights reserved.
//

import UIKit

enum MessageType{
  case Text
  case Announcement
  case Status
}
enum MessageAlignment{
  case Left
  case Center
  case Right
}
class Message {
  var fromCurrentUser = false
  var content = ""
  var type:MessageType

  init(_ fromCurrentUser:Bool, content:String){
    self.fromCurrentUser = fromCurrentUser
    self.type = .Text
    self.content = content
  }
  init(_ fromCurrentUser:Bool, status:String){
    self.fromCurrentUser = fromCurrentUser
    self.type = .Status
    self.content = status
  }
  init(announcement:String){
    self.type = .Announcement
    self.content = announcement
  }

  var fontSize:CGFloat{
    switch type{
    case .Text: return 14
    default: return 12
    }
  }
  var cellPadding:CGFloat{
    switch type{
    case .Announcement: return 4
    case .Text: return 15
    case .Status: return 2
    }
  }
  var roundedCornder:Bool{
    switch type{
    case .Announcement: return false
    default: return true
    }
  }
  var textColor:UIColor{
    switch type{
    case .Text:
      if fromCurrentUser {
        return UIColor.whiteColor()
      } else {
        return UIColor(red: 131/255, green: 138/255, blue: 147/255, alpha: 1.0)
      }
    default:
      return UIColor(red: 131/255, green: 138/255, blue: 147/255, alpha: 1.0)
    }
  }
  var alignment:MessageAlignment{
    switch type{
    case .Announcement: return .Center
    default: return fromCurrentUser ? .Right : .Left
    }
  }
  func verticalPaddingBetweenMessage(previousMessage:Message) -> CGFloat{
    if type == .Announcement{
      return 15
    }
    if previousMessage.type == .Announcement{
      return 5
    }
    if type == .Status{
      return 3
    }
    if type == .Text && type == previousMessage.type && fromCurrentUser == previousMessage.fromCurrentUser{
      return 5
    }
    return 15
  }
}

class MessageTextCell: MCell {
  var textLabel = UILabel()
  var message:Message!{
    didSet{
      
      textLabel.text = message.content
      textLabel.textColor = message.textColor
      textLabel.font = UIFont.systemFontOfSize(message.fontSize)
      
      layer.cornerRadius = message.roundedCornder ? 10 : 0
      
      if message.type == .Text {
        if showShadow{
          layer.shadowOffset = CGSizeMake(0, 5)
          layer.shadowOpacity = 0.3
          layer.shadowRadius = 8
          layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: layer.cornerRadius).CGPath
        } else {
          layer.shadowRadius = 0
        }
        if message.fromCurrentUser{
          backgroundColor = UIColor(red: 0, green: 94/255, blue: 1.0, alpha: 1.0)
          layer.shadowColor = UIColor(red: 0, green: 94/255, blue: 1.0, alpha: 1.0).CGColor
        } else {
          backgroundColor = UIColor(white: showShadow ? 1.0 : 0.95, alpha: 1.0)
          layer.shadowColor = UIColor(white: 0.8, alpha: 1.0).CGColor
        }
      } else {
        backgroundColor = nil
        layer.shadowColor = nil
        layer.shadowPath = nil
      }
    }
  }

  var showShadow:Bool{
    return kIsHighPerformanceDevice && message.type == .Text
  }
  var pressGR:UILongPressGestureRecognizer!
  override init(frame: CGRect) {
    super.init(frame: frame)
    identifier = "MessageTextCell"
    addSubview(textLabel)
    textLabel.frame = frame
    textLabel.numberOfLines = 0
    
    pressGR = UILongPressGestureRecognizer(target: self, action: "press")
    pressGR.delegate = self
    pressGR.minimumPressDuration = 0
    addGestureRecognizer(pressGR)
    self.m_defineCustomProperty("scale", initialValues: [1]) { (values) -> Void in
      self.transform = CGAffineTransformMakeScale(values[0], values[0])
    }
  }
  
  func press(){
    switch pressGR.state{
    case .Began:
      self.m_animate("scale", to: 0.9, damping: 10)
    case .Changed:
      break
    default:
      self.m_animate("scale", to: 1.0, damping: 10)
    }
  }

  required init?(coder aDecoder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
  }
  
  override func didUpdateOnScreenPosition(center: CGPoint, inContainer view:UIView) {
    if message.type == .Text && message.fromCurrentUser{
      let distanceFromTop = center.y
      let distanceFromBottom = view.bounds.height - distanceFromTop
      backgroundColor = UIColor(red: 0, green: (124+(distanceFromBottom/view.bounds.height*100))/255, blue: 1.0, alpha: 1.0)
    }
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    if showShadow {
      layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: layer.cornerRadius).CGPath
    }
    textLabel.frame = CGRectInset(bounds, message.cellPadding, message.cellPadding)
  }

  static func sizeForText(text:String, fontSize:CGFloat, maxWidth:CGFloat, padding:CGFloat) -> CGSize{
    let maxSize = CGSizeMake(maxWidth, 0)
    let font = UIFont.systemFontOfSize(fontSize)
    var rect = text.boundingRectWithSize(maxSize, options: .UsesLineFragmentOrigin , attributes: [ NSFontAttributeName : font ], context: nil)
    rect.size = CGSizeMake(ceil(rect.size.width) + 2 * padding, ceil(rect.size.height) + 2 * padding)
    return rect.size
  }
  
  static func frameForMessage(message:Message, yPosition:CGFloat, containerWidth:CGFloat) -> CGRect{
    if message.alignment == .Center{
      let size = sizeForText(message.content, fontSize: message.fontSize, maxWidth: containerWidth, padding: message.cellPadding)
      return CGRectMake((containerWidth - size.width)/2, yPosition, size.width, size.height)
    } else {
      let size = sizeForText(message.content, fontSize: message.fontSize, maxWidth: 200, padding: message.cellPadding)
      let origin = CGPointMake(message.alignment == .Right ? containerWidth - size.width - 10 : 10, yPosition)
      return CGRect(origin: origin, size: size)
    }
  }
}

extension MessageTextCell:UIGestureRecognizerDelegate{
  func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
    return true
  }
}
