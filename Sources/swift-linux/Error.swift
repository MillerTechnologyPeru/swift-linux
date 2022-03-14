//
//  Error.swift
//  
//
//  Created by Alsey Coleman Miller on 3/13/22.
//

import Foundation

struct SwiftLinuxToolError: Error, LocalizedError {
    
    let errorDescription: String
    
    init(_ errorDescription: String) {
        self.errorDescription = errorDescription
    }
}
