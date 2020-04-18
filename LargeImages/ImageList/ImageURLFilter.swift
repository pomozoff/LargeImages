//
//  ImageURLFilter.swift
//  LargeImages
//
//  Created by Anton Pomozov on 17.04.2020.
//  Copyright © 2020 Akademon. All rights reserved.
//

import Foundation
import MobileCoreServices

protocol ImageURLChecker: AnyObject {
    func check(url: URL) -> URL?
}

class ImageURLFilter {}

extension ImageURLFilter: ImageURLChecker {
    func check(url: URL) -> URL? {
        guard
            let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, url.pathExtension as CFString, nil),
            UTTypeConformsTo((uti.takeUnretainedValue()), kUTTypeImage)
        else { return nil }

        return url
    }
}
