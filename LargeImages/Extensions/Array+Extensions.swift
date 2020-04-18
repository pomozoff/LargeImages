//
//  Array+Extensions.swift
//  LargeImages
//
//  Created by Anton Pomozov on 18.04.2020.
//  Copyright © 2020 Akademon. All rights reserved.
//

import Foundation

extension Array where Element: Equatable {
    // TODO: Use Heckel algorithm when it will be allowed
    func changes(from original: Self) -> [Change] {
        var result: [Change] = []

        var originalIndex = 0
        var originalItems = original

        while originalIndex < originalItems.count {
            let originalItem = originalItems[originalIndex]
            guard let newIndex = firstIndex(of: originalItem) else {
                result.append(.delete(at: originalIndex))
                originalItems.remove(at: originalIndex)

                continue
            }

            defer { originalIndex += 1 }
            guard newIndex != originalIndex else { continue }

            result.append(.move(from: originalIndex, to: newIndex))
//            originalItems.swapAt(originalIndex, newIndex)
        }

        for (newIndex, newItem) in enumerated() {
            guard let _ = original.firstIndex(of: newItem) else {
                result.append(.insert(at: newIndex))
                continue
            }
        }

        return result
    }
}
