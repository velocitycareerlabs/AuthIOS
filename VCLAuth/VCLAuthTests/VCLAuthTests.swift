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
