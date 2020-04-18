//
//  ImageIOResizer.swift
//  LargeImages
//
//  Created by Anton Pomozov on 18.04.2020.
//  Copyright © 2020 Akademon. All rights reserved.
//

import CoreGraphics
import Foundation
import ImageIO

class ImageIOResizer {}

extension ImageIOResizer: ImageResizable {
    func resizedImage(at url: URL, for size: CGSize) -> ImageResizerResult {
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageIfAbsent: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: max(size.width, size.height)
        ]

        guard let imageSource = CGImageSourceCreateWithURL(url as NSURL, nil),
            let image = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary)
        else {
            return .failure(ImageResizerError.invalidFile(url))
        }

        return .success(image)
    }
}
