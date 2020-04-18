//
//  DispatchWorkItem+Extensions.swift
//  LargeImages
//
//  Created by Anton Pomozov on 18.04.2020.
//  Copyright © 2020 Akademon. All rights reserved.
//

import Foundation

extension DispatchWorkItem: Equatable {
    public static func == (lhs: DispatchWorkItem, rhs: DispatchWorkItem) -> Bool {
        lhs === rhs
    }
}

extension DispatchWorkItem: CustomDebugStringConvertible {
    public var debugDescription: String {
        String("\(Unmanaged.passUnretained(self).toOpaque())")
    }
}
