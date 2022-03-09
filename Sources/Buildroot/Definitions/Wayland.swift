//
//  Wayland.swift
//  
//
//  Created by Alsey Coleman Miller on 3/8/22.
//

// Wayland packages
public extension Configuration.ID {
    
    static var wayland: Configuration.ID            { "BR2_PACKAGE_WAYLAND" }
    
    static var waylandProtocols: Configuration.ID   { "BR2_PACKAGE_WAYLAND_PROTOCOLS" }
    
    static var wlroots: Configuration.ID            { "BR2_PACKAGE_WLROOTS" }
}
