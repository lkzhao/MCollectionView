//
//  ClosureViewProvider.swift
//  MCollectionView
//
//  Created by Luke Zhao on 2017-07-19.
//  Copyright © 2017 lkzhao. All rights reserved.
//

import UIKit

public class ClosureViewProvider<View, Data>: CollectionViewProvider where View: UIView {
  public var viewUpdater: (View, Data, Int) -> Void
  public init(viewUpdater: @escaping (View, Data, Int) -> Void) {
    self.viewUpdater = viewUpdater
  }

  public func view(at: Int) -> View {
    return ReuseManager.shared.dequeue(View.self) ?? View()
  }
  public func update(view: View, with data: Data, at: Int) {
    viewUpdater(view, data, at)
  }
}

public class ClosureEventResponder: CollectionEventResponder {
  public var canDrag: (UIView, Int) -> Bool = { _, _ in return false }
  public var onMove: (Int, Int) -> Bool = { _, _ in return false }
  public var onTap: (UIView, Int) -> Void = { _, _ in }
  
  public init(canDrag: @escaping (UIView, Int) -> Bool = { _, _ in return false },
              onMove: @escaping (Int, Int) -> Bool = { _, _ in return false },
              onTap: @escaping (UIView, Int) -> Void = { _, _ in }) {
    self.canDrag = canDrag
    self.onMove = onMove
    self.onTap = onTap
  }
  public func willReload() {}
  public func didReload() {}
  public func willDrag(cell: UIView, at index:Int) -> Bool {
    return canDrag(cell, index)
  }
  public func didDrag(cell: UIView, at index:Int) {}
  public func moveItem(at index: Int, to: Int) -> Bool {
    return onMove(index, to)
  }
  public func didTap(cell: UIView, index: Int) {
    onTap(cell, index)
  }
}

public class DefaultEventResponder: CollectionEventResponder {
  public func willReload() {}
  public func didReload() {}
  public func willDrag(cell: UIView, at index:Int) -> Bool { return false }
  public func didDrag(cell: UIView, at index:Int) {}
  public func moveItem(at index: Int, to: Int) -> Bool { return false }
  public func didTap(cell: UIView, index: Int) {}
  public init() {}
}
