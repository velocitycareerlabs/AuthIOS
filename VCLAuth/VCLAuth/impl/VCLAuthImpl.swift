//
//  VCLAuthImpl.swift
//  VCLAuth
//
//  Created by Michael Avoyan on 22/05/2022.
//
//  Copyright 2022 Velocity Career Labs inc.
//  SPDX-License-Identifier: Apache-2.0

import UIKit
import LocalAuthentication

class VCLAuthImpl: VCLAuth {
    
    // Every call gets a new context. A context that has already passed can
    // pass again without showing the prompt, so a shared one would let every
    // authentication after the first succeed silently.
    let makeLocalAuthenticationContext: () -> LAContext
    let executor: Executor
    
    init(makeLocalAuthenticationContext: @escaping () -> LAContext, executor: Executor) {
        self.makeLocalAuthenticationContext = makeLocalAuthenticationContext
        self.executor = executor
    }
    
    func isAuthenticationAvailable(
        successHandler: @escaping (Bool) -> Void,
        errorHandler: @escaping (VCLError) -> Void
    ) {
        let localAuthenticationContext = makeLocalAuthenticationContext()
        self.executor.runOnMainThread {
            do {
                var error: NSError?
                try successHandler(localAuthenticationContext.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error))
            } catch let error {
                errorHandler(VCLError(error: error))
            }
        }
    }
    
    func authenticate(
        authConfig: VCLAuthConfig,
        successHandler: @escaping (Bool) -> Void,
        errorHandler: @escaping (VCLError) -> Void) {
            
            let localAuthenticationContext = makeLocalAuthenticationContext()
            self.executor.runOnMainThread {
                do {
                    try localAuthenticationContext.evaluatePolicy(
                        .deviceOwnerAuthentication,
    //                    .deviceOwnerAuthenticationWithBiometrics,
                        localizedReason: authConfig.title
                    ) { success, error in
                        // Releasing a context cancels its evaluation, so the
                        // reply holds the context until the evaluation ends.
                        withExtendedLifetime(localAuthenticationContext) {
                            if success {
                                successHandler(true)
                            } else {
                                if let error = error {
                                    errorHandler(VCLError(error: error))
                                } else {
                                    successHandler(false)
                                }
                            }
                        }
                    }
                } catch let error {
                    errorHandler(VCLError(error: error))
                }
            }
        }
    
    func openSecuritySettings(
        successHandler: @escaping (Bool) -> Void,
        errorHandler: @escaping (VCLError) -> Void) {
            
            self.executor.runOnMainThread {
                if let url = URL.init(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    successHandler(true)
                }
                else {
                    errorHandler(VCLError(description: "Failed to oppen settings"))
                }
            }
        }
}
