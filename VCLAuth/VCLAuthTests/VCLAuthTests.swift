//
//  VCLAuthTests.swift
//  VCLAuthTests
//
//  Created by Michael Avoyan on 12/06/2022.
//
//  Copyright 2022 Velocity Career Labs inc.
//  SPDX-License-Identifier: Apache-2.0

import XCTest
import LocalAuthentication
@testable import VCLAuth

class VCLAuthTests: XCTestCase {

    private let authConfig = VCLAuthConfig(title: "Unlock")

    func testEachAuthenticationEvaluatesANewContext() {
        var contexts: [FakeLAContext] = []
        let auth = VCLAuthImpl(
            makeLocalAuthenticationContext: {
                let context = FakeLAContext()
                contexts.append(context)
                return context
            },
            executor: ImmediateExecutor()
        )
        var results: [Bool] = []

        auth.authenticate(authConfig: authConfig, successHandler: { results.append($0) }, errorHandler: { _ in })
        auth.authenticate(authConfig: authConfig, successHandler: { results.append($0) }, errorHandler: { _ in })

        XCTAssertEqual(results, [true, true])
        XCTAssertEqual(contexts.count, 2)
        XCTAssertEqual(contexts.map(\.evaluationCount), [1, 1])
    }

    func testAuthenticationKeepsTheContextUntilTheReply() {
        let pendingReply = PendingReply()
        weak var weakContext: LAContext?
        let auth = VCLAuthImpl(
            makeLocalAuthenticationContext: {
                let context = DeferredReplyLAContext(pendingReply: pendingReply)
                weakContext = context
                return context
            },
            executor: ExecutorImpl()
        )
        let replied = expectation(description: "reply")
        var results: [Bool] = []
        var errors: [VCLError] = []

        auth.authenticate(
            authConfig: authConfig,
            successHandler: { results.append($0); replied.fulfill() },
            errorHandler: { errors.append($0); replied.fulfill() }
        )
        // Let the main-thread block run and return, as the OS prompt would.
        RunLoop.main.run(until: Date().addingTimeInterval(0.1))

        XCTAssertNotNil(weakContext)
        XCTAssertTrue(errors.isEmpty)

        pendingReply.complete(success: true)
        wait(for: [replied], timeout: 1)

        XCTAssertEqual(results, [true])
        XCTAssertTrue(errors.isEmpty)
        XCTAssertNil(weakContext)
    }

    func testAuthenticationCompletesAfterTheAuthIsReleased() {
        let executor = DeferredExecutor()
        var auth: VCLAuth? = VCLAuthImpl(
            makeLocalAuthenticationContext: { FakeLAContext() },
            executor: executor
        )
        var result: Bool?

        auth?.authenticate(authConfig: authConfig, successHandler: { result = $0 }, errorHandler: { _ in })
        auth = nil
        executor.runPending()

        XCTAssertEqual(result, true)
    }

    func testFailedAuthenticationReportsTheError() {
        let auth = VCLAuthImpl(
            makeLocalAuthenticationContext: {
                FakeLAContext(error: LAError(.userCancel))
            },
            executor: ImmediateExecutor()
        )
        var reportedError: VCLError?

        auth.authenticate(authConfig: authConfig, successHandler: { _ in }, errorHandler: { reportedError = $0 })

        XCTAssertNotNil(reportedError)
    }
}

private class FakeLAContext: LAContext {
    private let error: Error?
    private(set) var evaluationCount = 0

    init(error: Error? = nil) {
        self.error = error
        super.init()
    }

    override func canEvaluatePolicy(_ policy: LAPolicy, error: NSErrorPointer) -> Bool {
        true
    }

    override func evaluatePolicy(
        _ policy: LAPolicy,
        localizedReason: String,
        reply: @escaping (Bool, Error?) -> Void
    ) {
        evaluationCount += 1
        reply(error == nil, error)
    }
}

// Replies only when the test completes the evaluation. Like LocalAuthentication,
// it cancels a pending evaluation when the context is deallocated.
private class DeferredReplyLAContext: LAContext {
    private let pendingReply: PendingReply

    init(pendingReply: PendingReply) {
        self.pendingReply = pendingReply
        super.init()
    }

    deinit {
        pendingReply.cancel()
    }

    override func evaluatePolicy(
        _ policy: LAPolicy,
        localizedReason: String,
        reply: @escaping (Bool, Error?) -> Void
    ) {
        pendingReply.reply = reply
    }
}

private class PendingReply {
    var reply: ((Bool, Error?) -> Void)?

    func cancel() {
        finish(success: false, error: LAError(.appCancel))
    }

    func complete(success: Bool) {
        finish(success: success, error: nil)
    }

    private func finish(success: Bool, error: Error?) {
        let reply = self.reply
        self.reply = nil
        reply?(success, error)
    }
}

private class ImmediateExecutor: Executor {
    func runOnMainThread(_ block: @escaping () -> Void) {
        block()
    }

    func runOnBackgroundThread(_ block: @escaping () -> Void) {
        block()
    }
}

private class DeferredExecutor: Executor {
    private var pending: [() -> Void] = []

    func runOnMainThread(_ block: @escaping () -> Void) {
        pending.append(block)
    }

    func runOnBackgroundThread(_ block: @escaping () -> Void) {
        pending.append(block)
    }

    func runPending() {
        let blocks = pending
        pending = []
        blocks.forEach { $0() }
    }
}
