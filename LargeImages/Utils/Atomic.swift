//
//  Atomic.swift
//  LargeImages
//
//  Created by Anton Pomozov on 16.04.2020.
//  Copyright © 2020 Akademon. All rights reserved.
//

import Foundation

@propertyWrapper
class Atomic<Value> {
    var projectedValue: Atomic<Value> {
        return self
    }

    init(wrappedValue: Value) {
        self.value = wrappedValue
    }

    var wrappedValue: Value {
        get {
            defer { lock.unlock() }
            lock.lock()

            return value
        }
        set {
            defer { lock.unlock() }
            lock.lock()

            value = newValue
        }
    }

    func mutate(_ mutation: (inout Value) -> Void) {
        defer { lock.unlock() }
        lock.lock()

        mutation(&value)
    }

    private let lock = MutexLock()
    private var value: Value
}

private final class MutexLock {
    @inlinable
    func lock() {
        pthread_mutex_lock(&mutex)
    }

    @inlinable
    func unlock() {
        pthread_mutex_unlock(&mutex)
    }

    private var mutex: pthread_mutex_t = {
        var mutex = pthread_mutex_t()
        pthread_mutex_init(&mutex, nil)
        return mutex
    }()
}

private final class ReadWriteLock {
    @inlinable
    func writeLock() {
        pthread_rwlock_wrlock(&rwlock)
    }

    @inlinable
    func readLock() {
        pthread_rwlock_rdlock(&rwlock)
    }

    @inlinable
    func unlock() {
        pthread_rwlock_unlock(&rwlock)
    }

    private var rwlock: pthread_rwlock_t = {
        var rwlock = pthread_rwlock_t()
        pthread_rwlock_init(&rwlock, nil)
        return rwlock
    }()
}
