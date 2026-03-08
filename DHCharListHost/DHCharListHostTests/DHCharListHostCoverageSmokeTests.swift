import XCTest
import DHCharList

final class DHCharListHostCoverageSmokeTests: XCTestCase {
    func testResourceStateExperienceAvailableCalculation() {
        let resources = ResourceState(
            currentWounds: 7,
            maxWounds: 12,
            fatigue: 1,
            corruption: 0,
            insanity: 0,
            currentFate: 1,
            maxFate: 2,
            experienceSpent: 350,
            experienceTotal: 500
        )

        XCTAssertEqual(resources.experienceAvailable, 150)
    }
}
