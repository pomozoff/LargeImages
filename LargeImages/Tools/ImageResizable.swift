//
//  ImageResizable.swift
//  LargeImages
//
//  Created by Anton Pomozov on 18.04.2020.
//  Copyright © 2020 Akademon. All rights reserved.
//

import CoreGraphics
import Foundation

typealias ImageResizerResult = Result<CGImage, Error>

enum ImageResizerError: Error {
    case noFile(URL)
    case invalidFile(URL)
    case contextFail(URL)
    case scaleFail(URL)
    case unknown
}

protocol ImageResizable: AnyObject {
    func resizedImage(at url: URL, for size: CGSize) -> ImageResizerResult
}
