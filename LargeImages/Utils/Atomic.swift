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
            lock.readLock()

            return value
        }
        set {
            defer { lock.unlock() }
            lock.writeLock()

            value = newValue
        }
    }

    func mutate(_ mutation: (inout Value) -> Void) {
        defer { lock.unlock() }
        lock.writeLock()

        mutation(&value)
    }

    private let lock = ReadWriteLock()
    private var value: Value
}

protocol Lockable: AnyObject {
    func lock()
    func unlock()
}

private final class SpinLock: Lockable {
    @inlinable
    func lock() {
        os_unfair_lock_lock(&unfairLock)
    }

    @inlinable
    func unlock() {
        os_unfair_lock_unlock(&unfairLock)
    }

    private var unfairLock = os_unfair_lock_s()
}

private final class MutexLock: Lockable {
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
