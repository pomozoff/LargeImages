//
//  CGSize+Extensions.swift
//  LargeImages
//
//  Created by Anton Pomozov on 18.04.2020.
//  Copyright © 2020 Akademon. All rights reserved.
//

import AVFoundation
import CoreGraphics

extension CGSize {
    static func *(lhs: CGSize, rhs: CGFloat) -> CGSize {
        CGSize(width: lhs.width * rhs, height: lhs.height * rhs)
    }

    func aspectSize(for width: CGFloat) -> CGSize {
        AVMakeRect(
            aspectRatio: self,
            insideRect: CGRect(x: 0.0, y: 0.0, width: width, height: width)
        ).size
    }
}
