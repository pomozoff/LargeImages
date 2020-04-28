//
//  PinterestLayout.swift
//  LargeImages
//
//  Created by Anton Pomozov on 19.04.2020.
//  Copyright © 2020 Akademon. All rights reserved.
//

import UIKit

protocol PinterestLayoutDelegate: AnyObject {
    func collectionView(_ collectionView: UICollectionView, heightForPhotoAtIndexPath indexPath: IndexPath) -> CGFloat
}

class PinterestLayout: UICollectionViewLayout {
    weak var delegate: PinterestLayoutDelegate?

    var cellPadding: CGFloat = 4.0 {
        didSet {
            invalidateLayout()
        }
    }

    var columnWidth: CGFloat {
        contentWidth / CGFloat(numberOfColumns)
    }

    // MARK: - Life cycle

    init(numberOfColumns: Int) {
        self.numberOfColumns = numberOfColumns
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func invalidateLayout() {
        cache.removeAll()
        super.invalidateLayout()
    }

    override var collectionViewContentSize: CGSize {
        return CGSize(width: contentWidth, height: contentHeight)
    }

    override func prepare() {
        guard
            cache.isEmpty,
            let collectionView = collectionView
        else { return }

        var xOffset: [CGFloat] = []
        for column in 0..<numberOfColumns {
            xOffset.append(CGFloat(column) * columnWidth)
        }

        var maxHeight: [Int: CGFloat] = [:]
        var column = 0
        var yOffset: [CGFloat] = .init(repeating: 0, count: numberOfColumns)

        for item in 0..<collectionView.numberOfItems(inSection: 0) {
            let indexPath = IndexPath(item: item, section: 0)

            let photoHeight = delegate?.collectionView(
                collectionView,
                heightForPhotoAtIndexPath: indexPath) ?? 100.0

            let height = cellPadding + photoHeight
            let frame = CGRect(
                x: xOffset[column],
                y: yOffset[column],
                width: columnWidth,
                height: height
            )
            let insetFrame = frame.insetBy(dx: cellPadding, dy: cellPadding)

            let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            attributes.frame = insetFrame
            cache.append(attributes)

            yOffset[column] = yOffset[column] + height
            maxHeight[column] = frame.maxY

            column = (column + 1) % numberOfColumns
        }
        contentHeight = maxHeight.values.max() ?? contentHeight
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        cache.filter {
            $0.frame.intersects(rect)
        }
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        cache[indexPath.item]
    }

    // MARK: - Private

    private let numberOfColumns: Int

    private var cache: [UICollectionViewLayoutAttributes] = []

    private var contentHeight: CGFloat = 0.0

    private var contentWidth: CGFloat {
        guard let collectionView = collectionView else { return .zero }

        let insets = collectionView.contentInset
        return collectionView.bounds.width - (insets.left + insets.right)
    }
}
