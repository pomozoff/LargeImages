//
//  ContextImageResizer.swift
//  LargeImages
//
//  Created by Anton Pomozov on 25.04.2020.
//  Copyright © 2020 Akademon. All rights reserved.
//

import CoreGraphics
import Foundation
import ImageIO

class ContextImageResizer {}

extension ContextImageResizer: ImageResizable {
    func resizedImage(at url: URL, for size: CGSize) -> ImageResizerResult {
        guard let imageSource = CGImageSourceCreateWithURL(NSURL(fileURLWithPath: url.path), nil) else {
            return .failure(ImageResizerError.noFile(url))
        }

        guard let image = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            return .failure(ImageResizerError.invalidFile(url))
        }

        guard let context = CGContext(
            data: nil,
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: image.bitsPerComponent,
            bytesPerRow: image.bytesPerRow,
            space: image.colorSpace ?? CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: image.bitmapInfo.rawValue
        ) else {
            return .failure(ImageResizerError.contextFail(url))
        }

        context.interpolationQuality = .high
        context.draw(image, in: CGRect(origin: .zero, size: size))

        guard let scaledImage = context.makeImage() else {
            return .failure(ImageResizerError.scaleFail(url))
        }

        return .success(scaledImage)
    }
}
