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
  var animator: CollectionAnimator

  public init(dataProvider: DP, viewProvider: VP, layoutProvider: LP, eventResponder: ER, animator: CollectionAnimator = DefaultCollectionAnimator()) {
    self.dataProvider = dataProvider
    self.viewProvider = viewProvider
    self.layoutProvider = layoutProvider
    self.eventResponder = eventResponder
    self.animator = animator
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
  
  public func prepare(collectionView: MCollectionView) {
    animator.prepare(collectionView: collectionView)
  }
  public func insert(view: UIView, at: Int, frame: CGRect) {
    animator.insert(view: view, at: at, frame: frame)
  }
  public func delete(view: UIView, at: Int, frame: CGRect) {
    animator.delete(view: view, at: at, frame: frame)
  }
  public func update(view: UIView, at: Int, frame: CGRect) {
    animator.update(view: view, at: at, frame: frame)
  }
}

public protocol AnyCollectionProvider {
  // data
  var numberOfItems: Int { get }
  func identifier(at: Int) -> String
  
  // view
  func view(at: Int) -> UIView
  func update(view: UIView, at: Int)
  
  // layout
  func prepare(size: CGSize)
  var insets: UIEdgeInsets { get }
  func frame(at: Int) -> CGRect
  
  // event
  func willReload()
  func didReload()
  func willDrag(cell: UIView, at:Int) -> Bool
  func didDrag(cell: UIView, at:Int)
  func moveItem(at: Int, to: Int) -> Bool
  func didTap(cell: UIView, at: Int)
  
  // animate
  func prepare(collectionView: MCollectionView)
  func insert(view: UIView, at: Int, frame: CGRect)
  func delete(view: UIView, at: Int, frame: CGRect)
  func update(view: UIView, at: Int, frame: CGRect)
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

public class SectionComposer<LP> where LP: CustomSizeLayout<AnyCollectionProvider> {
  public var sections: [AnyCollectionProvider]

  fileprivate var sectionBeginIndex:[Int] = []
  fileprivate var sectionForIndex:[Int] = []
  fileprivate var sectionFrames:[[CGRect]] = []
  fileprivate var sectionFrameOrigin:[CGPoint] = []
  
  var layoutProvider: LP

  public init(_ sections: [AnyCollectionProvider] = [], layoutProvider: LP) {
    self.sections = sections
    self.layoutProvider = layoutProvider
    self.layoutProvider.sizeProvider = { [weak self] (index, section, size) -> CGSize in
      guard let strongSelf = self else { return .zero }
      var sectionUnionFrame: CGRect = .zero
      strongSelf.sectionFrames.append([])
      section.prepare(size: size)
      for i in 0..<section.numberOfItems {
        let frame = section.frame(at: i)
        strongSelf.sectionFrames[index].append(frame)
        sectionUnionFrame = sectionUnionFrame.union(frame)
      }
      return sectionUnionFrame.size
    }
  }
  
  public convenience init(_ sections: AnyCollectionProvider..., layoutProvider: LP) {
    self.init(sections, layoutProvider: layoutProvider)
  }

  func indexPath(_ index: Int) -> (Int, Int) {
    let section = sectionForIndex[index]
    let item = index - sectionBeginIndex[section]
    return (section, item)
  }

  func insets(for index: Int) -> UIEdgeInsets {
    if let section = sections.get(index) {
      return section.insets
    }
    return .zero
  }
}

extension SectionComposer: AnyCollectionProvider {
  public var insets: UIEdgeInsets {
    return layoutProvider.insets
  }
  public var numberOfItems: Int {
    return sectionForIndex.count
  }
  public func view(at: Int) -> UIView {
    let (sectionIndex, item) = indexPath(at)
    return sections[sectionIndex].view(at: item)
  }
  public func update(view: UIView, at: Int) {
    let (sectionIndex, item) = indexPath(at)
    sections[sectionIndex].update(view: view, at: item)
  }
  public func identifier(at: Int) -> String {
    let (sectionIndex, item) = indexPath(at)
    return "section-\(sectionIndex)-" + sections[sectionIndex].identifier(at: item)
  }

  public func prepare(size: CGSize) {
    sectionFrames = []
    sectionFrameOrigin = []
    layoutProvider.prepare(size: size)
    for (i, section) in sections.enumerated() {
      sectionFrameOrigin.append(layoutProvider.frame(with: section, at: i).origin)
    }
  }
  public func frame(at: Int) -> CGRect {
    let (sectionIndex, item) = indexPath(at)
    var frame = sectionFrames[sectionIndex][item]
    frame.origin = frame.origin + sectionFrameOrigin[sectionIndex]
    return frame
  }
  public func willReload() {
    for section in sections {
      section.willReload()
    }
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
  public func didReload() {
    for section in sections {
      section.didReload()
    }
  }
  public func willDrag(cell: UIView, at index:Int) -> Bool {
    let (sectionIndex, item) = indexPath(index)
    return sections[sectionIndex].willDrag(cell: cell, at: item)
  }
  public func didDrag(cell: UIView, at index:Int) {
    let (sectionIndex, item) = indexPath(index)
    sections[sectionIndex].didDrag(cell: cell, at: item)
  }
  public func moveItem(at index: Int, to: Int) -> Bool {
    let (fromSection, fromItem) = indexPath(index)
    let (toSection, toItem) = indexPath(to)
    if fromSection == toSection {
      return sections[fromSection].moveItem(at: fromItem, to: toItem)
    }
    return false
  }
  public func didTap(cell: UIView, at: Int) {
    let (sectionIndex, item) = indexPath(at)
    sections[sectionIndex].didTap(cell: cell, at: item)
  }
  public func prepare(collectionView: MCollectionView) {
    for section in sections {
      section.prepare(collectionView: collectionView)
    }
  }
  public func insert(view: UIView, at: Int, frame: CGRect) {
    let (sectionIndex, item) = indexPath(at)
    sections[sectionIndex].insert(view: view, at: item, frame: frame)
  }
  public func delete(view: UIView, at: Int, frame: CGRect) {
    let (sectionIndex, item) = indexPath(at)
    sections[sectionIndex].delete(view: view, at: item, frame: frame)
  }
  public func update(view: UIView, at: Int, frame: CGRect) {
    let (sectionIndex, item) = indexPath(at)
    sections[sectionIndex].update(view: view, at: item, frame: frame)
  }
}
