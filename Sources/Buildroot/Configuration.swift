//
//  Configuration.swift
//
//
//  Created by Alsey Coleman Miller on 3/8/22.
//

/// Buildroot Configuration file
public struct Configuration: Equatable, Hashable {

    internal private(set) var elements: [Configuration.Element]
    
    private init(elements: [Configuration.Element]) {
        self.elements = elements
    }
    
    public init() {
        self.init(elements: [])
    }
    
    public init<S>(_ sequence: S) where S:Sequence, S.Element == Self.Element {
        self.elements = [Element](sequence)
    }
    
    public var count: Int {
        elements.count
    }
    
    public subscript(key: Configuration.ID) -> Configuration.Value? {
        get { elements.first(where: { $0.id == key })?.value }
        set {
            if let newValue = newValue {
                if let index = elements.firstIndex(where: { $0.id == key }) {
                    // modify existing entry
                    elements[index].value = newValue
                } else {
                    // append new entry
                    elements.append(.init(id: key, value: newValue))
                }
            } else if let index = elements.firstIndex(where: { $0.id == key }) {
                // remove existing entry
                elements.remove(at: index)
            }
        }
    }
}

// MARK: - ExpressibleByArrayLiteral

extension Configuration: ExpressibleByArrayLiteral {
    
    public init(arrayLiteral elements: Configuration.Element...) {
        self.init(elements: elements)
    }
}

// MARK: - ExpressibleByDictionaryLiteral

extension Configuration: ExpressibleByDictionaryLiteral {
    
    public init(dictionaryLiteral elements: (Configuration.ID, Configuration.Value)...) {
        self.init(elements: elements.map { Configuration.Element.init(id: $0, value: $1) })
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
/*
// MARK: - Sequence

extension Configuration: Sequence {
    
    func makeIterator() -> IndexingIterator<Self> {
        IndexingIterator<Self>(_elements: self.elements)
    }
}

// MARK: - RandomAccessCollection

extension Configuration: RandomAccessCollection {
    
    public subscript(position: Int) -> Element {
        self.elements[position]
    }
}
*/
// MARK: - Operators

public extension Configuration {
    
    static func + (lhs: Configuration, rhs: Configuration) -> Configuration {
        Configuration(elements: lhs.elements + rhs.elements)
    }
    
    static func += (lhs: inout Configuration, rhs: Configuration) {
        lhs.elements.append(contentsOf: rhs.elements)
    }
}
