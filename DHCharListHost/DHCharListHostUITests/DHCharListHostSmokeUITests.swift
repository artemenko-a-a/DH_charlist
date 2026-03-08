import XCTest

final class DHCharListHostSmokeUITests: DHCharListHostUITestCase {
    func testSmokeCoreFlowsAndEntryPoints() {
        launchForSmoke()

        let createButton = app.buttons["Create Character"]
        XCTAssertTrue(createButton.waitForExistence(timeout: 5))
        createButton.tap()
        XCTAssertTrue(app.navigationBars["Create Character"].waitForExistence(timeout: 5))

        let blankCharacterButton = app.buttons["quickstart.blank-character"]
        if blankCharacterButton.waitForExistence(timeout: 5) {
            blankCharacterButton.tap()
        } else {
            let blankCharacterRow = app.otherElements["quickstart.blank-character"]
            XCTAssertTrue(blankCharacterRow.waitForExistence(timeout: 5))
            blankCharacterRow.tap()
        }

        XCTAssertTrue(app.staticTexts["New Acolyte"].waitForExistence(timeout: 8))

        openCharacterDetail()
        XCTAssertTrue(app.navigationBars["Smoke Acolyte"].waitForExistence(timeout: 8))

        let editProfileButton = app.staticTexts["Edit Profile"]
        XCTAssertTrue(editProfileButton.waitForExistence(timeout: 5))
        editProfileButton.tap()
        XCTAssertTrue(app.navigationBars["Profile"].waitForExistence(timeout: 5))

        let nameField = app.textFields["Character Name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap()
        nameField.clearAndEnterText("Smoke Edited")

        returnToCharacterDetail()
        XCTAssertTrue(app.staticTexts["Smoke Edited"].waitForExistence(timeout: 8))

        openDetailSection("Characteristics & Resources", expectedNavTitle: "Characteristics")
        openDetailSection("Skills", expectedNavTitle: "Skills")
        openDetailSection("Notes", expectedNavTitle: "Notes")
        openDetailSection("Equipment", expectedNavTitle: "Equipment")
        openDetailSection("Session Mode", expectedNavTitle: "Session")
        openDetailSection("Campaign Log & History", expectedNavTitle: "Campaign Log")

        returnToCharactersList()

        let templatesButton = app.buttons["Manage Templates"]
        XCTAssertTrue(templatesButton.waitForExistence(timeout: 5))
        templatesButton.tap()
        XCTAssertTrue(app.navigationBars["Manage Templates"].waitForExistence(timeout: 5))
        app.buttons["Close"].tap()

        let importExportMenu = app.buttons["Import or Export Characters"]
        XCTAssertTrue(importExportMenu.waitForExistence(timeout: 5))
        importExportMenu.tap()
        XCTAssertTrue(app.buttons["Import JSON"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Export JSON"].waitForExistence(timeout: 5))
    }
}

private extension XCUIElement {
    func clearAndEnterText(_ text: String) {
        guard let currentValue = value as? String else {
            tap()
            typeText(text)
            return
        }

        tap()
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: currentValue.count)
        typeText(deleteString + text)
    }
}
