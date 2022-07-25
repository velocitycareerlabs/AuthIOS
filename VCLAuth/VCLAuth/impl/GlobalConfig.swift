//
//  GlobalConfig.swift
//  VCLAuth
//
//  Created by Michael Avoyan on 22/05/2022.
//

import UIKit

struct GlobalConfig {
    static let VclPackage = "io.velocitycareerlabs.vclauth"
        
    #if DEBUG
        static let IsDebug = true
    #else
        static let IsDebug = false
    #endif
    
    static let LogTagPrefix = "VCLAuth "

    static var IsLoggerOn: Bool { get { IsDebug } }
}
