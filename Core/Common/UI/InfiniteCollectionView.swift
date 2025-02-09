//
//  InfiniteCollectionView.swift
//  ExampleInfiniteScrollView
//
//  Created by Mason L'Amy on 04/08/2015.
//  Copyright (c) 2015 Maso Apps Ltd. All rights reserved.
//
//  https://github.com/masonlamy/infinite-uicollectionview

import UIKit

// MARK: - InfiniteCollectionViewDataSource

public protocol InfiniteCollectionViewDataSource: AnyObject {
    func cellForItemAtIndexPath(_ collectionView: UICollectionView, dequeueIndexPath: IndexPath, usableIndexPath: IndexPath) -> UICollectionViewCell
    func numberOfItems(_ collectionView: UICollectionView) -> Int
}

// MARK: - InfiniteCollectionViewDelegate

public protocol InfiniteCollectionViewDelegate: AnyObject {
    func didSelectCellAtIndexPath(_ collectionView: UICollectionView, usableIndexPath: IndexPath)
    func willBeginDragging(_ scrollView: UIScrollView)
}

// MARK: - InfiniteCollectionView

open class InfiniteCollectionView: UICollectionView {
    public weak var infiniteDataSource: InfiniteCollectionViewDataSource?
    public weak var infiniteDelegate: InfiniteCollectionViewDelegate?

    @IBInspectable var isHorizontalScroll: Bool = true

    fileprivate var cellPadding = CGFloat(0)
    fileprivate var cellWidth = CGFloat(0)
    fileprivate var cellHeight = CGFloat(0)
    fileprivate var indexOffset = 0

    public required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        dataSource = self
        delegate = self
        setupCellDimensions()
    }

    override public init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
        dataSource = self
        delegate = self
        setupCellDimensions()
    }

    fileprivate func setupCellDimensions() {
        let layout = collectionViewLayout as! UICollectionViewFlowLayout
        cellPadding = layout.minimumInteritemSpacing
        cellWidth = layout.itemSize.width
        cellHeight = layout.itemSize.height
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        if isHorizontalScroll {
            centreIfNeeded()
        } else {
            centreVerticallyIfNeeded()
        }
    }

    fileprivate func centreIfNeeded() {
        let currentOffset = contentOffset
        let contentWidth = getTotalContentWidth()

        // Calculate the centre of content X position offset and the current distance from that centre point
        let centerOffsetX: CGFloat = (3 * contentWidth - bounds.size.width) / 2
        let distFromCentre = centerOffsetX - currentOffset.x

        if abs(distFromCentre) > (contentWidth / 4) {
            // Total cells (including partial cells) from centre
            let cellcount = distFromCentre / (cellWidth + cellPadding)

            // Amount of cells to shift (whole number) - conditional statement due to nature of +ve or -ve cellcount
            let shiftCells = Int((cellcount > 0) ? floor(cellcount) : ceil(cellcount))

            // Amount left over to correct for
            let offsetCorrection = (abs(cellcount).truncatingRemainder(dividingBy: 1)) * (cellWidth + cellPadding)

            // Scroll back to the centre of the view, offset by the correction to ensure it's not noticable
            if contentOffset.x < centerOffsetX {
                // left scrolling
                contentOffset = CGPoint(x: centerOffsetX - offsetCorrection, y: currentOffset.y)
            } else if contentOffset.x > centerOffsetX {
                // right scrolling
                contentOffset = CGPoint(x: centerOffsetX + offsetCorrection, y: currentOffset.y)
            }

            // Make content shift as per shiftCells
            shiftContentArray(getCorrectedIndex(shiftCells))

            // Reload cells, due to data shift changes above
            reloadData()
        }
    }

    fileprivate func centreVerticallyIfNeeded() {
        let currentOffset = contentOffset
        let contentHeight = getTotalContentHeight()

        let centerOffsetY: CGFloat = (3 * contentHeight) / 2 // - bounds.size.height
        let distFromCentre = centerOffsetY - currentOffset.y

        if abs(distFromCentre) > (contentHeight / 4) {
            let cellcount = distFromCentre / (cellHeight + cellPadding)
            let shiftCells = Int((cellcount > 0) ? floor(cellcount) : ceil(cellcount))

            // Amount left over to correct for
            let offsetCorrection = (abs(cellcount).truncatingRemainder(dividingBy: 1)) * (cellHeight + cellPadding)

            // Scroll back to the centre of the view, offset by the correction to ensure it's not noticable
            if contentOffset.y < centerOffsetY {
                // left scrolling
                contentOffset = CGPoint(x: currentOffset.x, y: centerOffsetY - offsetCorrection)
            } else if contentOffset.y > centerOffsetY {
                // right scrolling
                contentOffset = CGPoint(x: currentOffset.x, y: centerOffsetY + offsetCorrection)
            }

            // Make content shift as per shiftCells
            shiftContentArray(getCorrectedIndex(shiftCells))

            // Reload cells, due to data shift changes above
            reloadData()
        }
    }

    fileprivate func shiftContentArray(_ offset: Int) {
        indexOffset += offset
    }

    fileprivate func getTotalContentWidth() -> CGFloat {
        let numberOfCells = infiniteDataSource?.numberOfItems(self) ?? 0
        return CGFloat(numberOfCells) * (cellWidth + cellPadding)
    }

    fileprivate func getTotalContentHeight() -> CGFloat {
        let numberOfCells = infiniteDataSource?.numberOfItems(self) ?? 0
        return (CGFloat(numberOfCells) * (cellHeight + cellPadding)) - cellPadding
    }
}

// MARK: UICollectionViewDataSource

extension InfiniteCollectionView: UICollectionViewDataSource {
    public func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int {
        let numberOfItems = infiniteDataSource?.numberOfItems(self) ?? 0
        return 3 * numberOfItems
    }

    public func collectionView(_: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        infiniteDataSource!.cellForItemAtIndexPath(self, dequeueIndexPath: indexPath, usableIndexPath: IndexPath(row: getCorrectedIndex(indexPath.row - indexOffset), section: 0))
    }

    fileprivate func getCorrectedIndex(_ indexToCorrect: Int) -> Int {
        guard let numberOfCells = infiniteDataSource?.numberOfItems(self), numberOfCells > 0 else {
            return 0
        }

        guard indexToCorrect < 0 || indexToCorrect >= numberOfCells else {
            return indexToCorrect
        }

        return (indexToCorrect % numberOfCells + numberOfCells) % numberOfCells
    }
}

// MARK: UICollectionViewDelegate

extension InfiniteCollectionView: UICollectionViewDelegate {
    public func collectionView(_: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        infiniteDelegate?.didSelectCellAtIndexPath(self, usableIndexPath: IndexPath(row: getCorrectedIndex(indexPath.row - indexOffset), section: 0))
    }

    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        infiniteDelegate?.willBeginDragging(scrollView)
    }
}

public extension InfiniteCollectionView {
    override var dataSource: UICollectionViewDataSource? {
        didSet {
            if let dataSource, !dataSource.isEqual(self) {
                Logger.shared.error("WARNING: UICollectionView DataSource must not be modified.  Set infiniteDataSource instead.")
                self.dataSource = self
            }
        }
    }

    override var delegate: UICollectionViewDelegate? {
        didSet {
            if let delegate, !delegate.isEqual(self) {
                Logger.shared.error("WARNING: UICollectionView delegate must not be modified.  Set infiniteDelegate instead.")
                self.delegate = self
            }
        }
    }
}
