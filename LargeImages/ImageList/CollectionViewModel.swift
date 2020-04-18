//
//  CollectionViewModel.swift
//  LargeImages
//
//  Created by Anton Pomozov on 15.04.2020.
//  Copyright © 2020 Akademon. All rights reserved.
//

import UIKit

enum FetchingState {
    case idle
    case fetching
    case error(Error)
}

protocol ImagePresenter: AnyObject {
    func updateState(_ state: FetchingState)
    func didUpdateURLs(with diff: CollectionDifference<URL>, updateData: @escaping () -> Void, completion: @escaping () -> Void)
}

class CollectionViewModel {
    weak var presenter: ImagePresenter?

    init(directoryReadable: DirectoryReadable) {
        self.directoryReadable = directoryReadable
    }

    private let dataSourceBag = UnsafeBag<([Change]) -> Void>()
    private let directoryReadable: DirectoryReadable

    private var items: [Item] = []

    private let disposeBag = DisposeBag()
    private let updateSemaphore = DispatchSemaphore(value: 1)
}

extension CollectionViewModel {
    var numberOfItems: Int {
        items.count
    }

    func fetchImages() {
        directoryReadable
            .didUpdateDirectory { [weak self] result in
                guard let self = self else { return }

                switch result {
                case let .success(urls):
                    self.processNewURLs(urls)

                case let .failure(error):
                    DispatchQueue.main.async {
                        self.presenter?.updateState(.error(error))
                    }
                }
            }
            .disposed(by: disposeBag)

        presenter?.updateState(.fetching)
        DispatchQueue.global(qos: .userInitiated).async { [weak directoryReadable] in
            directoryReadable?.start()
        }
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
}

extension CollectionViewModel: ViewModel {}

private extension CollectionViewModel {
    func processNewURLs(_ urls: [URL]) {
        updateSemaphore.wait()

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            let diff = urls.difference(from: self.items.map(\.url))
            let newItems = urls.map { url in
                Item(
                    url: url,
                    image: self.items.first { $0.url == url }?.image
                )
            }

            self.presenter?.updateState(.idle)
            self.presenter?.didUpdateURLs(
                with: diff,
                updateData: {
                    self.items = newItems
                }, completion: { [weak self] in
                    self?.updateSemaphore.signal()
                }
            )
        }
    }
}

private struct Item {
    let url: URL
    var image: UIImage?
}

extension Item: Equatable {}
