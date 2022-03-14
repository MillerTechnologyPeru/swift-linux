//
//  Toolchain.swift
//  
//
//  Created by Alsey Coleman Miller on 3/13/22.
//

import Foundation

public extension Configuration.ID {
    
    static var kernelHeaders4_9: Configuration.ID       { "BR2_KERNEL_HEADERS_4_9" }
    
    static var toolchainGlibc: Configuration.ID         { "BR2_TOOLCHAIN_BUILDROOT_GLIBC" }
    
    static var toolchainCxx: Configuration.ID           { "BR2_TOOLCHAIN_BUILDROOT_CXX" }
    
    static var toolchainVendor: Configuration.ID        { "BR2_TOOLCHAIN_BUILDROOT_VENDOR" }
    
    static var genericHostname: Configuration.ID        { "BR2_TARGET_GENERIC_HOSTNAME" }
    
    static var genericIssue: Configuration.ID           { "BR2_TARGET_GENERIC_ISSUE" }
}
