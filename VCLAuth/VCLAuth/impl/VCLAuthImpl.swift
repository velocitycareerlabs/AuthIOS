//
//  VCLAuthImpl.swift
//  VCLAuth
//
//  Created by Michael Avoyan on 22/05/2022.
//

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
            do {
                var error: NSError?
                try successHandler(self?.localAuthenticationContext.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) == true)
            } catch let error {
                errorHandler(VCLError(error: error))
            }
        }
    }
    
    func authenticate(
        authConfig: VCLAuthConfig,
        successHandler: @escaping (Bool) -> Void,
        errorHandler: @escaping (VCLError) -> Void) {
            
            self.executor.runOnMainThread { [weak self] in
                do {
                    try self?.localAuthenticationContext.evaluatePolicy(
                        .deviceOwnerAuthentication,
    //                    .deviceOwnerAuthenticationWithBiometrics,
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
