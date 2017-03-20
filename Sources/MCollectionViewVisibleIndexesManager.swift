//
//  MCollectionViewVisibleIndexesManager.swift
//  MCollectionView
//
//  Created by Luke on 3/20/17.
//  Copyright © 2017 lkzhao. All rights reserved.
//

import UIKit


public class LinearVisibleIndexesManager {
  var minToIndexes: [(CGFloat, IndexPath)] = []
  var maxToIndexes: [(CGFloat, IndexPath)] = []

  var lastMin: CGFloat = 0
  var lastMax: CGFloat = 0

  var minIndex: Int = 0
  var maxIndex: Int = -1

  var visibleIndexes = Set<IndexPath>()

  public func reload(minToIndexes:[(CGFloat, IndexPath)], maxToIndexes:[(CGFloat, IndexPath)]) {
    self.minToIndexes = minToIndexes.sorted { left, right in
      return left.0 < right.0
    }
    self.maxToIndexes = maxToIndexes.sorted { left, right in
      return left.0 < right.0
    }

    // assign a value that doesn't contain any visible indexes
    lastMin = (minToIndexes.first?.0 ?? 0) - 1
    lastMax = lastMin
    minIndex = 0
    maxIndex = -1

    visibleIndexes.removeAll()
  }

  public func visibleIndexes(min:CGFloat, max:CGFloat) -> Set<IndexPath> {
    if (max > lastMax) {
      while minIndex < minToIndexes.count, minToIndexes[minIndex].0 < max {
        visibleIndexes.insert(minToIndexes[minIndex].1)
        minIndex += 1
      }
    } else {
      while minIndex > 0, minToIndexes[minIndex-1].0 > max {
        visibleIndexes.remove(minToIndexes[minIndex-1].1)
        minIndex -= 1
      }
    }

    if (min > lastMin) {
      while maxIndex < maxToIndexes.count - 1, maxToIndexes[maxIndex+1].0 < min {
        visibleIndexes.remove(maxToIndexes[maxIndex+1].1)
        maxIndex += 1
      }
    } else {
      while maxIndex >= 0, maxToIndexes[maxIndex].0 > min {
        visibleIndexes.insert(maxToIndexes[maxIndex].1)
        maxIndex -= 1
      }
    }

    lastMax = max
    lastMin = min
    return visibleIndexes
  }

  public init(){
    
  }
}

class MCollectionViewVisibleIndexesManager {
  var verticalVisibleIndexManager = LinearVisibleIndexesManager()
  var horizontalVisibleIndexManager = LinearVisibleIndexesManager()

  func reload(with frames:[[CGRect]]) {
    var flattened: [(CGRect, IndexPath)] = []
    for (section, sectionFrames) in frames.enumerated() {
      for (item, frame) in sectionFrames.enumerated() {
        flattened.append((frame, IndexPath(item: item, section: section)))
      }
    }

    verticalVisibleIndexManager.reload(minToIndexes: flattened.map({ return ($0.0.minY, $0.1) }),
                                       maxToIndexes: flattened.map({ return ($0.0.maxY, $0.1) }))

    horizontalVisibleIndexManager.reload(minToIndexes: flattened.map({ return ($0.0.minX, $0.1) }),
                                         maxToIndexes: flattened.map({ return ($0.0.maxX, $0.1) }))
  }

  func visibleIndexes(for rect:CGRect) -> Set<IndexPath> {
    let vertical = verticalVisibleIndexManager.visibleIndexes(min: rect.minY, max: rect.maxY)
    let horizontal = horizontalVisibleIndexManager.visibleIndexes(min: rect.minX, max: rect.maxX)
    return vertical.intersection(horizontal)
  }
}
