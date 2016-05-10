//
//  MessageTextCell.swift
//  MCollectionViewExample
//
//  Created by YiLun Zhao on 2016-02-20.
//  Copyright © 2016 lkzhao. All rights reserved.
//

import UIKit

protocol MessageTextCellDelegate{
  func messageCellDidTap(cell:MessageTextCell)
  func messageCellDidBeginHolding(cell:MessageTextCell, gestureRecognizer:UILongPressGestureRecognizer)
  func messageCellDidMoveWhileHolding(cell:MessageTextCell, gestureRecognizer:UILongPressGestureRecognizer)
  func messageCellDidEndHolding(cell:MessageTextCell, gestureRecognizer:UILongPressGestureRecognizer)
}

class MessageTextCell: MCell {
  
  var delegate:MessageTextCellDelegate?
  
  var textLabel = UILabel()
  var imageView:UIImageView?
  var pressGR:UILongPressGestureRecognizer!

  var message:Message!{
    didSet{
      textLabel.text = message.content
      textLabel.textColor = message.textColor
      textLabel.font = UIFont.systemFontOfSize(message.fontSize)
      
      layer.cornerRadius = message.roundedCornder ? 10 : 0
      
      if message.type == .Image{
        imageView = imageView ?? UIImageView()
        imageView?.image = UIImage(named: message.content)
        imageView?.frame = bounds
        imageView?.contentMode = .ScaleAspectFill
        imageView?.clipsToBounds = true
        imageView?.layer.cornerRadius = layer.cornerRadius
        addSubview(imageView!)
      }else{
        imageView?.removeFromSuperview()
        imageView = nil
      }
      
      if message.showShadow{
        layer.shadowOffset = CGSizeMake(0, 5)
        layer.shadowOpacity = 0.3
        layer.shadowRadius = 8
        layer.shadowColor = UIColor(white: 0.6, alpha: 1.0).CGColor
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: layer.cornerRadius).CGPath
      } else {
        layer.shadowOpacity = 0
        layer.shadowColor = nil
      }
      
      layer.shadowColor = message.shadowColor.CGColor
      backgroundColor = message.backgroundColor
    }
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    addSubview(textLabel)
    textLabel.frame = frame
    textLabel.numberOfLines = 0
    layer.shouldRasterize = true;
    layer.rasterizationScale = UIScreen.mainScreen().scale;
    opaque = true

    pressGR = UILongPressGestureRecognizer(target: self, action: #selector(press))
    pressGR.delegate = self
    pressGR.minimumPressDuration = 0.5
    addGestureRecognizer(pressGR)
    
//    self.m_addVelocityUpdateCallback("center", velocityUpdateCallback: CGPointObserver({ [weak self] velocity in
//      self?.velocityUpdated(velocity)
//      }))
  }
  
  func press(){
    switch pressGR.state{
    case .Began:
      tapAnimation = false
      self.m_animate("scale", to: 1.1)
      self.m_animate("xyRotation", to: CGPointZero, stiffness: 150, damping: 7)
      delegate?.messageCellDidBeginHolding(self, gestureRecognizer: pressGR)
      break
    case .Changed:
      delegate?.messageCellDidMoveWhileHolding(self, gestureRecognizer: pressGR)
      break
    default:
      self.m_animate("scale", to: 1.0)
      delegate?.messageCellDidEndHolding(self, gestureRecognizer: pressGR)
      tapAnimation = true
    }
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    if message?.showShadow ?? false {
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
      let size = sizeForText(message.content, fontSize: message.fontSize, maxWidth: containerWidth - 2*message.cellPadding, padding: message.cellPadding)
      let origin = CGPointMake(message.alignment == .Right ? containerWidth - size.width : 0, 0)
      return CGRect(origin: origin, size: size)
    }
  }
}


extension MessageTextCell:UIGestureRecognizerDelegate{
  override func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
    if gestureRecognizer == self.pressGR{
      return self.delegate != nil
    }
    return super.gestureRecognizerShouldBegin(gestureRecognizer)
  }
}