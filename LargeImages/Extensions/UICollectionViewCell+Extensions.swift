//
//  UICollectionViewCell+Extensions.swift
//  LargeImages
//
//  Created by Anton Pomozov on 16.04.2020.
//  Copyright © 2020 Akademon. All rights reserved.
//

import UIKit

extension UICollectionViewCell {
    static var reuseIdentifier: String {
        String(describing: type(of: Self.self))
    }
}
