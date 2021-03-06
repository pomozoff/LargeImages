//
//  ImageListViewController.swift
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

typealias CancelToken = () -> Void

protocol ImagePresenter: AnyObject {
    func updateState(_ state: FetchingState)
    func didUpdateURLs(with diff: CollectionDifference<URL>, updateData: @escaping () -> Void, completion: @escaping () -> Void)
}

class ImageListViewModel {
    weak var presenter: ImagePresenter?

    init(
        directoryReadable: DirectoryReadable,
        imageFetchable: ImageFetchable
    ) {
        self.directoryReadable = directoryReadable
        self.imageFetchable = imageFetchable
    }

    private var items: [Item] = []

    private let directoryReadable: DirectoryReadable
    private let imageFetchable: ImageFetchable

    private let disposeBag = DisposeBag()
    private let updateSemaphore = DispatchSemaphore(value: 1)

    private let dataSourceBag = UnsafeBag<([Change]) -> Void>()
}

extension ImageListViewModel {
    var numberOfItems: Int {
        items.count
    }

    func fetchImages() {
        directoryReadable
            .didUpdateDirectory { [weak self] result in
                self?.processDirectoryResult(result)
            }
            .disposed(by: disposeBag)

        presenter?.updateState(.fetching)
        DispatchQueue.global(qos: .userInitiated).async { [weak directoryReadable] in
            directoryReadable?.start()
        }
    }

    func makeImageCellViewModel(for index: Int, with size: CGSize, completion: @escaping (ImageCellViewModel) -> Void) -> CancelToken? {
        let item = items[index]
        if let image = item.image {
            completion(ImageCellViewModel(state: .idle, image: image))
            return nil
        }

        completion(ImageCellViewModel(state: .fetching, image: nil))
        return imageFetchable.fetchImage(
            from: item.url,
            with: size,
            on: DispatchQueue.global(qos: .userInitiated),
            completion: { [weak self] result in
                self?.processFetchingImageResult(result, completion: completion)
            }
        )
    }
}

extension ImageListViewModel: ViewModel {}

private extension ImageListViewModel {
    func processDirectoryResult(_ result: DirectoryReaderResult) {
        switch result {
        case let .success(urls):
            updateSemaphore.wait()

            let diff = urls.difference(from: self.items.map(\.url))
            let newItems = urls.map { url in
                Item(
                    url: url,
                    image: self.items.first { $0.url == url }?.image
                )
            }

            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }

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

        case let .failure(error):
            DispatchQueue.main.async {
                self.presenter?.updateState(.error(error))
            }
        }
    }

    func processFetchingImageResult(_ result: ImageFetcherResult, completion: @escaping (ImageCellViewModel) -> Void) {
        DispatchQueue.main.async { [weak presenter] in
            switch result {
            case let .success(image):
                completion(ImageCellViewModel(state: .idle, image: image))

            case let .failure(error):
                completion(ImageCellViewModel(state: .error(error), image: nil))
                presenter?.updateState(.error(error))
            }
        }
    }
}

private struct Item {
    let url: URL
    var image: UIImage?
}

extension Item: Equatable {}
