//
//  DirectoryReader.swift
//  LargeImages
//
//  Created by Anton Pomozov on 16.04.2020.
//  Copyright © 2020 Akademon. All rights reserved.
//

import Foundation

protocol DirectoryReadable: AnyObject {
}

class DirectoryReader {
    init(directory: URL) {
        self.directory = directory
    }

    private let directory: URL
}

extension DirectoryReader: DirectoryReadable {}
