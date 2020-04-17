//
//  ViewModel.swift
//  LargeImages
//
//  Created by Anton Pomozov on 16.04.2020.
//  Copyright © 2020 Akademon. All rights reserved.
//

import Foundation

protocol ViewModel {}

protocol ViewModelConfigurable: AnyObject {
    associatedtype ViewModelObject: ViewModel

    var viewModel: ViewModelObject? { get }

    func configure(with viewModel: ViewModelObject)
}

protocol ViewModelOwning: ViewModelConfigurable {
    var currentViewModel: ViewModelObject { get }
}

extension ViewModelOwning {
    var currentViewModel: ViewModelObject { viewModel! }
}
