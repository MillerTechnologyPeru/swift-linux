//
//  ConfigurationID.swift
//  
//
//  Created by Alsey Coleman Miller on 3/8/22.
//

import Foundation

/// Buildroot Configuration ID
///
/// e.g. `BR2_PACKAGE_SWIFT`
public extension Configuration {

    struct ID: RawRepresentable, Equatable, Hashable, Codable {

        public let rawValue: String

        public init(rawValue: String) {
            self.rawValue = rawValue
        }
    }
}

public extension Configuration.ID {
    
    var isPackage: Bool {
        rawValue.contains("BR2_PACKAGE")
    }
}
