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

extension URL {
    static var documents: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
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

    func isDirectory() throws -> Bool {
        (try resourceValues(forKeys: [.isDirectoryKey])).isDirectory ?? false
    }
}
