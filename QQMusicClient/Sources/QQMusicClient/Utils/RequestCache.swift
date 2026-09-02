import Foundation

actor RequestCache<Key: Hashable, Value> {
    private var storage: [Key: CacheEntry<Value>] = [:]
    private let expiration: TimeInterval

    init(expiration: TimeInterval = 300) {
        self.expiration = expiration
    }

    func value(for key: Key) -> Value? {
        guard let entry = storage[key], entry.isValid(expiration: expiration) else {
            storage.removeValue(forKey: key)
            return nil
        }
        return entry.value
    }

    func setValue(_ value: Value, for key: Key) {
        storage[key] = CacheEntry(value: value, timestamp: Date())
    }

    func clear() {
        storage.removeAll()
    }

    private struct CacheEntry<Value> {
        let value: Value
        let timestamp: Date

        func isValid(expiration: TimeInterval) -> Bool {
            Date().timeIntervalSince(timestamp) < expiration
        }
    }
}
