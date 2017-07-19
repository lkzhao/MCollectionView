//
//  ArrayDataProvider.swift
//  MCollectionView
//
//  Created by Luke Zhao on 2017-07-19.
//  Copyright © 2017 lkzhao. All rights reserved.
//

import Foundation

public class ArrayDataProvider<Data>: CollectionDataProvider {
  public var data: [Data]
  public var identifierMapper: (Int, Data) -> String
  
  public init(data: [Data], identifierMapper: @escaping (Int, Data) -> String = { "\($0)" }) {
    self.data = data
    self.identifierMapper = identifierMapper
  }

  public var numberOfItems: Int {
    return data.count
  }
  public func identifier(at: Int) -> String {
    return identifierMapper(at, data[at])
  }
  public func data(at: Int) -> Data {
    return data[at]
  }
}
