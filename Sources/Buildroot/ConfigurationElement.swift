//
//  ConfigurationElement.swift
//  
//
//  Created by Alsey Coleman Miller on 3/8/22.
//

public extension Configuration {
    
    /// Buildroot Configuration entry
    ///
    /// e.g. `BR2_PACKAGE_SWIFT=y`
    struct Element: Equatable, Hashable, Codable, Identifiable {

        public let id: Configuration.ID

        public let value: Configuration.Value
    }
}

// MARK: - RawRepresentable

extension Configuration.Element: RawRepresentable {
    
    public init?(rawValue: String) {
        guard let value = Self.parse(rawValue) else {
            return nil
        }
        self = value
    }
    
    internal static func parse<S: StringProtocol>(_ string: S) -> Configuration.Element? {
        let substrings = string.split(separator: .equal, maxSplits: 2, omittingEmptySubsequences: true)
        guard substrings.count == 2,
            let value = Configuration.Value.parse(substrings[1])
            else { return nil }
        return Configuration.Element(
            id: Configuration.ID(rawValue: String(substrings[0])),
            value: value
        )
    }
    
    public var rawValue: String {
        id.rawValue + .equal + value.rawValue
    }
}

// MARK: - CustomStringConvertible

extension Configuration.Element: CustomStringConvertible, CustomDebugStringConvertible {
    
    public var description: String {
        rawValue
    }
    
    public var debugDescription: String {
        rawValue
    }
}
