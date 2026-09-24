//
//  NotificationTokenLedgerTests.swift
//  boringNotchTests
//
//  Created by Lucas Walker on 2026-09-22.
//
//  SPDX-License-Identifier: GPL-3.0-only
//

import XCTest
@testable import boringNotch

final class NotificationTokenLedgerTests: XCTestCase {

    func testRecordReportsNoveltyOnlyOnce() {
        var ledger = NotificationTokenLedger()
        XCTAssertTrue(ledger.record("a"))
        XCTAssertFalse(ledger.record("a"))
        XCTAssertTrue(ledger.contains("a"))
    }

    func testContainsIsFalseForAnUnrecordedToken() {
        var ledger = NotificationTokenLedger()
        ledger.record("a")
        XCTAssertFalse(ledger.contains("b"))
    }

    func testEvictsOldestPastCapacity() {
        var ledger = NotificationTokenLedger(capacity: 3)
        for token in ["a", "b", "c"] {
            ledger.record(token)
        }
        XCTAssertTrue(ledger.record("d"))
        XCTAssertFalse(ledger.contains("a"), "the oldest token should have been evicted")
        for token in ["b", "c", "d"] {
            XCTAssertTrue(ledger.contains(token), token)
        }
        XCTAssertTrue(ledger.record("a"), "an evicted token reads as new again")
    }

    func testReRecordingDoesNotCorruptEvictionOrder() {
        var ledger = NotificationTokenLedger(capacity: 3)
        for token in ["a", "b", "c"] {
            ledger.record(token)
        }
        ledger.record("a")
        ledger.record("d")
        XCTAssertFalse(ledger.contains("a"), "\"a\" is the genuine oldest and should go")
        for token in ["b", "c", "d"] {
            XCTAssertTrue(ledger.contains(token), "\"\(token)\" was evicted by a duplicate entry")
        }
    }

    func testCapacityIsClampedToAtLeastOne() {
        var ledger = NotificationTokenLedger(capacity: 0)
        XCTAssertTrue(ledger.record("a"))
        XCTAssertTrue(ledger.contains("a"))
        ledger.record("b")
        XCTAssertFalse(ledger.contains("a"))
        XCTAssertTrue(ledger.contains("b"))
    }

    func testRemoveAllClearsBothMembershipAndOrder() {
        var ledger = NotificationTokenLedger(capacity: 3)
        for token in ["a", "b"] {
            ledger.record(token)
        }
        ledger.removeAll()
        XCTAssertFalse(ledger.contains("a"))
        XCTAssertTrue(ledger.record("a"))
    }
}
