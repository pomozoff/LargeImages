//
//  ImageFetchable.swift
//  LargeImages
//
//  Created by Anton Pomozov on 18.04.2020.
//  Copyright © 2020 Akademon. All rights reserved.
//

import ObjectiveC
import UIKit

typealias ImageFetcherResult = Result<UIImage, Error>

protocol ImageFetchable: AnyObject {
    func fetchImage(
        from url: URL,
        with size: CGSize,
        completion: @escaping (ImageFetcherResult) -> Void
    ) -> CancelToken?
}

class ImageFetcher {
    init(imageResizable: ImageResizable) {
        self.imageResizable = imageResizable
    }

    private let imageResizable: ImageResizable

    private let syncQueue = DispatchQueue(
        label: "ru.akademon.largeimages.images-sync-queue",
        qos: .userInitiated
    )

    private let workerQueue = DispatchQueue(
        label: "ru.akademon.largeimages.images-worker-queue",
        qos: .userInitiated,
        attributes: .concurrent
    )

    @Atomic
    private var workers: [URL: DispatchWorkItem] = [:]
}

extension ImageFetcher: ImageFetchable {
    func fetchImage(
        from url: URL,
        with size: CGSize,
        completion: @escaping (ImageFetcherResult) -> Void
    ) -> CancelToken? {
        let worker = DispatchWorkItem { [weak self] in
            NSLog("XXX - Perform worker for file: \(url.lastPathComponent)")
            guard let self = self else { return }

            let result = self.imageResizable.resizedImage(at: url, for: size)
            completion(result.map { UIImage(cgImage: $0) })
            NSLog("XXX - Completed worker for file: \(url.lastPathComponent)")

            self.removeWorker(for: url)
        }

        addWorker(worker, for: url)

        return { [weak self, weak worker] in
            NSLog("XXX - Cancel token - for file: \(url.lastPathComponent)")

            if let worker = worker, !worker.isCancelled {
                NSLog("XXX - Cancel worker: \(worker) for file: \(url.lastPathComponent)")
                worker.cancel()
            }

            self?.removeWorker(for: url)
        }
    }
}

private extension ImageFetcher {
    func addWorker(_ worker: DispatchWorkItem, for url: URL) {
        $workers.mutate {
            if let currentWorker = $0[url], !currentWorker.isCancelled { return }

            NSLog("XXX - Add worker: \(worker) for file: \(url.lastPathComponent)")

            $0[url] = worker
            guard !$0.map({ !$0.value.isExecuting }).isEmpty else { return }

            executeWorkers()
        }
    }

    func removeWorker(for url: URL) {
        $workers.mutate {
            guard let worker = $0[url] else { return }

            $0.removeValue(forKey: url)
            NSLog("XXX - Removed worker: \(worker) for file: \(url.lastPathComponent)")
        }
    }

    func executeWorkers() {
        syncQueue.async { [weak self] in
            while true {
                guard let self = self else { break }

                var firstWorkerPair: (key: URL, value: DispatchWorkItem)?
                self.$workers.mutate {
                    firstWorkerPair = $0.first {
                        !$0.value.isExecuting
                    }
                }

                guard let workerPair = firstWorkerPair else { break }

                if !workerPair.value.isCancelled, !workerPair.value.isExecuting {
                    workerPair.value.isExecuting = true
                    self.workerQueue.async(execute: workerPair.value)
                }
            }
        }
    }
}

private extension DispatchWorkItem {
    var isExecuting: Bool {
        get {
            return objc_getAssociatedObject(self, &isExecutingObject) as? Bool ?? false
        }
        set {
            objc_setAssociatedObject(self, &isExecutingObject, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

private var isExecutingObject: UInt8 = 0
