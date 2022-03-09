//
//  Arch.swift
//  
//
//  Created by Alsey Coleman Miller on 3/8/22.
//

// Buildroot arch
public extension Configuration.ID {
    
    static var arm: Configuration.ID                { "BR2_arm" }
    
    static var arm64: Configuration.ID              { "BR2_aarch64" }
    
    static var x86_64: Configuration.ID             { "BR2_x86_64" }
}
