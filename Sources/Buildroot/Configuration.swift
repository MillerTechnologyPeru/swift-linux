//
//  Configuration.swift
//
//
//  Created by Alsey Coleman Miller on 3/8/22.
//

/// Buildroot Configuration file
public struct Configuration: Equatable, Hashable {

    internal private(set) var elements: [Configuration.Element]
    
    public init() {
        self.elements = []
    }
    
    public init<S>(_ sequence: S) where S:Sequence, S.Element == Self.Element {
        self.elements = [Element](sequence)
    }
    
    public var count: Int {
        elements.count
    }
}

// MARK: - RawRepresentable

extension Configuration: ExpressibleByArrayLiteral {
    
    public init(arrayLiteral elements: Configuration.Element...) {
        self.elements = elements
    }
}

// MARK: - RawRepresentable

extension Configuration: RawRepresentable {
    
    public init?(rawValue: String) {
        guard rawValue.isEmpty == false else {
            self = .init()
            return
        }
        let lines = rawValue.split(separator: .newline, maxSplits: .max, omittingEmptySubsequences: true)
        self.elements = [Element]()
        self.elements.reserveCapacity(lines.count)
        for line in lines {
            // ignore comments
            guard line.first != .pound else {
                continue
            }
            // parse entry
            guard let element = Element.parse(line) else {
                return nil
            }
            self.elements.append(element)
        }
    }
    
    public var rawValue: String {
        elements.reduce(into: "", { $0 += ($0.isEmpty ? "" : String(.newline)) + $1.rawValue})
    }
}

// MARK: - CustomStringConvertible

extension Configuration: CustomStringConvertible, CustomDebugStringConvertible {
    
    public var description: String {
        rawValue
    }
    
    public var debugDescription: String {
        rawValue
    }
}
