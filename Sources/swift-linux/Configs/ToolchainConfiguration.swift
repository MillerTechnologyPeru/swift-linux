//
//  Toolchain.swift
//  
//
//  Created by Alsey Coleman Miller on 3/13/22.
//

import Foundation
import Buildroot

public extension Configuration {
    
    static var toolchain: Configuration {
        [
            // GNU C Toolchain
            .kernelHeaders4_9: true,
            .toolchainGlibc: true,
            .toolchainCxx: true,
            
            // Device Management
            "BR2_ROOTFS_DEVICE_CREATION_DYNAMIC_EUDEV": true,
            
            // Vendor
            .toolchainVendor: "swift",
            .genericHostname: "swift-linux",
            .genericIssue: "Welcome to Swift Linux"
        ]
    }
}
