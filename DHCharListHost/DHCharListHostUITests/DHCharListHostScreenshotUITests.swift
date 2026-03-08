import XCTest

final class DHCharListHostScreenshotUITests: DHCharListHostUITestCase {
    func testCaptureSeededSmokeScreens() {
        launchForSmoke()
        captureScreenshot(named: "01-characters-list")

        openCharacterDetail()
        captureScreenshot(named: "02-character-detail")

        openDetailSectionAndCapture("Characteristics & Resources", navTitle: "Characteristics", screenshotName: "03-characteristics")
        openDetailSectionAndCapture("Skills", navTitle: "Skills", screenshotName: "04-skills")
        openDetailSectionAndCapture("Notes", navTitle: "Notes", screenshotName: "05-notes")
        openDetailSectionAndCapture("Equipment", navTitle: "Equipment", screenshotName: "06-equipment")
        openDetailSectionAndCapture("Session Mode", navTitle: "Session", screenshotName: "07-session")
        openDetailSectionAndCapture("Campaign Log & History", navTitle: "Campaign Log", screenshotName: "08-history")

        returnToCharactersList()

        app.buttons["Manage Templates"].tap()
        XCTAssertTrue(app.navigationBars["Manage Templates"].waitForExistence(timeout: 5))
        captureScreenshot(named: "09-templates")
        app.buttons["Close"].tap()
    }

    private func openDetailSectionAndCapture(_ sectionTitle: String, navTitle: String, screenshotName: String) {
        let section = app.staticTexts[sectionTitle]
        XCTAssertTrue(section.waitForExistence(timeout: 8))
        section.tap()
        XCTAssertTrue(app.navigationBars[navTitle].waitForExistence(timeout: 8))
        captureScreenshot(named: screenshotName)
        returnToCharacterDetail()
    }

    private func captureScreenshot(named name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
