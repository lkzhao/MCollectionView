//
//  MCollectionView+VisibleIndexes.swift
//  MCollectionViewExample
//
//  Created by Luke on 3/17/17.
//  Copyright © 2017 lkzhao. All rights reserved.
//

import UIKit

extension MCollectionView {
  open func previousIndex(_ index: IndexPath) -> IndexPath? {
    if (index as NSIndexPath).item > 0 {
      return IndexPath(item: (index as NSIndexPath).item - 1, section: (index as NSIndexPath).section)
    }
    var currentSection = (frames:framesForSectionIndex((index as NSIndexPath).section - 1), sectionIndex: (index as NSIndexPath).section - 1)
    while currentSection.frames != nil {
      if currentSection.frames!.count > 0 {
        return IndexPath(item:currentSection.frames!.count - 1, section: currentSection.sectionIndex)
      }
      currentSection = (framesForSectionIndex(currentSection.sectionIndex - 1), currentSection.sectionIndex - 1)
    }
    return nil
  }

  open func nextIndex(_ index: IndexPath) -> IndexPath? {
    if let sectionFrames = framesForSectionIndex((index as NSIndexPath).section), sectionFrames.count > (index as NSIndexPath).item + 1 {
      return IndexPath(item: (index as NSIndexPath).item + 1, section: (index as NSIndexPath).section)
    }
    var currentSection = (frames:framesForSectionIndex((index as NSIndexPath).section + 1), sectionIndex: (index as NSIndexPath).section + 1)
    while currentSection.frames != nil {
      if currentSection.frames!.count > 0 {
        return IndexPath(item:0, section: currentSection.sectionIndex)
      }
      currentSection = (framesForSectionIndex(currentSection.sectionIndex + 1), currentSection.sectionIndex + 1)
    }
    return nil
  }

  func calculateVisibleIndexesUsingOptimizedMethod() -> Set<IndexPath> {
    var indexes = Set<IndexPath>()
    let currentFrame = activeFrame

    for index in visibleIndexes {
      if let cellFrame = frameForIndexPath(index), cellFrame.intersects(currentFrame) {
        indexes.insert(index)
      }
    }

    var nextIndex: IndexPath? = visibleIndexEnd
    var nextCellFrame = frameForIndexPath(nextIndex)
    while (nextCellFrame != nil && nextCellFrame!.intersects(currentFrame)) {
      indexes.insert(nextIndex!)
      visibleIndexEnd = nextIndex!
      nextIndex = self.nextIndex(nextIndex!)
      nextCellFrame = frameForIndexPath(nextIndex)
    }

    var prevIndex: IndexPath? = self.previousIndex(visibleIndexStart)
    var prevCellFrame = frameForIndexPath(prevIndex)
    while (prevCellFrame != nil && prevCellFrame!.intersects(currentFrame)) {
      indexes.insert(prevIndex!)
      visibleIndexStart = prevIndex!
      prevIndex = self.previousIndex(prevIndex!)
      prevCellFrame = frameForIndexPath(prevIndex)
    }

    while (visibleIndexStart != visibleIndexEnd) {
      if let cellFrame = frameForIndexPath(visibleIndexStart), cellFrame.intersects(currentFrame) {
        break
      }
      visibleIndexStart = self.nextIndex(visibleIndexStart) ?? visibleIndexEnd
    }

    while (visibleIndexStart != visibleIndexEnd) {
      if let cellFrame = frameForIndexPath(visibleIndexEnd), cellFrame.intersects(currentFrame) {
        break
      }
      visibleIndexEnd = self.previousIndex(visibleIndexEnd) ?? visibleIndexStart
    }
    return indexes
  }

  func calculateVisibleIndexesFromActiveFrame() -> Set<IndexPath> {
    var indexes: Set<IndexPath>
    if optimizeForContinuousLayout {
      indexes = calculateVisibleIndexesUsingOptimizedMethod()

      // no visible cell found. we might be
      if visibleIndexStart == visibleIndexEnd {
        if let firstVisible = firstVisibleIndex() {
          visibleIndexStart = firstVisible
          visibleIndexEnd = firstVisible
          indexes = calculateVisibleIndexesUsingOptimizedMethod()
        }
      }
      //      print(visibleIndexStart, visibleIndexEnd)
    } else {
      indexes = indexesForFramesIntersectingFrame(activeFrame)
    }
    for f in floatingCells {
      if let index = visibleCellToIndexMap[f] {
        indexes.insert(index)
      }
    }
    return indexes
  }
}
