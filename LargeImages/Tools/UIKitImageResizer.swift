//
//  UIKitImageResizer.swift
//  LargeImages
//
//  Created by Anton Pomozov on 18.04.2020.
//  Copyright © 2020 Akademon. All rights reserved.
//

import UIKit

class UIKitImageResizer {}

extension UIKitImageResizer: ImageResizable {
    func resizedImage(at url: URL, for size: CGSize) -> ImageResizerResult {
        guard let image = UIImage(contentsOfFile: url.path) else {
            return .failure(ImageResizerError.invalidFile(url))
        }

        let renderer = UIGraphicsImageRenderer(size: size)
        guard let cgImage = renderer.image(
            actions: { context in
                image.draw(in: CGRect(origin: .zero, size: size))
            }).cgImage
        else {
            return .failure(ImageResizerError.unknown)
        }

        return .success(cgImage)
    }
}
