//
//  MDynamicSectionController.swift
//  Footprint
//
//  Created by Luke on 4/15/16.
//  Copyright © 2016 Luke Zhao. All rights reserved.
//

import UIKit

class MDynamicSectionController:NSObject{
    var sections:[MCollectionViewSection] = []
}

extension MDynamicSectionController:MCollectionViewDataSource {
    func numberOfSectionsInCollectionView(collectionView: MCollectionView) -> Int {
        return sections.count
    }
    func collectionView(collectionView: MCollectionView, numberOfItemsInSection section: Int) -> Int {
        return sections[section].numberOfItems
    }
    func collectionView(collectionView: MCollectionView, frameForIndexPath indexPath: NSIndexPath) -> CGRect {
        return sections[indexPath.section].frameForItem(indexPath.item)
    }
    func collectionView(collectionView: MCollectionView, viewForIndexPath indexPath: NSIndexPath, initialFrame: CGRect) -> UIView {
        let view = sections[indexPath.section].viewForItem(indexPath.item)
        view.bounds = initialFrame.bounds
        view.center = initialFrame.center
        return view
    }
    func collectionViewWillReload(collectionView: MCollectionView) {
        let size = CGSizeMake(collectionView.frame.width - collectionView.contentInset.left - collectionView.contentInset.right, CGFloat.max)
        var lastOrigin = CGPointZero
        for section in sections{
            section.collectionView = collectionView
            let finalFrame = section.prepareLayout(CGRect(origin: lastOrigin, size: size))
            lastOrigin = CGPointMake(0, finalFrame.maxY)
        }
    }
    func collectionView(collectionView: MCollectionView, identifierForIndexPath indexPath: NSIndexPath) -> String {
        return sections[indexPath.section].identifierForItem(indexPath.item)
    }
}
