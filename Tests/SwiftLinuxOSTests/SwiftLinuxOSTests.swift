import XCTest
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
            .libdispatch: true,
            .swift: true,
            .libswiftdispatch: true,
            .foundation: true,
            .icu: true,
            .libbsd: true,
            .libxml2: true,
            .libcurl: true,
            .openssl: true,
        ]
        
        XCTAssertEqual(parsedConfiguration, configuration)
        XCTAssertEqual(configuration.rawValue, configurationSanitizedFile)
    }
}
