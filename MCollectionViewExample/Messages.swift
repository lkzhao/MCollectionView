//
//  Messages.swift
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
  
  var backgroundColor:UIColor{
    switch type{
    case .Text:
      if fromCurrentUser {
        return UIColor(red: 0, green: 184/255, blue: 1.0, alpha: 1.0)
      } else {
        return UIColor(white: showShadow ? 1.0 : 0.95, alpha: 1.0)
      }
    default:
      return UIColor.clearColor()
    }
  }
  var shadowColor:UIColor{
    switch type{
    case .Text:
      if fromCurrentUser {
        return UIColor(red: 0, green: 94/255, blue: 1.0, alpha: 1.0)
      } else {
        return UIColor(white: 0.8, alpha: 1.0)
      }
    default:
      return UIColor.clearColor()
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

let TestMessages = [
  Message(announcement: "MCollectionView"),
  Message(true, content: "Chat Example"),
  Message(false, content: "Lorem Ipsum"),
  Message(false, content: "This is an advance example demostrating what MCollectionView can do."),
  Message(false, content: "Checkout the source code to see how "),
  Message(false, content: "Test Content"),
  Message(true, content: "Test Content"),
  Message(true, content: "Test Content"),
  Message(false, content: "Nulla fringilla, dolor id congue elementum, urna diam rhoncus eros, sit amet hendrerit turpis velit eget nisl."),
  Message(false, content: "Quisque nulla sapien, dignissim ac risus nec, vehicula commodo lectus. Suspendisse lacinia mi sit amet nulla semper sollicitudin."),
  Message(true, content: "Test Content"),
  Message(announcement: "Today 9:30 AM"),
  Message(true, image: "l1"),
  Message(true, image: "l2"),
  Message(true, image: "l3"),
  Message(true, content: "Suspendisse ut turpis."),
  Message(true, content: "velit."),
  Message(false, content: "Suspendisse ut turpis velit."),
  Message(true, content: "Nullam placerat rhoncus erat ut placerat."),
  Message(false, content: "Fusce cursus metus viverra erat viverra, sed efficitur magna consequat. Ut tristique magna et sapien euismod, consequat maximus ipsum varius."),
  Message(false, content: "Nulla mattis odio a tortor fringilla pulvinar. Curabitur laoreet, velit nec malesuada finibus, massa arcu aliquam ex, a interdum justo massa eget erat. Curabitur facilisis molestie arcu id porta. Phasellus commodo rutrum mi a elementum. Etiam vestibulum volutpat sem, tincidunt auctor elit lobortis in. Pellentesque pellentesque tortor lectus, sed cursus augue porta vitae. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus."),
  Message(false, content: "Test Content"),
  Message(true, content: "Test Content"),
  Message(false, content: "In bibendum nisl at arcu mollis volutpat vitae eu urna. Mauris sodales iaculis lorem, nec rutrum dui ullamcorper nec. Fusce nibh dolor, mollis ac efficitur condimentum, vulputate eget erat. Sed molestie neque eu blandit placerat. Fusce nec sagittis nulla. Sed aliquam elit sollicitudin egestas convallis. Vestibulum vel sem vel lectus porta tempus. Curabitur semper in nulla id lacinia. Sed consequat massa nisi, sed egestas quam facilisis id."),
  Message(false, image: "1"),
  Message(false, image: "2"),
  Message(false, image: "3"),
  Message(false, image: "4"),
  Message(false, image: "5"),
  Message(false, image: "6"),
  Message(true, content: "Etiam a leo nibh. Fusce cursus metus viverra erat viverra, sed efficitur magna consequat. Ut tristique magna et sapien euismod, consequat maximus ipsum varius."),
  Message(false, content: "Cras sollicitudin porta ligula id congue. Nulla facilisi. Morbi blandit nisl sed elit blandit pretium. Aliquam erat volutpat."),
  Message(true, content: "Suspendisse ut turpis."),
  Message(true, content: "velit."),
  Message(false, content: "Suspendisse ut turpis velit."),
  Message(true, content: "Vivamus et fermentum diam. Suspendisse vitae tempor lectus."),
  Message(true, content: "Duis eros eros"),
  Message(true, content: "You can also drag and drop these message cells to reorder them! 😄"),
  Message(true, status: "Delivered"),
]
