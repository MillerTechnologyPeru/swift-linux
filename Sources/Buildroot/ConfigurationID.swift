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

        public init?(rawValue: String) {
            guard rawValue.contains(.equal) == false else {
                return nil
            }
            self.rawValue = rawValue
        }
    }
}

public extension Configuration.ID {
    
    var isPackage: Bool {
        rawValue.contains("BR2_PACKAGE")
    }
}

// MARK: - ExpressibleByStringLiteral

extension Configuration.ID: ExpressibleByStringLiteral {
    
    public init(stringLiteral string: String) {
        guard let value = Self.init(rawValue: string) else {
            fatalError("Invalid string \(string)")
        }
        self = value
    }
}

// MARK: - CustomStringConvertible

extension Configuration.ID: CustomStringConvertible, CustomDebugStringConvertible {
    
    public var description: String {
        rawValue
    }
    
    public var debugDescription: String {
        rawValue
    }
}
