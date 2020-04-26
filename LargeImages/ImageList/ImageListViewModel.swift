//
//  ImageListViewModel.swift
//  LargeImages
//
//  Created by Anton Pomozov on 15.04.2020.
//  Copyright © 2020 Akademon. All rights reserved.
//

import UIKit

// TODO: <T>
enum FetchingState {
    case idle
    case fetching
    case error(Error)
}

typealias CancelToken = () -> Void

protocol ImagePresenter: AnyObject {
    func updateState(_ state: FetchingState)
    func didUpdateItems(with diff: CollectionDifference<URL>, updateData: @escaping () -> Void, completion: @escaping () -> Void)
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

    @Atomic
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

    func startFetchingImages() {
        guard !directoryReadable.isStarted else { return }

        directoryReadable
            .didUpdate { [weak self] result in
                self?.processDirectoryResult(result)
            }
            .disposed(by: disposeBag)

        presenter?.updateState(.fetching)
        DispatchQueue.global(qos: .userInitiated).async { [weak directoryReadable] in
            directoryReadable?.start()
        }
    }

    func refreshImages() {
        presenter?.updateState(.fetching)
        directoryReadable.refresh()
    }

    func sizeOfImage(for index: Int, with width: CGFloat) -> CGSize {
        items[index].image?.size.aspectSize(for: width) ?? CGSize(width: width, height: width)
    }

    func makeImageCellViewModel(for index: Int, with width: CGFloat, completion: @escaping (ImageCellViewModel) -> Void) -> CancelToken? {
        let item = items[index]

        if let image = item.image {
            DispatchQueue.main.async {
                completion(ImageCellViewModel(
                    state: .idle,
                    url: item.url,
                    size: image.size,
                    image: image)
                )
            }
            return nil
        }

        let size = CGSize(width: width, height: width)
        completion(ImageCellViewModel(
            state: .fetching,
            url: item.url,
            size: size,
            image: nil)
        )

        return imageFetchable.fetchImage(
            from: item.url,
            with: size,
            completion: { [weak self] image in
                DispatchQueue.main.async { [weak self] in
                    self?.updateImage(image, for: item.url, completion: completion)
                }
            }
        )
    }
}

extension ImageListViewModel: ViewModel {}

private extension ImageListViewModel {
    func processDirectoryResult(_ result: DirectoryReaderResult) {
        switch result {
        case let .success(urls):
            assert(!Thread.isMainThread)

            updateSemaphore.wait()
            let diff = urls.difference(from: self.items.map(\.url))

            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }

                self.presenter?.updateState(.idle)
                self.presenter?.didUpdateItems(
                    with: diff,
                    updateData: { [weak self] in
                        self?.$items.mutate { items in
                            items = urls.enumerated().map { (index, url) in
                                Item(
                                    url: url,
                                    image: items.first { $0.url == url }?.image
                                )
                            }
                        }
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

    func updateImage(_ image: UIImage, for url: URL, completion: @escaping (ImageCellViewModel) -> Void) {
        $items.mutate {
            guard let index = $0.firstIndex(where: { $0.url == url }) else {
                return
            }
            $0[index].image = image
        }

        completion(ImageCellViewModel(
            state: .idle,
            url: url,
            size: image.size,
            image: image)
        )
    }
}

private struct Item {
    let url: URL
    var image: UIImage?
}

extension Item: Equatable {}
