//
//  URL+Extensions.swift
//  LargeImages
//
//  Created by Anton Pomozov on 16.04.2020.
//  Copyright © 2020 Akademon. All rights reserved.
//

import CoreGraphics
import Foundation
import ImageIO
import MobileCoreServices

extension URL {
    static var documents: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    var isDirectory: Bool {
        (resourceValue(forKey: .isDirectoryKey) as Bool?) ?? false
    }

    var isRegularFile: Bool {
        (resourceValue(forKey: .isRegularFileKey) as Bool?) ?? false
    }

    var isReadable: Bool {
        (resourceValue(forKey: .isReadableKey) as Bool?) ?? false
    }

    var fileSize: Int {
        (resourceValue(forKey: .fileSizeKey) as Int?) ?? 0
    }

    var isImage: Bool {
        guard
            let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension as CFString, nil),
            UTTypeConformsTo((uti.takeUnretainedValue()), kUTTypeImage)
        else { return false }

        return true
    }

    var sizeOfImage: CGSize {
        guard let source = CGImageSourceCreateWithURL(self as CFURL, nil) else { return .zero }
        guard let cfImageHeader = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) else { return .zero }

        let imageHeader = cfImageHeader as Dictionary
        guard let width = imageHeader[kCGImagePropertyPixelWidth] as? CGFloat,
            let height = imageHeader[kCGImagePropertyPixelHeight] as? CGFloat
            else { return .zero }

        return CGSize(width: width, height: height)
    }

    func resourceValues(forKeys keys: Set<URLResourceKey>) -> [URLResourceKey: Any] {
        (try? resourceValues(forKeys: keys))?.allValues ?? [:]
    }

    func resourceValue<T>(forKey key: URLResourceKey) -> T? {
        resourceValues(forKeys: [key])[key] as? T
    }
}
