//
//  UICollectionView+Extensions.swift
//  LargeImages
//
//  Created by Anton Pomozov on 16.04.2020.
//  Copyright © 2020 Akademon. All rights reserved.
//

import UIKit

extension UICollectionView {
    func dequeueReusableCell<T: UICollectionViewCell>(at indexPath: IndexPath) -> T {
        dequeueReusableCell(withReuseIdentifier: T.reuseIdentifier, for: indexPath) as! T
    }

    func applyChanges(_ diff: CollectionDifference<URL>, updateData: @escaping () -> Void, completion: @escaping () -> Void) {
        var deletedIndexPaths = [IndexPath]()
        var insertedIndexPaths = [IndexPath]()

        for change in diff {
            switch change {
            case let .remove(offset, _, _):
                deletedIndexPaths.append(IndexPath(row: offset, section: 0))
            case let .insert(offset, _, _):
                insertedIndexPaths.append(IndexPath(row: offset, section: 0))
            }
        }

        updateData()

        performBatchUpdates(
            {
                deleteItems(at: deletedIndexPaths)
                insertItems(at: insertedIndexPaths)
            },
            completion: { finished in
                completion()
            }
        )
    }
}
