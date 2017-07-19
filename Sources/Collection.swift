//
//  Collection.swift
//  MCollectionView
//
//  Created by Luke Zhao on 2017-07-18.
//  Copyright © 2017 lkzhao. All rights reserved.
//

import UIKit

public protocol CollectionViewProvider {
  associatedtype Data
  associatedtype View: UIView
  func view(at: Int) -> View
  func update(view: View, with data: Data, at: Int)
}

public protocol CollectionDataProvider {
  associatedtype Data
  var numberOfItems: Int { get }
  func data(at: Int) -> Data
  func identifier(at: Int) -> String
}

public protocol CollectionLayoutProvider {
  associatedtype Data
  var insets: UIEdgeInsets { get }
  func prepare(size: CGSize)
  func frame(with data: Data, at: Int) -> CGRect
}

public protocol CollectionEventResponder {
  associatedtype Data
  func willReload()
  func didReload()
  func willDrag(cell: UIView, at index:Int) -> Bool
  func didDrag(cell: UIView, at index:Int)
  func moveItem(at index: Int, to: Int) -> Bool
  func didTap(cell: UIView, index: Int)
}

public typealias CollectionProvider = CollectionViewProvider & CollectionDataProvider & CollectionLayoutProvider

public class NoEventResponder<D>: CollectionEventResponder {
  public typealias Data = D
  public func willReload() {}
  public func didReload() {}
  public func willDrag(cell: UIView, at index:Int) -> Bool { return false }
  public func didDrag(cell: UIView, at index:Int) {}
  public func moveItem(at index: Int, to: Int) -> Bool { return false }
  public func didTap(cell: UIView, index: Int) {}
  public init() {}
}

public class CustomProvider<D, V, VP, DP, LP, ER>: AnyCollectionProvider where
  VP: CollectionViewProvider,
  DP: CollectionDataProvider,
  LP: CollectionLayoutProvider,
  ER: CollectionEventResponder,
  VP.View == V,
  VP.Data == D,
  DP.Data == D,
  ER.Data == D,
  LP.Data == D
{
  var dataProvider: DP
  var viewProvider: VP
  var layoutProvider: LP
  var eventResponder: ER
  public init(dataProvider: DP, viewProvider: VP, layoutProvider: LP, eventResponder: ER) {
    self.dataProvider = dataProvider
    self.viewProvider = viewProvider
    self.layoutProvider = layoutProvider
    self.eventResponder = eventResponder
  }
  
  public var numberOfItems: Int {
    return dataProvider.numberOfItems
  }
  public func view(at: Int) -> UIView {
    return viewProvider.view(at: at)
  }
  public func update(view: UIView, at: Int) {
    viewProvider.update(view: view as! V, with: dataProvider.data(at: at), at: at)
  }
  public func identifier(at: Int) -> String {
    return dataProvider.identifier(at: at)
  }

  public func prepare(size: CGSize) {
    layoutProvider.prepare(size: size)
  }
  public var insets: UIEdgeInsets {
    return layoutProvider.insets
  }
  public func frame(at: Int) -> CGRect {
    return layoutProvider.frame(with: dataProvider.data(at: at), at: at)
  }

  public func willReload() {
    eventResponder.willReload()
  }
  public func didReload() {
    eventResponder.didReload()
  }
  public func willDrag(cell: UIView, at:Int) -> Bool {
    return eventResponder.willDrag(cell: cell, at: at)
  }
  public func didDrag(cell: UIView, at:Int) {
    eventResponder.didDrag(cell: cell, at: at)
  }
  public func moveItem(at: Int, to: Int) -> Bool {
    return eventResponder.moveItem(at: at, to: to)
  }
  public func didTap(cell: UIView, at: Int) {
    eventResponder.didTap(cell: cell, index: at)
  }
}

public protocol AnyCollectionProvider {
  var numberOfItems: Int { get }
  func view(at: Int) -> UIView
  func update(view: UIView, at: Int)
  func identifier(at: Int) -> String

  func prepare(size: CGSize)
  var insets: UIEdgeInsets { get }
  func frame(at: Int) -> CGRect

  func willReload()
  func didReload()
  func willDrag(cell: UIView, at:Int) -> Bool
  func didDrag(cell: UIView, at:Int)
  func moveItem(at: Int, to: Int) -> Bool
  func didTap(cell: UIView, at: Int)
}

public class Section {
  static let defaultInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)

  var insets: UIEdgeInsets = defaultInsets
  var isHidden = false

  func numberOfItems() -> Int {
    return 0
  }
  func view(for index: Int) -> UIView {
    fatalError()
  }
  func frame(for index: Int) -> CGRect{
    fatalError()
  }
  func identifier(for index: Int) -> String{
    fatalError()
  }


  func willReload() {}
  func didReload() {}
  func willDrag(cell: UIView, at index:Int) -> Bool {
    return false
  }
  func didDrag(cell: UIView, at index:Int) {}
  func moveItem(at index: Int, to: Int) -> Bool {
    return false
  }
  func didTap(cell: UIView, at index: Int) {}
}


extension Array {
  func get(_ index: Int) -> Element? {
    if (0..<count).contains(index) {
      return self[index]
    }
    return nil
  }
}

class SectionComposer {
  public var sections: [AnyCollectionProvider]

  fileprivate var sectionBeginIndex:[Int] = []
  fileprivate var sectionForIndex:[Int] = []
  fileprivate var currentSectionAndOffset: (index: Int, bottomOffset: CGFloat) = (0, 0)
  fileprivate var currentOffset: CGFloat = 0
  fileprivate let firstCellMask = CAShapeLayer()

  init(sections: [AnyCollectionProvider] = []) {
    self.sections = sections
  }

  func indexPath(_ index: Int) -> (Int, Int) {
    let section = sectionForIndex[index]
    let item = index - sectionBeginIndex[section]
    return (section, item)
  }

  func calculateContentSize() -> CGSize {
    var height: CGFloat = 0
    var width: CGFloat = 0
    for section in sections {
      var sectionUnionFrame: CGRect = .zero
      for i in 0..<section.numberOfItems {
        sectionUnionFrame = sectionUnionFrame.union(section.frame(at: i))
      }
      sectionUnionFrame = UIEdgeInsetsInsetRect(sectionUnionFrame, -section.insets)
      width = max(width, sectionUnionFrame.width)
      height += sectionUnionFrame.height
    }
    return CGSize(width: width, height: height)
  }

  func insets(for index: Int) -> UIEdgeInsets {
    if let section = sections.get(index) {
      return section.insets
    }
    return .zero
  }
}

extension SectionComposer: AnyCollectionProvider {
  var insets: UIEdgeInsets {
    var top: CGFloat = 0
    let firstSectionIndexWithView = (sectionForIndex.first ?? 0)
    for i in 0..<firstSectionIndexWithView {
      top += insets(for: i).top + insets(for: i).bottom
    }
    top += insets(for: firstSectionIndexWithView).top

    var bottom: CGFloat = 0
    let lastSectionIndexWithView = (sectionForIndex.last ?? sections.count-1)
    for i in lastSectionIndexWithView+1..<sections.count {
      bottom += insets(for: i).top + insets(for: i).bottom
    }
    bottom += insets(for: lastSectionIndexWithView).bottom

    return UIEdgeInsets(top: top, left: 0, bottom: bottom, right: 0)
  }
  var numberOfItems: Int {
    return sectionForIndex.count
  }
  func view(at: Int) -> UIView {
    let (sectionIndex, item) = indexPath(at)
    return sections[sectionIndex].view(at: item)
  }
  func update(view: UIView, at: Int) {
    let (sectionIndex, item) = indexPath(at)
    sections[sectionIndex].update(view: view, at: item)
  }
  func identifier(at: Int) -> String {
    let (sectionIndex, item) = indexPath(at)
    return "section-\(sectionIndex)-" + sections[sectionIndex].identifier(at: item)
  }

  func prepare(size: CGSize) {

  }
  func frame(at: Int) -> CGRect {
    let (sectionIndex, item) = indexPath(at)
    var frame = sections[sectionIndex].frame(at: item)
    if sectionIndex > currentSectionAndOffset.index {
      currentOffset = currentSectionAndOffset.bottomOffset
      for inbetweenSectionIndex in currentSectionAndOffset.index..<sectionIndex {
        currentOffset += insets(for: inbetweenSectionIndex).bottom
      }
      for inbetweenSectionIndex in (currentSectionAndOffset.index + 1)...sectionIndex {
        currentOffset += insets(for: inbetweenSectionIndex).top
      }
    }
    frame.origin.y += currentOffset
    frame.origin.x += insets(for: sectionIndex).left
    currentSectionAndOffset = (sectionIndex, max(frame.maxY, currentSectionAndOffset.bottomOffset))
    return frame
  }

  func willReload() {
    for section in sections {
      section.willReload()
    }

    currentOffset = 0
    currentSectionAndOffset = (0, 0)
    sectionBeginIndex.removeAll()
    sectionForIndex.removeAll()

    sectionBeginIndex.reserveCapacity(sections.count)
    for (sectionIndex, section) in sections.enumerated() {
      let itemCount = section.numberOfItems
      sectionBeginIndex.append(sectionForIndex.count)
      for _ in 0..<itemCount {
        sectionForIndex.append(sectionIndex)
      }
    }
  }
  func didReload() {
    for section in sections {
      section.didReload()
    }
  }
  func willDrag(cell: UIView, at index:Int) -> Bool {
    let (sectionIndex, item) = indexPath(index)
    if sections[sectionIndex].willDrag(cell: cell, at: item) {
      DispatchQueue.main.async {
        cell.layer.yaal.zPosition.animateTo(500)
        cell.yaal.scale.animateTo(1.2)
      }
      return true
    }
    return false
  }
  func didDrag(cell: UIView, at index:Int) {
    cell.yaal.scale.animateTo(1)
    cell.layer.yaal.zPosition.animateTo(0)

    let (sectionIndex, item) = indexPath(index)
    sections[sectionIndex].didDrag(cell: cell, at: item)
  }
  func moveItem(at index: Int, to: Int) -> Bool {
    let (fromSection, fromItem) = indexPath(index)
    let (toSection, toItem) = indexPath(to)
    if fromSection == toSection {
      return sections[fromSection].moveItem(at: fromItem, to: toItem)
    }
    return false
  }
  func didTap(cell: UIView, at: Int) {
    let (sectionIndex, item) = indexPath(at)
    sections[sectionIndex].didTap(cell: cell, at: item)
  }
}


//  /// Callback during reloadData
//  func collectionView(_ collectionView: MCollectionView, didInsertCellView cellView: UIView, atIndex index: Int) {
//    guard showInsertAndDeleteAnimation else { return }
//    cellView.transform = CGAffineTransform.identity.scaledBy(x: 0.5, y: 0.5)
//    cellView.alpha = 0
//    UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: [], animations: {
//      cellView.alpha = 1
//      cellView.transform = CGAffineTransform.identity
//    }, completion: nil)
//  }
//  func collectionView(_ collectionView: MCollectionView, didDeleteCellView cellView: UIView, atIndex index: Int) {
//    if showInsertAndDeleteAnimation {
//      UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: [], animations: {
//        cellView.alpha = 0
//        cellView.transform = CGAffineTransform.identity.scaledBy(x: 0.5, y: 0.5)
//      }, completion: { _ in
//        cellView.removeFromSuperview()
//      })
//    } else {
//      cellView.removeFromSuperview()
//    }
//  }
//  func collectionView(_ collectionView: MCollectionView, didReloadCellView cellView: UIView, atIndex index: Int) {
//    if collectionView.isFloating(cell: cellView) {
//      return
//    }
//    UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0, options: [], animations: {
//      if let bounds = self.collectionView?.frameForCell(at: index)?.bounds, cellView.bounds != bounds {
//        cellView.bounds = bounds
//        cellView.layoutIfNeeded()
//      }
//      if !collectionView.autoLayoutOnUpdate,
//        !collectionView.wabble,
//        let center = self.collectionView?.frameForCell(at: index)?.center, cellView.center != center {
//        cellView.center = center
//      }
//    }, completion: nil)
//  }
//  func collectionView(_ collectionView: MCollectionView, didMoveCellView cellView: UIView, fromIndex: Int, toIndex: Int) {
//    if collectionView.isFloating(cell: cellView) {
//      return
//    }
//    UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0, options: [], animations: {
//      if let bounds = self.collectionView?.frameForCell(at: toIndex)?.bounds, cellView.bounds != bounds {
//        cellView.bounds = bounds
//        cellView.layoutIfNeeded()
//      }
//      if !collectionView.autoLayoutOnUpdate,
//        !collectionView.wabble,
//        let center = self.collectionView?.frameForCell(at: toIndex)?.center, cellView.center != center {
//        cellView.center = center
//      }
//    }, completion: nil)
//  }
//
//  /// On Scroll
//  func collectionView(_ collectionView: MCollectionView, cellView: UIView, didAppearForIndex index: Int) {
//
//  }
//  func collectionView(_ collectionView: MCollectionView, cellView: UIView, willDisappearForIndex index: Int) {
//
//  }
//  func collectionView(_ collectionView: MCollectionView, cellView: UIView, didUpdateScreenPositionForIndex index: Int, screenPosition: CGPoint) {
//    
//  }
//}
