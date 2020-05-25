//
//  ReadWrite.swift
//  LargeImages
//
//  Created by Anton Pomozov on 11.05.2020.
//  Copyright © 2020 Akademon. All rights reserved.
//

import Foundation

@propertyWrapper
class ReadWrite<Value> {
    var projectedValue: ReadWrite<Value> {
        return self
    }

    init(
        wrappedValue: Value,
        queue: DispatchQueue = DispatchQueue(
            label: "largeImages.ReadWriteQueue",
            qos: .background,
            attributes: .concurrent
        )
    ) {
        self.value = wrappedValue
        self.queue = queue
    }

    var wrappedValue: Value {
        get { queue.sync { value } }
        set { queue.async(flags: .barrier) { self.value = newValue }}
    }

    func mutate(_ mutation: (inout Value) -> Void) {
        queue.sync {
            mutation(&self.value)
        }
    }

    private var value: Value
    private let queue: DispatchQueue
}
