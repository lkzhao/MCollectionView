//
//  MCollectionView+Section.swift
//  Footprint
//
//  Created by Luke on 4/10/16.
//  Copyright © 2016 Luke Zhao. All rights reserved.
//

import UIKit

@objc protocol MCollectionViewSingleSectionDataSource{
    func numberOfItemsInCollectionView(collectionView:MCollectionView) -> Int
    func collectionView(collectionView:MCollectionView, viewForIndex:Int, initialFrame:CGRect) -> UIView
    func collectionView(collectionView:MCollectionView, frameForIndex:Int) -> CGRect
    func collectionView(collectionView:MCollectionView, identifierForIndex:Int) -> String


    optional func collectionViewPrepareForLayout(collectionView:MCollectionView)

    // todo move to delegate
    optional func collectionView(collectionView:MCollectionView, didInsertCellView cellView: UIView, atIndex index: Int)
    optional func collectionView(collectionView:MCollectionView, didDeleteCellView cellView: UIView, atIndex index: Int)
    optional func collectionView(collectionView:MCollectionView, didReloadCellView cellView: UIView, atIndex index: Int)
    optional func collectionView(collectionView:MCollectionView, didMoveCellView cellView: UIView, fromIndex: Int, toIndex:Int)

    optional func collectionView(collectionView:MCollectionView, cellView:UIView, didAppearForIndex index:Int)
    optional func collectionView(collectionView:MCollectionView, cellView:UIView, willDisappearForIndex index:Int)
    optional func collectionView(collectionView:MCollectionView, cellView:UIView, didUpdateScreenPositionForIndex index:Int, screenPosition:CGPoint)
}

class MCollectionViewSingleSectionManager:NSObject{
    weak var singleSectionDataSource:MCollectionViewSingleSectionDataSource?
}

extension MCollectionViewSingleSectionManager:MCollectionViewDataSource{
    func numberOfSectionsInCollectionView(collectionView: MCollectionView) -> Int {
        return 1
    }
    func collectionView(collectionView: MCollectionView, numberOfItemsInSection: Int) -> Int {
        return singleSectionDataSource?.numberOfItemsInCollectionView(collectionView) ?? 0
    }
    func collectionView(collectionView: MCollectionView, identifierForIndexPath indexPath: NSIndexPath) -> String {
        return singleSectionDataSource?.collectionView(collectionView, identifierForIndex: indexPath.item) ?? ""
    }
    func collectionView(collectionView: MCollectionView, frameForIndexPath indexPath: NSIndexPath) -> CGRect {
        return singleSectionDataSource?.collectionView(collectionView, frameForIndex: indexPath.item) ?? CGRectZero
    }
    func collectionView(collectionView: MCollectionView, viewForIndexPath indexPath: NSIndexPath, initialFrame: CGRect) -> UIView {
        return singleSectionDataSource?.collectionView(collectionView, viewForIndex: indexPath.item, initialFrame: initialFrame) ?? UIView()
    }
    func collectionViewDidReload(collectionView: MCollectionView) {

    }
    func collectionViewWillReload(collectionView: MCollectionView) {
        singleSectionDataSource?.collectionViewPrepareForLayout?(collectionView)
    }

    func collectionView(collectionView:MCollectionView, didInsertCellView cellView: UIView, atIndexPath indexPath: NSIndexPath){
        singleSectionDataSource?.collectionView?(collectionView, didInsertCellView:cellView, atIndex: indexPath.item)
    }
    func collectionView(collectionView:MCollectionView, didDeleteCellView cellView: UIView, atIndexPath indexPath: NSIndexPath){
        singleSectionDataSource?.collectionView?(collectionView, didDeleteCellView:cellView, atIndex: indexPath.item)
    }
    func collectionView(collectionView:MCollectionView, didReloadCellView cellView: UIView, atIndexPath indexPath: NSIndexPath){
        singleSectionDataSource?.collectionView?(collectionView, didReloadCellView:cellView, atIndex: indexPath.item)
    }
    func collectionView(collectionView:MCollectionView, didMoveCellView cellView: UIView, fromIndexPath: NSIndexPath, toIndexPath:NSIndexPath){
        singleSectionDataSource?.collectionView?(collectionView, didMoveCellView:cellView, fromIndex: fromIndexPath.item, toIndex: toIndexPath.item)
    }

    func collectionView(collectionView:MCollectionView, cellView:UIView, didAppearForIndexPath indexPath:NSIndexPath){
        singleSectionDataSource?.collectionView?(collectionView, cellView:cellView, didAppearForIndex:indexPath.item)
    }
    func collectionView(collectionView:MCollectionView, cellView:UIView, willDisappearForIndexPath indexPath:NSIndexPath){
        singleSectionDataSource?.collectionView?(collectionView, cellView:cellView, willDisappearForIndex:indexPath.item)
    }
    func collectionView(collectionView:MCollectionView, cellView:UIView, didUpdateScreenPositionForIndexPath indexPath:NSIndexPath, screenPosition:CGPoint){
        singleSectionDataSource?.collectionView?(collectionView, cellView: cellView, didUpdateScreenPositionForIndex: indexPath.item, screenPosition: screenPosition)
    }
}


class MCollectionViewSection:NSObject{
    var numberOfItems:Int {
        return 0
    }
    weak var collectionView:MCollectionView?
    func viewForItem(index:Int) -> UIView { fatalError() }
    func identifierForItem(index:Int) -> String { fatalError() }
    func frameForItem(index:Int) -> CGRect { fatalError() }
    func prepareLayout(boundingFrame:CGRect) -> CGRect { fatalError() }
}

class MCollectionViewSectionWithLayout:MCollectionViewSection{
    var layout:MCollectionViewLayout
    var items:[UIView]
    var identifier:String

    override var numberOfItems:Int{
        return items.count
    }
    override func viewForItem(index:Int) -> UIView{
        return items[index]
    }
    override func identifierForItem(index:Int) -> String{
        return "\(identifier) - item \(index)"
    }
    override func frameForItem(index:Int) -> CGRect {
        return layout.frames[index]
    }
    init(_ identifier:String, items:[UIView], layout:MCollectionViewLayout){
        self.items = items
        self.layout = layout
        self.identifier = identifier
    }
    override func prepareLayout(boundingFrame: CGRect) -> CGRect {
        return self.layout.prepareLayout(items, boundingFrame: boundingFrame)
    }
}

class MCollectionViewLayout{
    var frames:[CGRect] = []
    func prepareLayout(items:[UIView], boundingFrame:CGRect) -> CGRect{
        fatalError()
    }
}