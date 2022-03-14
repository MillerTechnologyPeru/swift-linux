//
//  ArchConfiguration.swift
//  
//
//  Created by Alsey Coleman Miller on 3/13/22.
//

import Foundation
import Buildroot
import AppRuntime

public extension Configuration {
    
    static var armv7: Configuration {
        [
            .arm: true,
            "BR2_cortex_a8": true,
            "BR2_ARM_FPU_VFPV3": true,
        ]
    }
    
    static var arm64: Configuration {
        [
            .arm64: true
        ]
    }
    
    static var x86_64: Configuration {
        [
            .x86_64: true
        ]
    }
}

public extension Configuration {
    
    init?(arch: Arch) {
        switch arch {
        case .armv7:
            self = .armv7
        case .arm64:
            self = .arm64
        case .x86_64:
            self = .x86_64
        default:
            return nil
        }
    }
}
