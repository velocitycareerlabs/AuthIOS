//
//  ExecutorImpl.swift
//  
//
//  Created by Michael Avoyan on 02/05/2021.
//
//  Copyright 2022 Velocity Career Labs inc.
//  SPDX-License-Identifier: Apache-2.0

import Foundation

class ExecutorImpl: Executor {
    private var mainThread: DispatchQueue
    
    init() {
        self.mainThread = DispatchQueue.main
    }
    
//    func runOn(_ callinghQueue: DispatchQueue, _ block: @escaping () -> Void) {
//        callinghQueue.async {
//            block()
//        }
//    }
    
    func runOnMainThread(_ block: @escaping () -> Void) {
        self.mainThread.async {
            block()
        }
    }
    
    func runOnBackgroundThread(_ block: @escaping () -> Void) {
        DispatchQueue.global(qos: .default).async {
            block()
        }
    }
}
