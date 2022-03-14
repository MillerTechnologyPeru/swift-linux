//
//  ConfigurationProfile.swift
//  
//
//  Created by Alsey Coleman Miller on 3/13/22.
//

import Foundation
import Buildroot
import AppRuntime
import ArgumentParser

/// Buildroot Configuration Profile.
///
/// Can be further customized by arch, UI frontend, etc.
public enum ConfigurationProfile: String {
    
    // Runtime
    case sdk
    
    // Complete images
    case uefi
    
    // Raspberry Pi
    case raspberryPi3
    case raspberryPi4
    
    // Orange Pi
    case orangePiPC
    case orangePiOne
    case orangePiZero
    case orangePiZero2
    
    // Chromebooks
    case chromebookVeyron
    case chromebookGru
    case chromebookKukui
    case chromebookTrogdor
}
