//
//  ImageCellViewModel.swift
//  LargeImages
//
//  Created by Anton Pomozov on 16.04.2020.
//  Copyright © 2020 Akademon. All rights reserved.
//

import UIKit

struct ImageCellViewModel {
    let state: FetchingState
    let url: URL
    let size: CGSize
    var image: UIImage?
}

extension ImageCellViewModel: ViewModel {}
