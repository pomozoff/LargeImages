//
//  DisposeBag.swift
//  LargeImages
//
//  Created by Anton Pomozov on 16.04.2020.
//  Copyright © 2020 Akademon. All rights reserved.
//

import Foundation

class DisposeBag {
    func insert(_ disposable: Disposable) {
        $disposables.mutate { $0.append(disposable) }
    }

    deinit {
        $disposables.mutate { $0.removeAll() }
    }

    @Atomic
    private var disposables: [Disposable] = []
}
