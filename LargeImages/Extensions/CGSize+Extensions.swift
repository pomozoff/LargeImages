//
//  CGSize+Extensions.swift
//  LargeImages
//
//  Created by Anton Pomozov on 18.04.2020.
//  Copyright © 2020 Akademon. All rights reserved.
//

import CoreGraphics

extension CGSize {
    static func *(lhs: CGSize, rhs: CGFloat) -> CGSize {
        CGSize(width: lhs.width * rhs, height: lhs.height * rhs)
    }
}
