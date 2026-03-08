import XCTest
import DHCharList
@testable import DHCharListHost

final class DHCharListHostLaunchConfigurationTests: XCTestCase {
    func testDefaultsToJSONWithoutFlags() {
        let configuration = DHCharListHostLaunchConfiguration.from(arguments: ["DHCharListHost"])

        XCTAssertFalse(configuration.isUITesting)
        XCTAssertFalse(configuration.shouldResetData)
        XCTAssertFalse(configuration.shouldSeedSmokeData)
        XCTAssertEqual(configuration.persistence, .jsonFile)
    }

    func testEnablesUITestingHooksFromFlags() {
        let configuration = DHCharListHostLaunchConfiguration.from(arguments: [
            "DHCharListHost",
            DHCharListHostLaunchConfiguration.uiTestingArgument,
            DHCharListHostLaunchConfiguration.resetDataArgument,
            DHCharListHostLaunchConfiguration.seedSmokeDataArgument
        ])

        XCTAssertTrue(configuration.isUITesting)
        XCTAssertTrue(configuration.shouldResetData)
        XCTAssertTrue(configuration.shouldSeedSmokeData)
        XCTAssertEqual(configuration.persistence, .jsonFile)
    }

    func testSelectsSwiftDataWhenFlagPresent() {
        let configuration = DHCharListHostLaunchConfiguration.from(arguments: [
            "DHCharListHost",
            DHCharListHostLaunchConfiguration.persistenceSwiftDataArgument
        ])

        XCTAssertEqual(configuration.persistence, .swiftData)
    }
}
