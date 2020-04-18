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

protocol DirectoryReadable: Worker {
    func didUpdateDirectory(_ action: @escaping (DirectoryReaderResult) -> Void) -> Disposable
}

class DirectoryReader {
    var imageFilter: ImageURLChecker?

    init(url: URL) {
        self.url = url
        self.fileDescriptor = open(url.path, O_EVTONLY)
        self.source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: self.fileDescriptor,
            eventMask: .all,
            queue: DispatchQueue.global(qos: .background)
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
    private let updateDirectoryBag = UnsafeBag<(DirectoryReaderResult) -> Void>()

    private let fileDescriptor: CInt
    private let source: DispatchSourceProtocol
}

extension DirectoryReader: DirectoryReadable {
    func didUpdateDirectory(_ action: @escaping (DirectoryReaderResult) -> Void) -> Disposable {
        updateDirectoryBag.insert(action)
    }
}

extension DirectoryReader: Worker {
    func start() {
        fetchContentOfDirectory()
        source.resume()
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
