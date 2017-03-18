//
//  MessageTextCell.swift
//  MCollectionViewExample
//
//  Created by YiLun Zhao on 2016-02-20.
//  Copyright © 2016 lkzhao. All rights reserved.
//

import UIKit

protocol MessageTextCellDelegate {
  func messageCellDidTap(_ cell: MessageTextCell)
  func messageCellDidBeginHolding(_ cell: MessageTextCell, gestureRecognizer: UILongPressGestureRecognizer)
  func messageCellDidMoveWhileHolding(_ cell: MessageTextCell, gestureRecognizer: UILongPressGestureRecognizer)
  func messageCellDidEndHolding(_ cell: MessageTextCell, gestureRecognizer: UILongPressGestureRecognizer)
}

class MessageTextCell: MCell {

  var delegate: MessageTextCellDelegate?

  var textLabel = UILabel()
  var imageView: UIImageView?
  var pressGR: UILongPressGestureRecognizer!

  var message: Message! {
    didSet {
      textLabel.text = message.content
      textLabel.textColor = message.textColor
      textLabel.font = UIFont.systemFont(ofSize: message.fontSize)

      layer.cornerRadius = message.roundedCornder ? 10 : 0

      if message.type == .image {
        imageView = imageView ?? UIImageView()
        imageView?.image = UIImage(named: message.content)
        imageView?.frame = bounds
        imageView?.contentMode = .scaleAspectFill
        imageView?.clipsToBounds = true
        imageView?.layer.cornerRadius = layer.cornerRadius
        addSubview(imageView!)
      } else {
        imageView?.removeFromSuperview()
        imageView = nil
      }

      if message.showShadow {
        layer.shadowOffset = CGSize(width: 0, height: 5)
        layer.shadowOpacity = 0.3
        layer.shadowRadius = 8
        layer.shadowColor = UIColor(white: 0.6, alpha: 1.0).cgColor
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: layer.cornerRadius).cgPath
      } else {
        layer.shadowOpacity = 0
        layer.shadowColor = nil
      }

      layer.shadowColor = message.shadowColor.cgColor
      backgroundColor = message.backgroundColor
    }
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    addSubview(textLabel)
    textLabel.frame = frame
    textLabel.numberOfLines = 0
    layer.shouldRasterize = true
    layer.rasterizationScale = UIScreen.main.scale
    isOpaque = true

    pressGR = UILongPressGestureRecognizer(target: self, action: #selector(press))
    pressGR.delegate = self
    pressGR.minimumPressDuration = 0.5
    addGestureRecognizer(pressGR)

//    self.m_addVelocityUpdateCallback("center", velocityUpdateCallback: CGPointObserver({ [weak self] velocity in
//      self?.velocityUpdated(velocity)
//      }))
  }

  func press() {
    switch pressGR.state {
    case .began:
      tapAnimation = false
      self.m_animate("scale", to: 1.1)
      self.m_animate("xyRotation", to: CGPoint.zero, stiffness: 150, damping: 7)
      delegate?.messageCellDidBeginHolding(self, gestureRecognizer: pressGR)
      break
    case .changed:
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
      layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: layer.cornerRadius).cgPath
    }
    textLabel.frame = bounds.insetBy(dx: message.cellPadding, dy: message.cellPadding)
    imageView?.frame = bounds
  }

  static func sizeForText(_ text: String, fontSize: CGFloat, maxWidth: CGFloat, padding: CGFloat) -> CGSize {
    let maxSize = CGSize(width: maxWidth, height: 0)
    let font = UIFont.systemFont(ofSize: fontSize)
    var rect = text.boundingRect(with: maxSize, options: .usesLineFragmentOrigin, attributes: [ NSFontAttributeName: font ], context: nil)
    rect.size = CGSize(width: ceil(rect.size.width) + 2 * padding, height: ceil(rect.size.height) + 2 * padding)
    return rect.size
  }

  static func frameForMessage(_ message: Message, containerWidth: CGFloat) -> CGRect {
    if message.type == .image {
      var imageSize = UIImage(named: message.content)!.size
      let maxImageSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: 120)
      if imageSize.width > maxImageSize.width {
        imageSize.height /= imageSize.width/maxImageSize.width
        imageSize.width = maxImageSize.width
      }
      if imageSize.height > maxImageSize.height {
        imageSize.width /= imageSize.height/maxImageSize.height
        imageSize.height = maxImageSize.height
      }
      return CGRect(origin: CGPoint(x: message.alignment == .right ? containerWidth - imageSize.width : 0, y: 0), size: imageSize)
    }
    if message.alignment == .center {
      let size = sizeForText(message.content, fontSize: message.fontSize, maxWidth: containerWidth, padding: message.cellPadding)
      return CGRect(x: (containerWidth - size.width)/2, y: 0, width: size.width, height: size.height)
    } else {
      let size = sizeForText(message.content, fontSize: message.fontSize, maxWidth: containerWidth - 2*message.cellPadding, padding: message.cellPadding)
      let origin = CGPoint(x: message.alignment == .right ? containerWidth - size.width : 0, y: 0)
      return CGRect(origin: origin, size: size)
    }
  }
}

extension MessageTextCell:UIGestureRecognizerDelegate {
  override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    if gestureRecognizer == self.pressGR {
      return self.delegate != nil
    }
    return super.gestureRecognizerShouldBegin(gestureRecognizer)
  }
}
