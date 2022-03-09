//
//  ConfigurationValue.swift
//  
//
//  Created by Alsey Coleman Miller on 3/8/22.
//

/// Buildroot Configuration Value
///
/// e.g. `y`, `"/usr/bin"`, `"buildroot"`
public extension Configuration {

    enum Value: Equatable, Hashable, Codable {

        case bool(Bool)
        case string(String)
    }
}

// MARK: - RawRepresentable

extension Configuration.Value: RawRepresentable {
    
    public init?(rawValue: String) {
        guard let value = Self.parse(rawValue) else {
            return nil
        }
        self = value
    }
    
    internal static func parse<S: StringProtocol>(_ string: S) -> Configuration.Value? {
        switch string {
        case "y":
            return .bool(true)
        case "n":
            return .bool(false)
        default:
            guard string.count >= 2,
                  string.first == .quotes,
                  string.last == .quotes else {
                return nil
            }
            var stringValue = String(string)
            stringValue.removeFirst()
            stringValue.removeLast()
            return .string(stringValue)
        }
    }
    
    public var rawValue: String {
        switch self {
        case let .bool(value):
            return value ? "y" : "n"
        case let .string(value):
            return .quotes + value + .quotes
        }
    }
}

// MARK: - CustomStringConvertible

extension Configuration.Value: CustomStringConvertible, CustomDebugStringConvertible {
    
    public var description: String {
        rawValue
    }
    
    public var debugDescription: String {
        rawValue
    }
}
