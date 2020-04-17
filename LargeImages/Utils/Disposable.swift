//
//  Disposable.swift
//  LargeImages
//
//  Created by Anton Pomozov on 16.04.2020.
//  Copyright © 2020 Akademon. All rights reserved.
//

import Foundation

protocol Disposable: AnyObject {
    func dispose()
    func disposed(by bag: DisposeBag)
}

class DisposableObject {
    @Atomic
    private var disposed = false
}

extension DisposableObject: Disposable {
    static var new: Disposable { DisposableObject() }

    private(set) var isDisposed: Bool {
        get {
            disposed
        }
        set {
            disposed = newValue
        }
    }

    func dispose() {
        disposed = true
    }

    func disposed(by bag: DisposeBag) {
        bag.insert(self)
    }
}
