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
        completion: @escaping (UIImage) -> Void
    ) -> CancelToken?
}

class ImageFetcher {
    init(imageResizable: ImageResizable, maxTasksNumber: Int) {
        self.imageResizable = imageResizable
        workersSemaphore = DispatchSemaphore(value: maxTasksNumber)
    }

    private let imageResizable: ImageResizable
    private let pollingTimeout = 500

    private let workerQueue = DispatchQueue(
        label: "ru.akademon.largeimages.images-worker-queue",
        qos: .userInitiated,
        attributes: .concurrent
    )

    private let workersSemaphore: DispatchSemaphore

    @Atomic
    private var workers: [UUID: DispatchWorkItem] = [:]

    @Atomic
    private var hasWorkers = false
}

extension ImageFetcher: ImageFetchable {
    func fetchImage(
        from url: URL,
        with size: CGSize,
        completion: @escaping (UIImage) -> Void
    ) -> CancelToken? {
        let uuid = UUID()
        let worker = DispatchWorkItem { [weak self] in
            defer {
                NSLog("ZZZ - signal - worker's job done: \(uuid)")
//                self?.workersSemaphore.signal()
            }

            guard let self = self else { return }
            NSLog("ZZZ - start worker: \(uuid), file: \(url.lastPathComponent)")

            let result = self.imageResizable.resizedImage(at: url, for: size)
            switch result {
            case let .success(image):
                NSLog("ZZZ - worker succeeded: \(uuid), file: \(url.lastPathComponent)")
                self.removeWorker(for: uuid)
                completion(UIImage(cgImage: image))

            case let .failure(error):
                NSLog("ZZZ - worker failed: \(uuid), file: \(url.lastPathComponent), error: \(error)")
                if case ImageResizerError.noFile = error {
                    NSLog("ZZZ - file removed: \(url.lastPathComponent)")
                    return self.removeWorker(for: uuid)
                }

                self.$workers.mutate {
                    NSLog("ZZZ - pause worker: \(uuid), file: \(url.lastPathComponent)")
                    $0[uuid]?.isExecuting = false
                }
            }
        }

        NSLog("ZZZ - add worker: \(uuid), file \(url.lastPathComponent)")
        addWorker(worker, for: uuid)

        return { [weak self] in
            NSLog("ZZZ - cancel worker: \(uuid), file: \(url.lastPathComponent)")
            self?.removeWorker(for: uuid)
        }
    }
}

private extension ImageFetcher {
    func addWorker(_ worker: DispatchWorkItem, for uuid: UUID) {
        $workers.mutate {
            $0[uuid] = worker
        }

        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }

            guard !self.hasWorkers else { return }

            self.hasWorkers = true
            self.executeWorkers()
        }
    }

    func removeWorker(for uuid: UUID) {
        NSLog("ZZZ - remove worker: \(uuid)")
        $workers.mutate {
            if let worker = $0[uuid] {
                worker.cancel()
                worker.isExecuting = false
            }
            $0.removeValue(forKey: uuid)
        }
//        workersSemaphore.signal()
    }

    func executeWorkers() {
        NSLog("ZZZ - execute workers")

        while hasWorkers {
//            NSLog("ZZZ - wait")
//            workersSemaphore.wait()

            var firstWorkerPair: (key: UUID, value: DispatchWorkItem)?
            $workers.mutate { [weak self] in
                guard let self = self else { return }

                guard !$0.isEmpty else {
                    NSLog("ZZZ - signal - no workers")
                    self.hasWorkers = false
//                    self.workersSemaphore.signal()

                    return
                }

                firstWorkerPair = $0.first {
                    !$0.value.isExecuting && !$0.value.isCancelled
                }

                guard let workerPair = firstWorkerPair else {
                    return
                }

                workerPair.value.isExecuting = true
                self.workerQueue.asyncAfter(
                    deadline: .now() + .milliseconds(pollingTimeout),
                    execute: workerPair.value
                )
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
