//
//  VclAuthProvider.swift
//  VCLAuth
//
//  Created by Michael Avoyan on 22/05/2022.
//
// Copyright 2022 Velocity Career Labs inc.
// SPDX-License-Identifier: Apache-2.0

import Foundation
import LocalAuthentication

public class VclAuthProvider {
    public static func instance() -> VCLAuth {
        return VCLAuthImpl(localAuthenticationContext: LAContext(), executor: ExecutorImpl())
    }
}
