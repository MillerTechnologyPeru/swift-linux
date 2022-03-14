//
//  SwiftConfiguration.swift
//  
//
//  Created by Alsey Coleman Miller on 3/13/22.
//

import Foundation
import Buildroot

public extension Configuration {
    
    static var swift: Configuration {
        [
            // Swift Runtime Libraries
            .swift: true,
            .libdispatch: true,
            .libswiftdispatch: true,
            .foundation: true,
            // Dependencies
            .icu: true,
            .libbsd: true,
            .libxml2: true,
            .libcurl: true,
            .openssl: true
            // Swift Packages
        ]
    }
}
