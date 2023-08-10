//
//  VCLAuth.swift
//  VCLAuth
//
//  Created by Michael Avoyan on 22/05/2022.
//
//  Copyright 2022 Velocity Career Labs inc.
//  SPDX-License-Identifier: Apache-2.0

import UIKit
import LocalAuthentication

public protocol VCLAuth {
    ///Checks if authentication is available on the device
    func isAuthenticationAvailable(
        successHandler: @escaping (Bool) -> Void,
        errorHandler: @escaping (VCLError) -> Void
    )
    
    ///Displays a authentication identification dialog with provided configurations
    func authenticate(
        authConfig: VCLAuthConfig,
        successHandler: @escaping (Bool) -> Void,
        errorHandler: @escaping (VCLError) -> Void
    )

    /// Navigates to device's security settings screen for authentication setup
    func openSecuritySettings(
        successHandler: @escaping (Bool) -> Void,
        errorHandler: @escaping (VCLError) -> Void
    )
}
