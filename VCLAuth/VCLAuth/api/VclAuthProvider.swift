//
//  VclAuthProvider.swift
//  VCLAuth
//
//  Created by Michael Avoyan on 22/05/2022.
//

import Foundation
import LocalAuthentication

public class VclAuthProvider {
    public static func instance() -> VCLAuth {
        return VCLAuthImpl(localAuthenticationContext: LAContext(), executor: ExecutorImpl())
    }
}
