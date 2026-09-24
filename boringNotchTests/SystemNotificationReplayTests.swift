//
//  SystemNotificationReplayTests.swift
//  boringNotchTests
//
//  Created by Lucas Walker on 2026-09-22.
//
//  SPDX-License-Identifier: GPL-3.0-only
//

import XCTest
@testable import boringNotch

@MainActor
final class SystemNotificationReplayTests: XCTestCase {

    private static let allAppsKey = "notificationsFromAllApps"
    private var savedAllApps: Any?

    override func setUp() async throws {
        try await super.setUp()
        savedAllApps = UserDefaults.standard.object(forKey: Self.allAppsKey)
        UserDefaults.standard.set(true, forKey: Self.allAppsKey)
        SystemNotificationManager.shared.dismissActive()
    }

    override func tearDown() async throws {
        SystemNotificationManager.shared.dismissActive()
        if let savedAllApps {
            UserDefaults.standard.set(savedAllApps, forKey: Self.allAppsKey)
        } else {
            UserDefaults.standard.removeObject(forKey: Self.allAppsKey)
        }
        try await super.tearDown()
    }

    func testRepeatedTokenIsMirroredOnlyOnce() async throws {
        let token = UUID().uuidString
        post(token: token, title: "First")
        let first = try await waitForActiveNotification()
        XCTAssertEqual(first.id, token)
        XCTAssertEqual(first.title, "First")

        post(token: token, title: "Replay")
        try await settle()

        let active = SystemNotificationManager.shared.activeNotification
        XCTAssertEqual(active?.id, token)
        XCTAssertEqual(active?.title, "First", "a replay must not replace the original")
        XCTAssertEqual(
            active?.receivedAt, first.receivedAt,
            "a replay must not restart the dismiss timer"
        )
        XCTAssertTrue(SystemNotificationManager.shared.queuedNotifications.isEmpty)
    }

    func testRepeatedTokenIsSuppressedAfterTheOriginalIsDismissed() async throws {
        let token = UUID().uuidString
        post(token: token, title: "First")
        _ = try await waitForActiveNotification()

        SystemNotificationManager.shared.dismissActive()
        try await settle()
        XCTAssertNil(SystemNotificationManager.shared.activeNotification)

        post(token: token, title: "First")
        try await settle()
        XCTAssertNil(
            SystemNotificationManager.shared.activeNotification,
            "reopening Notification Center must not resurrect a shown notification"
        )
    }

    func testDistinctTokenStillMirrors() async throws {
        post(token: UUID().uuidString, title: "First")
        _ = try await waitForActiveNotification()
        SystemNotificationManager.shared.dismissActive()
        try await settle()

        let second = UUID().uuidString
        post(token: second, title: "Second")
        let active = try await waitForActiveNotification()
        XCTAssertEqual(active.id, second)
        XCTAssertEqual(active.title, "Second")
    }

    // MARK: - Helpers

    private struct TimedOut: Error {}

    private func post(token: String, title: String) {
        NotificationCenter.default.post(
            name: .systemNotificationDidAppear,
            object: nil,
            userInfo: [
                "token": token,
                "appName": "Music",
                "bundleID": "com.apple.Music",
                "title": title,
                "subtitle": "",
                "body": "body"
            ]
        )
    }

    private func settle() async throws {
        for _ in 0..<10 {
            await Task.yield()
        }
        try await Task.sleep(for: .milliseconds(50))
    }

    private func waitForActiveNotification(
        timeout: TimeInterval = 2
    ) async throws -> SystemNotification {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if let active = SystemNotificationManager.shared.activeNotification {
                return active
            }
            try await Task.sleep(for: .milliseconds(10))
        }
        XCTFail("no notification was mirrored within \(timeout)s")
        throw TimedOut()
    }
}
