//
//  Change.swift
//  LargeImages
//
//  Created by Anton Pomozov on 16.04.2020.
//  Copyright © 2020 Akademon. All rights reserved.
//

import Foundation

enum Change {
    case insert(at: Int)
    case delete(at: Int)
    case reload(at: Int)
    case move(from: Int, to: Int)
}

extension Change: Equatable {}
