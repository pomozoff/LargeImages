//
//  UnsafeBag.swift
//  LargeImages
//
//  Created by Anton Pomozov on 17.04.2020.
//  Copyright © 2020 Akademon. All rights reserved.
//

import Foundation

class UnsafeBag<Item> {
    func insert(_ item: Item) -> Disposable {
        let disposable = UnsafeDisposable(item: item)

        $items.mutate {
            $0.append(disposable)
        }

        return disposable
    }

    func forEach(_ action: (Item) -> Void) {
        $items.mutate {
            $0
                .filter { !$0.isDisposed }
                .map(\.item)
                .forEach(action)
        }
    }

    deinit {
        $items.mutate { $0.removeAll() }
    }

    @Atomic
    private var items: [UnsafeDisposable] = []
}

private extension UnsafeBag {
    class UnsafeDisposable: DisposableObject {
        let item: Item

        init(item: Item) {
            self.item = item
            super.init()
        }
    }
}
