//
//  Layout.swift
//  MCollectionView
//
//  Created by Luke Zhao on 2017-07-19.
//  Copyright © 2017 lkzhao. All rights reserved.
//

import UIKit

open class CustomSizeLayout<Data>: CollectionLayoutProvider {
  public var insets: UIEdgeInsets = .zero
  public var sizeProvider: (Int, Data, CGSize) -> CGSize
  
  public init(insets: UIEdgeInsets = .zero, sizeProvider: @escaping (Int, Data, CGSize) -> CGSize = { _,_,_ in return .zero }) {
    self.insets = insets
    self.sizeProvider = sizeProvider
  }
  
  open func prepare(size: CGSize) {
    
  }
  
  open func frame(with data: Data, at: Int) -> CGRect {
    return .zero
  }
}

public class HorizontalLayout<Data>: CustomSizeLayout<Data> {
  public var preferredCellHeight: CGFloat
  private var numRows = 2
  private var rowWidth: [CGFloat] = [0, 0]
  private var maxSize = CGSize.zero
  
  public init(preferredCellHeight: CGFloat  = 180, insets: UIEdgeInsets = .zero, sizeProvider: @escaping (Int, Data, CGSize) -> CGSize = { _,_,_ in return .zero }) {
    self.preferredCellHeight = preferredCellHeight
    super.init(insets: insets, sizeProvider: sizeProvider)
  }
  
  public override func prepare(size: CGSize) {
    maxSize = size
    numRows = max(1, Int(size.height / preferredCellHeight))
    rowWidth = Array<CGFloat>(repeating: 0, count: numRows)
  }
  
  public override func frame(with data: Data, at: Int) -> CGRect {
    func getMinRow() -> (Int, CGFloat) {
      var minWidth: (Int, CGFloat) = (0, rowWidth[0])
      for (index, width) in rowWidth.enumerated() {
        if width < minWidth.1 {
          minWidth = (index, width)
        }
      }
      return minWidth
    }
    
    let avaliableHeight = (maxSize.height - CGFloat(rowWidth.count - 1) * 10) / CGFloat(rowWidth.count)
    var cellSize = sizeProvider(at, data, CGSize(width: .infinity, height: avaliableHeight))
    cellSize.height = avaliableHeight
    let (rowIndex, offsetX) = getMinRow()
    rowWidth[rowIndex] += cellSize.width + 10
    return CGRect(origin: CGPoint(x: offsetX, y: CGFloat(rowIndex) * (avaliableHeight + 10)), size: cellSize)
  }
}
