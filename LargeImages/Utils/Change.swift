//
//  Change.swift
//  LargeImages
//
//  Created by Anton Pomozov on 16.04.2020.
//  Copyright © 2020 Akademon. All rights reserved.
//

import Foundation

enum Change {
    case insert(at: IndexPath)
    case delete(at: IndexPath)
    case reload(at: IndexPath)
    case move(from: IndexPath, to: IndexPath)
}
