//
//  CollectionViewModel.swift
//  LargeImages
//
//  Created by Anton Pomozov on 15.04.2020.
//  Copyright © 2020 Akademon. All rights reserved.
//

import UIKit

class CollectionViewModel {
    init(directoryReadable: DirectoryReadable) {
        self.directoryReadable = directoryReadable
    }

    func imageCellViewModel(for index: Int, size: CGSize, completion: @escaping (ImageCellViewModel) -> Void) {
        if let image = items[index].image {
            return completion(ImageCellViewModel(image: image))
        }

        DispatchQueue.global(qos: .userInitiated).async {
            DispatchQueue.main.async {
                let image = UIImage()
                completion(ImageCellViewModel(image: image))
            }
        }
    }

    func didUpdateDataSource(_ action: @escaping ([Change]) -> Void) -> Disposable {
        dataSourceBag.insert(action)
    }

    private let dataSourceBag = UnsafeBag<([Change]) -> Void>()
    private let directoryReadable: DirectoryReadable

    private var items: [Items] = []
}

extension CollectionViewModel {
    var numberOfItems: Int {
        items.count
    }
}

extension CollectionViewModel: ViewModel {}

private struct Items {
    let url: URL
    var image: UIImage?
}
