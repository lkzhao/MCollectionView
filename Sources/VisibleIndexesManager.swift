//
//  MCollectionViewVisibleIndexesManager.swift
//  MCollectionView
//
//  Created by Luke on 3/20/17.
//  Copyright © 2017 lkzhao. All rights reserved.
//

import UIKit

// struct with two elements is allocated in-place.
// no retain/release. Much faster than IndexPath if used frequently
public struct CheapIndex {
  var item:Int
  var section:Int
  var indexPath:IndexPath {
    return IndexPath(item: item, section: section)
  }
}

public class LinearVisibleIndexesManager {
  var minToIndexes: [(CGFloat, CheapIndex)] = []
  var maxToIndexes: [(CGFloat, CheapIndex)] = []

  var lastMin: CGFloat = 0
  var lastMax: CGFloat = 0

  var minIndex: Int = 0
  var maxIndex: Int = -1

  public func reload(minToIndexes:[(CGFloat, CheapIndex)], maxToIndexes:[(CGFloat, CheapIndex)]) {
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
  }

  public func visibleIndexes(min:CGFloat, max:CGFloat) -> ([CheapIndex], [CheapIndex]) {
    var inserted:[CheapIndex] = []
    var removed:[CheapIndex] = []
    if (max > lastMax) {
      while minIndex < minToIndexes.count, minToIndexes[minIndex].0 < max {
        inserted.append(minToIndexes[minIndex].1)
        minIndex += 1
      }
    } else {
      while minIndex > 0, minToIndexes[minIndex-1].0 > max {
        removed.append(minToIndexes[minIndex-1].1)
        minIndex -= 1
      }
    }

    if (min > lastMin) {
      while maxIndex < maxToIndexes.count - 1, maxToIndexes[maxIndex+1].0 < min {
        removed.append(maxToIndexes[maxIndex+1].1)
        maxIndex += 1
      }
    } else {
      while maxIndex >= 0, maxToIndexes[maxIndex].0 > min {
        inserted.append(maxToIndexes[maxIndex].1)
        maxIndex -= 1
      }
    }

    lastMax = max
    lastMin = min
    return (inserted, removed)
  }

  public init() {}
}

class VisibleIndexesManager {
  var verticalVisibleIndexManager = LinearVisibleIndexesManager()
  var horizontalVisibleIndexManager = LinearVisibleIndexesManager()

  var frames:[[CGRect]] = []
  var visibleIndexes = Set<IndexPath>()

  func reload(with frames:[[CGRect]]) {
    self.frames = frames
    var flattened: [(CGRect, CheapIndex)] = []
    for (section, sectionFrames) in frames.enumerated() {
      for (item, frame) in sectionFrames.enumerated() {
        flattened.append((frame, CheapIndex(item: item, section: section)))
      }
    }

    verticalVisibleIndexManager.reload(minToIndexes: flattened.map({ return ($0.0.minY, $0.1) }),
                                       maxToIndexes: flattened.map({ return ($0.0.maxY, $0.1) }))

    horizontalVisibleIndexManager.reload(minToIndexes: flattened.map({ return ($0.0.minX, $0.1) }),
                                         maxToIndexes: flattened.map({ return ($0.0.maxX, $0.1) }))
  }

  func frame(at indexPath: CheapIndex, isVisibleIn rect:CGRect) -> Bool {
    return rect.intersects(frames[indexPath.section][indexPath.item])
  }

  func visibleIndexes(for rect:CGRect) -> Set<IndexPath> {
    let (vInserted, vRemoved) = verticalVisibleIndexManager.visibleIndexes(min: rect.minY, max: rect.maxY)
    let (hInserted, hRemoved) = horizontalVisibleIndexManager.visibleIndexes(min: rect.minX, max: rect.maxX)

    // Ideally we just do a intersection between horizontal visible indexes with vertical visible indexes
    // However, perform intersections on sets is expansive in some cases. 
    // for example: all the cells are horizontally visible in a vertical scroll view.
    // Therefore, everytime horizontal visible indexes is equal to all indexes. Doing an interaction 
    // between N elements sets will make this function O(n) everytime.
    // We want to target O(1) for subsequent calculation. O(n) for the initial calculation.
    //
    // instead we do the following:
    //   calculate diff in visible indexes from each axis
    //   for all the inserted ones, we check if it is within rect
    //   for all the removed ones, we remove it directly

    for index in vInserted {
      if frame(at: index, isVisibleIn: rect) {
        visibleIndexes.insert(index.indexPath)
      }
    }
    for index in hInserted {
      if frame(at: index, isVisibleIn: rect) {
        visibleIndexes.insert(index.indexPath)
      }
    }
    for index in vRemoved {
      visibleIndexes.remove(index.indexPath)
    }
    for index in hRemoved {
      visibleIndexes.remove(index.indexPath)
    }

    return visibleIndexes
  }
}
