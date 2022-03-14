import Foundation
import ArgumentParser
import AppRuntime
import Buildroot

/// `swift-linux` command line tool
@main
struct SwiftLinuxTool: ParsableCommand {
    
    static let configuration = CommandConfiguration(
        commandName: "swift-linux",
        abstract: "Command line tool for generating Swift Linux SDKs and OS images.",
        version: "1.0.0",
        subcommands: [
            GenerateConfiguration.self
        ]
    )
}
