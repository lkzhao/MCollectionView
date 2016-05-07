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

  func copy() -> Message {
    switch type {
    case .Image:
      return Message(fromCurrentUser, image: content)
    case .Announcement:
      return Message(announcement: content)
    case .Text:
      return Message(fromCurrentUser, content: content)
    case .Status:
      return Message(fromCurrentUser, status: content)
    }
  }
}

let TestDiaryMessages = [
  Message(false, content: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vivamus accumsan bibendum tortor, vel ornare magna malesuada vel. Donec a nisi sed enim blandit molestie. Aenean imperdiet libero in purus hendrerit, tempor mollis augue venenatis. Morbi in ultricies nunc, hendrerit malesuada nulla. Nullam porta commodo vestibulum. Ut at tincidunt velit. Ut vel cursus nibh."),
  Message(false, content: "Etiam lacinia velit sit amet mattis imperdiet. Vestibulum mattis malesuada ipsum. Aliquam fermentum elit id lectus mollis, sed lacinia lectus fringilla. Proin consequat, massa a mattis vulputate, turpis est lobortis felis, ut vehicula ipsum felis vel lorem. In imperdiet elementum velit ut eleifend. Vivamus tempor elit a dolor gravida semper. Integer imperdiet turpis vitae mauris interdum, non aliquam dui dictum."),
  Message(false, image: "1"),
  Message(false, image: "2"),
  Message(false, image: "3"),
  Message(false, image: "4"),
  Message(false, image: "5"),
  Message(false, image: "6"),
]
let TestMessages = [
//  Message(announcement: "MCollectionView"),
//  Message(true, content: "Test Content"),
//  Message(true, content: "Test Content"),
//  Message(false, content: "Test Content"),
//  Message(true, content: "Test Content"),
//  Message(false, content: "Test Content"),
//  Message(false, content: "Test Content"),
//  Message(false, content: "Test Content"),
//  Message(true, content: "Test Content"),
//  Message(true, content: "Test Content"),
//  Message(true, content: "Test Content"),
//  Message(true, content: "Test Content"),
//  Message(false, content: "Test Content"),
//  Message(true, content: "Test Content"),
//  Message(false, content: "Test Content"),
//  Message(false, content: "Test Content"),
//  Message(false, content: "Test Content"),
//  Message(true, content: "Test Content"),
//  Message(true, content: "Test Content"),
//  Message(true, content: "Test Content"),
//  Message(true, content: "Test Content"),
//  Message(false, content: "Test Content"),
//  Message(announcement: "June 9th 11:30 PM"),
//  Message(true, content: "Test Content"),
//  Message(false, content: "Test Content"),
//  Message(false, content: "Test Content"),
//  Message(false, content: "Test Content"),
//  Message(true, content: "Test Content"),
//  Message(true, content: "Test Content"),
//  Message(true, content: "Test Content"),
//  Message(true, content: "Test Content"),
//  Message(false, content: "Test Content"),
//  Message(true, content: "Test Content"),
//  Message(false, content: "Test Content"),
//  Message(false, content: "Test Content"),
//  Message(false, content: "Test Content"),
//  Message(true, content: "Test Content"),
//  Message(true, content: "Test Content"),
//  Message(true, content: "Test Content"),
//  Message(false, content: "Test Content"),
//  Message(false, content: "Test Content"),
//  Message(false, content: "Test Content"),
//  Message(true, content: "Test Content"),
//  Message(true, content: "Test Content"),
//  Message(true, content: "Test Content"),
//  Message(true, content: "Test Content"),
//  Message(announcement: "Yesterday 11:30 PM"),
//  Message(false, content: "Test Content"),
//  Message(true, content: "Test Content"),
//  Message(false, content: "Test Content"),
//  Message(false, content: "Test Content"),
//  Message(false, content: "Test Content"),
//  Message(true, content: "Test Content"),
//  Message(true, content: "Test Content"),
//  Message(true, content: "Test Content"),
//  Message(true, content: "Test Content"),
//  Message(false, content: "Test Content"),
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
