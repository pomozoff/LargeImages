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
    init(imageResizable: ImageResizable, maxTasksNumber: Int) {
        self.imageResizable = imageResizable
        workersSemaphore = DispatchSemaphore(value: maxTasksNumber)
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

    private let workersSemaphore: DispatchSemaphore

    @Atomic
    private var workers: [UUID: DispatchWorkItem] = [:]
}

extension ImageFetcher: ImageFetchable {
    func fetchImage(
        from url: URL,
        with size: CGSize,
        completion: @escaping (ImageFetcherResult) -> Void
    ) -> CancelToken? {
        let worker = DispatchWorkItem { [weak self] in
            defer {
                self?.workersSemaphore.signal()
            }

            guard let self = self else { return }

            let result = self.imageResizable.resizedImage(at: url, for: size)
            completion(result.map { UIImage(cgImage: $0) })
        }

        let uuid = addWorker(worker)
        return { [weak self, weak worker] in
            if let worker = worker, !worker.isCancelled {
                worker.cancel()
            }

            self?.removeWorker(for: uuid)
        }
    }
}

private extension ImageFetcher {
    func addWorker(_ worker: DispatchWorkItem) -> UUID {
        let uuid = UUID()

        $workers.mutate {
            $0[uuid] = worker
            guard $0.map(\.value.isExecuting).filter({ $0 }).isEmpty else { return }
            executeWorkers()
        }

        return uuid
    }

    func removeWorker(for uuid: UUID) {
        $workers.mutate {
            $0.removeValue(forKey: uuid)
        }
    }

    func executeWorkers() {
        syncQueue.async { [weak self] in
            while true {
                guard let self = self else { break }

                self.workersSemaphore.wait()

                var firstWorkerPair: (key: UUID, value: DispatchWorkItem)?
                self.$workers.mutate {
                    firstWorkerPair = $0.first {
                        !$0.value.isExecuting
                    }
                }

                guard let workerPair = firstWorkerPair else {
                    self.workersSemaphore.signal()
                    break
                }

                if !workerPair.value.isCancelled, !workerPair.value.isExecuting {
                    workerPair.value.isExecuting = true

                    self.workerQueue.async(execute: workerPair.value)
                    self.removeWorker(for: workerPair.key)
                } else {
                    self.workersSemaphore.signal()
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
