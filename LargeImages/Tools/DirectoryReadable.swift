//
//  DirectoryReadable.swift
//  LargeImages
//
//  Created by Anton Pomozov on 16.04.2020.
//  Copyright © 2020 Akademon. All rights reserved.
//

import Foundation

enum DirectoryReaderError: Error {
    case notDirectory
}

typealias DirectoryReaderResult = Result<[URL], Error>

protocol DirectoryReadable: AnyObject {
    var isStarted: Bool { get }

    func start()
    func refresh()

    func didUpdate(_ action: @escaping (DirectoryReaderResult) -> Void) -> Disposable
}

class DirectoryReader {
    @Atomic
    private(set) var isStarted = false

    init(
        url: URL,
        queue: DispatchQueue
    ) {
        self.url = url
        self.backgroundQueue = queue
        self.documentsDirectoryDescriptor = open(url.path, O_EVTONLY)

        directorySource = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: self.documentsDirectoryDescriptor,
            eventMask: .all,
            queue: queue
        )

        directorySource.setEventHandler { [unowned self] in
            self.fetchContentOfDirectory()
        }
    }

    deinit {
        directorySource.cancel()
        close(documentsDirectoryDescriptor)
    }

    private let url: URL
    private let backgroundQueue: DispatchQueue
    private let documentsDirectoryDescriptor: CInt
    private let directorySource: DispatchSourceProtocol

    private let updateDirectoryBag = UnsafeBag<(DirectoryReaderResult) -> Void>()

    private let syncQueue = DispatchQueue(
        label: "ru.akademon.largeimages.files-sync-queue",
        qos: .userInitiated
    )
}

extension DirectoryReader: DirectoryReadable {
    func start() {
        guard !isStarted else { return }

        isStarted = true
        refresh()
        directorySource.activate()
    }

    func refresh() {
        backgroundQueue.async { [weak self] in
            self?.fetchContentOfDirectory()
        }
    }

    func didUpdate(_ action: @escaping (DirectoryReaderResult) -> Void) -> Disposable {
        updateDirectoryBag.insert(action)
    }
}

private extension DirectoryReader {
    func updateReadyFiles(result: DirectoryReaderResult) {
        updateDirectoryBag.forEach { $0(result) }
    }

    func fetchContentOfDirectory() {
        guard url.isDirectory else {
            updateReadyFiles(result: .failure(DirectoryReaderError.notDirectory))
            return
        }

        let resourceKeys: [URLResourceKey] = [.isRegularFileKey, .isReadableKey]
        do {
            let files: [URL] = try FileManager.default.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: resourceKeys,
                options: .skipsHiddenFiles
            ).filter {
                $0.isRegularFile && $0.isReadable && $0.isImage
            }

            updateReadyFiles(result: .success(files))

        } catch {
            updateReadyFiles(result: .failure(error))
        }
    }
}
