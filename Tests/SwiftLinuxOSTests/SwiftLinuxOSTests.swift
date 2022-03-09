import XCTest
@testable import SwiftLinuxOS
@testable import Buildroot

final class SwiftLinuxOSTests: XCTestCase {
    
    func testConfiguration() {
        
        let configurationFile = """
        # Swift Runtime Libraries
        BR2_PACKAGE_LIBDISPATCH=y
        BR2_PACKAGE_SWIFT=y
        BR2_PACKAGE_LIBSWIFTDISPATCH=y
        BR2_PACKAGE_FOUNDATION=y

        # Dependenecies
        BR2_PACKAGE_ICU=y
        BR2_PACKAGE_LIBBSD=y
        BR2_PACKAGE_LIBXML2=y
        BR2_PACKAGE_LIBCURL=y
        BR2_PACKAGE_OPENSSL=y
        """
        
        let configurationSanitizedFile = """
        BR2_PACKAGE_LIBDISPATCH=y
        BR2_PACKAGE_SWIFT=y
        BR2_PACKAGE_LIBSWIFTDISPATCH=y
        BR2_PACKAGE_FOUNDATION=y
        BR2_PACKAGE_ICU=y
        BR2_PACKAGE_LIBBSD=y
        BR2_PACKAGE_LIBXML2=y
        BR2_PACKAGE_LIBCURL=y
        BR2_PACKAGE_OPENSSL=y
        """
        
        guard let parsedConfiguration = Buildroot.Configuration(rawValue: configurationFile) else {
            XCTFail("Could not parse config")
            return
        }
        
        let configuration: Buildroot.Configuration = [
            .init(id: .libdispatch),
            .init(id: .swift),
            .init(id: .libswiftdispatch),
            .init(id: .foundation),
            
            .init(id: .icu),
            .init(id: .libbsd),
            .init(id: .libxml2),
            .init(id: .libcurl),
            .init(id: .openssl),
        ]
        
        XCTAssertEqual(parsedConfiguration, configuration)
        XCTAssertEqual(configuration.rawValue, configurationSanitizedFile)
    }
}
