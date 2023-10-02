//
//  GenerateConfiguration.swift
//  
//
//  Created by Alsey Coleman Miller on 3/13/22.
//

import Foundation
import ArgumentParser
import Buildroot
import AppRuntime

struct GenerateConfiguration: ParsableCommand {
    
    static let configuration = CommandConfiguration(
        abstract: "Generate Buildroot configuration."
    )
    
    @Option(help: "Path to output file.")
    var path: String?
    
    @Option(help: "Configuration profile to generate.")
    var configuration: ConfigurationProfile = .sdk
    
    @Option(help: "Architecture to generate.")
    var arch: Arch?
    
    @Option(help: "Desktop environment to build.")
    var desktopEnvironment: DesktopEnvironment = .weston
    
    func run() throws {
        let configuration = try generate()
        let url = try fileURL()
        let data = Data(configuration.rawValue.utf8)
        try data.write(to: url, options: [.atomic])
        print("Generated \(self.configuration) configuration at \(url.path)")
    }
    
    func fileURL() throws -> URL {
        if let path = path {
            return URL(fileURLWithPath: path)
        } else {
            let fileManger = FileManager()
            return URL(fileURLWithPath: fileManger.currentDirectoryPath)
                .appendingPathComponent("swift_linux_defconfig")
        }
    }
    
    func generate() throws -> Buildroot.Configuration {
        switch configuration {
        case .sdk:
            guard let arch = self.arch else {
                throw SwiftLinuxToolError("Must specify architecture")
            }
            guard let configuration = Configuration.generateSDK(for: arch) else {
                throw SwiftLinuxToolError("Invalid architecture \(arch)")
            }
            return configuration
        case .appSDK:
            guard let arch = self.arch else {
                throw SwiftLinuxToolError("Must specify architecture")
            }
            guard let configuration = Configuration.generateSDK(for: arch, isApp: true) else {
                throw SwiftLinuxToolError("Invalid architecture \(arch)")
            }
            return configuration
        default:
            throw SwiftLinuxToolError("Not implemented")
        }
    }
}

extension Buildroot.Configuration {
    
    static func generateSDK(for arch: Arch, isApp: Bool = false) -> Buildroot.Configuration? {
        guard var configuration = Configuration(arch: arch) else {
            return nil
        }
        configuration += .toolchain
        configuration += .swift
        if isApp {
            configuration += .appLibraries
        }
        return configuration
    }
}
