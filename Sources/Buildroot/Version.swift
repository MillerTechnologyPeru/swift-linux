//
//  Version.swift
//  
//
//  Created by Alsey Coleman Miller on 3/8/22.
//

/// Buildroot version or release
public struct Version: RawRepresentable, Equatable, Hashable, Codable {

    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

// MARK: - ExpressibleByStringLiteral

extension Version: ExpressibleByStringLiteral {
    
    public init(stringLiteral value: String) {
        self.init(rawValue: value)
    }
}

// MARK: - CustomStringConvertible

extension Version: CustomStringConvertible, CustomDebugStringConvertible {
    
    public var description: String {
        rawValue
    }
    
    public var debugDescription: String {
        rawValue
    }
}

// MARK: - Definitions

public extension Version {
    
    static var v2021_11: Version { "2021.11" }
    
    static var v2021_11_1: Version { "2021.11.1" }
    
    static var v2021_11_2: Version { "2021.11.2" }
    
    static var v2022_02: Version { "2022.02" }
}
