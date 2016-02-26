//
//  TestData.swift
//  MCollectionViewExample
//
//  Created by YiLun Zhao on 2016-02-23.
//  Copyright © 2016 lkzhao. All rights reserved.
//

import UIKit

enum MessageType{
  case Text
  case Announcement
  case Status
  case Image
}
enum MessageAlignment{
  case Left
  case Center
  case Right
}
class Message {
  var identifier:String = NSUUID().UUIDString
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
  init(_ fromCurrentUser:Bool, image:String){
    self.fromCurrentUser = fromCurrentUser
    self.type = .Image
    self.content = image
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
    case .Image: return 0
    }
  }
  var showShadow:Bool{
    switch type{
    case .Text: return true
    case .Image: return true
    default: return false
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
    default: return (fromCurrentUser ? .Right : .Left)
    }
  }

  func verticalPaddingBetweenMessage(previousMessage:Message) -> CGFloat{
    if type == .Image && previousMessage.type == .Image{
      return 2
    }
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

let TestMessages = [
  Message(announcement: "MCollectionView"),
  Message(true, content: "Test Content"),
  Message(true, content: "Test Content"),
  Message(false, content: "Test Content"),
  Message(true, content: "Test Content"),
  Message(false, content: "Test Content"),
  Message(false, content: "Test Content"),
  Message(false, content: "Test Content"),
  Message(true, content: "Test Content"),
  Message(true, content: "Test Content"),
  Message(true, content: "Test Content"),
  Message(true, content: "Test Content"),
  Message(false, content: "Test Content"),
  Message(true, content: "Test Content"),
  Message(false, content: "Test Content"),
  Message(false, content: "Test Content"),
  Message(false, content: "Test Content"),
  Message(true, content: "Test Content"),
  Message(true, content: "Test Content"),
  Message(true, content: "Test Content"),
  Message(true, content: "Test Content"),
  Message(false, content: "Test Content"),
  Message(announcement: "June 9th 11:30 PM"),
  Message(true, content: "Test Content"),
  Message(false, content: "Test Content"),
  Message(false, content: "Test Content"),
  Message(false, content: "Test Content"),
  Message(true, content: "Test Content"),
  Message(true, content: "Test Content"),
  Message(true, content: "Test Content"),
  Message(true, content: "Test Content"),
  Message(false, content: "Test Content"),
  Message(true, content: "Test Content"),
  Message(false, content: "Test Content"),
  Message(false, content: "Test Content"),
  Message(false, content: "Test Content"),
  Message(true, content: "Test Content"),
  Message(true, content: "Test Content"),
  Message(true, content: "Test Content"),
  Message(false, content: "Test Content"),
  Message(false, content: "Test Content"),
  Message(false, content: "Test Content"),
  Message(true, content: "Test Content"),
  Message(true, content: "Test Content"),
  Message(true, content: "Test Content"),
  Message(true, content: "Test Content"),
  Message(announcement: "Yesterday 11:30 PM"),
  Message(false, content: "Test Content"),
  Message(true, content: "Test Content"),
  Message(false, content: "Test Content"),
  Message(false, content: "Test Content"),
  Message(false, content: "Test Content"),
  Message(true, content: "Test Content"),
  Message(true, content: "Test Content"),
  Message(true, content: "Test Content"),
  Message(true, content: "Test Content"),
  Message(false, content: "Test Content"),
  Message(true, content: "Test Content"),
  Message(announcement: "Today 9:30 AM"),
  Message(true, image: "l1"),
  Message(true, image: "l2"),
  Message(true, image: "l3"),
  Message(true, content: "Test ContentTest Content"),
  Message(true, content: "Test ContentTest ContentTest ContentTest Content"),
  Message(false, content: "Test Content"),
  Message(true, content: "Test Content"),
  Message(false, content: "Test Content"),
  Message(false, content: "Test ContentTest ContentTest ContentTest ContentTest ContentTest ContentTest ContentTest ContentTest ContentTest ContentTest ContentTest Content"),
  Message(false, content: "Test Content"),
  Message(false, image: "1"),
  Message(false, image: "2"),
  Message(false, image: "3"),
  Message(false, image: "4"),
  Message(false, image: "5"),
  Message(false, image: "6"),
  Message(true, content: "Test Content"),
  Message(false, content: "Test Content"),
  Message(false, content: "Test ContentTest ContentTest ContentTest ContentTest Content"),
  Message(false, content: "Test Content"),
  Message(true, content: "Test Content"),
  Message(true, content: "Test Content"),
  Message(true, content: "Test ContentTest ContentTest ContentTest ContentTest Content"),
  Message(true, status: "Delivered"),
]
