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

    var imageFilter: ImageURLChecker?

    init(
        url: URL,
        queue: DispatchQueue
    ) {
        self.url = url
        self.queue = queue
        self.fileDescriptor = open(url.path, O_EVTONLY)

        self.source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: self.fileDescriptor,
            eventMask: .write,
            queue: queue
        )
        self.source.setEventHandler { [unowned self] in
            self.fetchContentOfDirectory()
        }
    }

    deinit {
        source.cancel()
        close(fileDescriptor)
    }

    private let url: URL
    private let queue: DispatchQueue
    private let fileDescriptor: CInt
    private let source: DispatchSourceProtocol

    private let updateDirectoryBag = UnsafeBag<(DirectoryReaderResult) -> Void>()
}

extension DirectoryReader: DirectoryReadable {
    func start() {
        guard !isStarted else { return }

        isStarted = true
        refresh()
        source.resume()
    }

    func refresh() {
        queue.async { [weak self] in
            self?.fetchContentOfDirectory()
        }
    }

    func didUpdate(_ action: @escaping (DirectoryReaderResult) -> Void) -> Disposable {
        updateDirectoryBag.insert(action)
    }
}

private extension DirectoryReader {
    func processResult(result: DirectoryReaderResult) {
        updateDirectoryBag.forEach { $0(result) }
    }

    func fetchContentOfDirectory() {
        do {
            guard try url.isDirectory() else {
                processResult(result: .failure(DirectoryReaderError.notDirectory))
                return
            }
        } catch {
            processResult(result: .failure(error))
        }

        do {
            let files: [URL] = try FileManager.default.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: .skipsHiddenFiles
            ).compactMap { [weak imageFilter] in
                return imageFilter?.check(url: $0)
            }

            processResult(result: .success(files))

        } catch {
            processResult(result: .failure(error))
        }
    }
}
