//
//  Character.swift
//  
//
//  Created by Alsey Coleman Miller on 3/8/22.
//

internal extension Character {
    
    static var quotes: Character { #"""# }
    
    static var pound: Character { #"#"# }
    
    static var newline: Character { "\n" }
    
    static var equal: Character { "=" }
}

internal extension String {
    
    static var quotes: String { String(.quotes) }
    
    static var equal: String { String(.equal) }
}
