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
    
    let localAuthenticationContext: LAContext
    let executor: Executor
    
    init(localAuthenticationContext: LAContext, executor: Executor) {
        self.localAuthenticationContext = localAuthenticationContext
        self.executor = executor
    }
    
    func isAuthenticationAvailable(
        successHandler: @escaping (Bool) -> Void,
        errorHandler: @escaping (VCLError) -> Void
    ) {
        self.executor.runOnMainThread { [weak self] in
            var error: NSError?
            let isAvailable = self?.localAuthenticationContext.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
            if let err = error {
                errorHandler(VCLError(error: err))
            } else {
                successHandler(isAvailable == true)
            }
        }
    }
    
    func authenticate(
        authConfig: VCLAuthConfig,
        successHandler: @escaping (Bool) -> Void,
        errorHandler: @escaping (VCLError) -> Void
    ) {
        self.executor.runOnMainThread { [weak self] in
            self?.localAuthenticationContext.evaluatePolicy(
                .deviceOwnerAuthentication,
                // .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: authConfig.title
            ) { success, error in
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
    }
    
    func cancelAuthentication(
        successHandler: @escaping () -> Void,
        errorHandler: @escaping (VCLError) -> Void
    ) {
        self.executor.runOnMainThread { [weak self] in
            do {
                try self?.localAuthenticationContext.invalidate()
                successHandler()
            } catch {
                errorHandler(VCLError(error: error))
            }
        }
    }
    
    func openSecuritySettings(
        successHandler: @escaping () -> Void,
        errorHandler: @escaping (VCLError) -> Void
    ) {
        self.executor.runOnMainThread {
            if let url = URL.init(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
                successHandler()
            }
            else {
                errorHandler(VCLError(description: "Failed to oppen settings"))
            }
        }
    }
}
