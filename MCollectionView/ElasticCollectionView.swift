//
//  Elasticswift
//  MCollectionViewExample
//
//  Created by YiLun Zhao on 2016-02-21.
//  Copyright © 2016 lkzhao. All rights reserved.
//

import UIKit

enum ElasticDirection{
  case Vertical, Horizontal, Both
}
class ElasticCollectionView: MCollectionView {
  var direction:ElasticDirection = .Both
  func adjustedRect(index:Int) -> CGRect{
    let screenDragLocation = contentOffset + dragLocation
    let cellFrame = frames[index]
    let cellOffset:CGPoint
    switch direction{
    case .Vertical:
      cellOffset = abs(cellFrame.center.y - screenDragLocation.y) * scrollVelocity / 5000
    case .Horizontal:
      cellOffset = abs(cellFrame.center.x - screenDragLocation.x) * scrollVelocity / 5000
    case .Both:
      cellOffset = cellFrame.center.distance(screenDragLocation) * scrollVelocity / 5000
    }
    return CGRect(origin: cellFrame.origin + cellOffset, size: cellFrame.size)
  }
  
  func adjustedScale(index:Int) -> CGFloat{
    let cellFrame = frames[index]
    let screenLocation = cellFrame.center - contentOffset
    if screenLocation.y < 25{
      return min(1,0.5 + (screenLocation.y / 50)*0.5)
    } else if screenLocation.y > bounds.size.height - 50 {
      return min(1,0.5 + ((bounds.size.height - screenLocation.y) / 50)*0.5)
    }
    return 1.0
  }
  
  override func layoutCells() {
    for (index, cell) in visibleCells{
      cell.bounds = frames[index].bounds
      //      cell.m_animate("scale", to: [adjustedScale(index)], stiffness: 500, damping: 25, threshold: 0.01)
      cell.animateCenterTo(adjustedRect(index).center, stiffness: 150, damping:20, threshold: 1)
    }
  }
}
