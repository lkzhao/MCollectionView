//
//  MessageTextCell.swift
//  MCollectionViewExample
//
//  Created by YiLun Zhao on 2016-02-20.
//  Copyright © 2016 lkzhao. All rights reserved.
//

import UIKit

class MessageTextCell: MCell {
  var textLabel = UILabel()
  var imageView:UIImageView?
  var message:Message!{
    didSet{
      textLabel.text = message.content
      textLabel.textColor = message.textColor
      textLabel.font = UIFont.systemFontOfSize(message.fontSize)
      
      layer.cornerRadius = message.roundedCornder ? 10 : 0
      
      imageView?.removeFromSuperview()
      if message.type == .Image{
        imageView = UIImageView(image: UIImage(named: message.content))
        imageView?.frame = bounds
        imageView?.contentMode = .ScaleAspectFill
        imageView?.clipsToBounds = true
        imageView?.layer.cornerRadius = layer.cornerRadius
        addSubview(imageView!)
      }else{
        imageView = nil
      }
      
      if showShadow{
        layer.shadowOffset = CGSizeMake(0, 5)
        layer.shadowOpacity = 0.3
        layer.shadowRadius = 8
        layer.shadowColor = UIColor(white: 0.6, alpha: 1.0).CGColor
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: layer.cornerRadius).CGPath
      } else {
        layer.shadowOpacity = 0
        backgroundColor = nil
      }

      if message.type == .Text {
        if message.fromCurrentUser{
          backgroundColor = UIColor(red: 0, green: 94/255, blue: 1.0, alpha: 1.0)
          layer.shadowColor = UIColor(red: 0, green: 94/255, blue: 1.0, alpha: 1.0).CGColor
        } else {
          backgroundColor = UIColor(white: showShadow ? 1.0 : 0.95, alpha: 1.0)
          layer.shadowColor = UIColor(white: 0.8, alpha: 1.0).CGColor
        }
      }
    }
  }

  var showShadow:Bool{
    return kIsHighPerformanceDevice && message.showShadow
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    identifier = "MessageTextCell"
    addSubview(textLabel)
    textLabel.frame = frame
    textLabel.numberOfLines = 0
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
    imageView?.frame = bounds
  }

  static func sizeForText(text:String, fontSize:CGFloat, maxWidth:CGFloat, padding:CGFloat) -> CGSize{
    let maxSize = CGSizeMake(maxWidth, 0)
    let font = UIFont.systemFontOfSize(fontSize)
    var rect = text.boundingRectWithSize(maxSize, options: .UsesLineFragmentOrigin , attributes: [ NSFontAttributeName : font ], context: nil)
    rect.size = CGSizeMake(ceil(rect.size.width) + 2 * padding, ceil(rect.size.height) + 2 * padding)
    return rect.size
  }
  
  static func frameForMessage(message:Message, containerWidth:CGFloat) -> CGRect{
    if message.type == .Image{
      var imageSize = UIImage(named: message.content)!.size
      let maxImageSize = CGSizeMake(CGFloat.max, 120)
      if imageSize.width > maxImageSize.width{
        imageSize.height /= imageSize.width/maxImageSize.width
        imageSize.width = maxImageSize.width
      }
      if imageSize.height > maxImageSize.height{
        imageSize.width /= imageSize.height/maxImageSize.height
        imageSize.height = maxImageSize.height
      }
      return CGRect(origin: CGPointMake(message.alignment == .Right ? containerWidth - imageSize.width : 0, 0), size: imageSize)
    }
    if message.alignment == .Center{
      let size = sizeForText(message.content, fontSize: message.fontSize, maxWidth: containerWidth, padding: message.cellPadding)
      return CGRectMake((containerWidth - size.width)/2, 0, size.width, size.height)
    } else {
      let size = sizeForText(message.content, fontSize: message.fontSize, maxWidth: 200, padding: message.cellPadding)
      let origin = CGPointMake(message.alignment == .Right ? containerWidth - size.width : 0, 0)
      return CGRect(origin: origin, size: size)
    }
  }
}