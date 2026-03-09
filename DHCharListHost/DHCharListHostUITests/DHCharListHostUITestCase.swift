import XCTest

class DHCharListHostUITestCase: XCTestCase {
    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launchArguments += [
            "-dh-uitesting",
            "-dh-ui-reset-data",
            "-dh-ui-seed-smoke",
            "-dh-ui-persistence-json"
        ]
    }

    @discardableResult
    func launchForSmoke() -> XCUIApplication {
        app.launch()
        XCTAssertTrue(app.navigationBars["Characters"].waitForExistence(timeout: 15))
        return app
    }

    func openCharacterDetail(named name: String = "Smoke Acolyte") {
        let nameCell = app.staticTexts[name]
        XCTAssertTrue(nameCell.waitForExistence(timeout: 8))
        nameCell.tap()
    }

    func returnToCharacterDetail() {
        app.navigationBars.buttons.element(boundBy: 0).tap()
    }

    func returnToCharactersList() {
        app.navigationBars.buttons.element(boundBy: 0).tap()
    }

    func openDetailSection(_ sectionTitle: String, expectedNavTitle: String) {
        let section = app.staticTexts[sectionTitle]
        XCTAssertTrue(section.waitForExistence(timeout: 8))
        section.tap()
        XCTAssertTrue(app.navigationBars[expectedNavTitle].waitForExistence(timeout: 8))
        returnToCharacterDetail()
    }

    func openPersistenceStatus() {
        let importExportMenu = app.buttons["Import or Export Characters"]
        XCTAssertTrue(importExportMenu.waitForExistence(timeout: 5))
        importExportMenu.tap()

        let persistenceStatusButton = app.buttons["Persistence Status"]
        XCTAssertTrue(persistenceStatusButton.waitForExistence(timeout: 5))
        persistenceStatusButton.tap()

        XCTAssertTrue(app.navigationBars["Persistence Status"].waitForExistence(timeout: 8))
    }
}
