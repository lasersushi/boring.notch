//
//  NotificationTokenLedger.swift
//  boringNotch
//
//  Created by Lucas Walker on 2026-09-22.
//
//  SPDX-License-Identifier: GPL-3.0-only
//
//  Shared source compiled into BOTH targets (via the Shared synchronized
//  group). There is intentionally one copy — edit once, both sides build it.
//

import Foundation

struct NotificationTokenLedger {
    private var order: [String] = []
    private var members: Set<String> = []
    private let capacity: Int

    init(capacity: Int = 512) {
        self.capacity = max(1, capacity)
    }

    func contains(_ token: String) -> Bool {
        members.contains(token)
    }

    @discardableResult
    mutating func record(_ token: String) -> Bool {
        guard members.insert(token).inserted else { return false }
        order.append(token)
        if order.count > capacity {
            members.remove(order.removeFirst())
        }
        return true
    }

    mutating func removeAll() {
        order.removeAll()
        members.removeAll()
    }
}
