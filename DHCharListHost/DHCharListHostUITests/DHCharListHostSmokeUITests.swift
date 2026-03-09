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

    func testQuickMechanicsHelpersAcrossCharacteristicSkillAndSessionFlows() {
        launchForSmoke()
        openCharacterDetail()
        XCTAssertTrue(app.navigationBars["Smoke Acolyte"].waitForExistence(timeout: 8))

        let characteristicsSection = app.staticTexts["Characteristics & Resources"]
        XCTAssertTrue(characteristicsSection.waitForExistence(timeout: 5))
        characteristicsSection.tap()
        XCTAssertTrue(app.navigationBars["Characteristics"].waitForExistence(timeout: 5))

        let weaponSkillQuickCheck = app.buttons["quick-check.characteristic.weaponSkill"]
        XCTAssertTrue(weaponSkillQuickCheck.waitForExistence(timeout: 5))
        weaponSkillQuickCheck.tap()
        XCTAssertTrue(app.navigationBars["Quick Check"].waitForExistence(timeout: 5))

        let plusTwentyModifier = app.buttons["quick-check.modifier.plus20"]
        XCTAssertTrue(plusTwentyModifier.waitForExistence(timeout: 5))
        plusTwentyModifier.tap()
        assertQuickCheckFinalTarget("20")

        let customModifierField = app.textFields["quick-check.custom-modifier"]
        XCTAssertTrue(customModifierField.waitForExistence(timeout: 5))
        customModifierField.clearAndEnterText("-10")

        let applyCustomModifierButton = app.buttons["quick-check.apply-custom"]
        XCTAssertTrue(applyCustomModifierButton.waitForExistence(timeout: 5))
        applyCustomModifierButton.tap()
        assertQuickCheckFinalTarget("-10")

        app.buttons["Done"].tap()
        app.navigationBars.buttons.element(boundBy: 0).tap()

        let skillsSection = app.staticTexts["Skills"]
        XCTAssertTrue(skillsSection.waitForExistence(timeout: 5))
        skillsSection.tap()
        XCTAssertTrue(app.navigationBars["Skills"].waitForExistence(timeout: 5))

        let addSkillButton = app.buttons["Add Skill"]
        XCTAssertTrue(addSkillButton.waitForExistence(timeout: 5))
        addSkillButton.tap()
        XCTAssertTrue(app.navigationBars["Add Skill"].waitForExistence(timeout: 5))

        let skillNameField = app.textFields["Skill Name"]
        XCTAssertTrue(skillNameField.waitForExistence(timeout: 5))
        skillNameField.tap()
        skillNameField.typeText("Awareness")
        app.buttons["Save"].tap()

        let awarenessQuickCheck = app.buttons["Quick Check Awareness"]
        XCTAssertTrue(awarenessQuickCheck.waitForExistence(timeout: 5))
        awarenessQuickCheck.tap()
        XCTAssertTrue(app.navigationBars["Quick Check"].waitForExistence(timeout: 5))

        let plusThirtyModifier = app.buttons["quick-check.modifier.plus30"]
        XCTAssertTrue(plusThirtyModifier.waitForExistence(timeout: 5))
        plusThirtyModifier.tap()
        assertQuickCheckFinalTarget("10")

        app.buttons["Done"].tap()
        app.navigationBars.buttons.element(boundBy: 0).tap()

        let sessionSection = app.staticTexts["Session Mode"]
        XCTAssertTrue(sessionSection.waitForExistence(timeout: 5))
        sessionSection.tap()
        XCTAssertTrue(app.navigationBars["Session"].waitForExistence(timeout: 5))

        let sessionQuickMechanicsButton = app.buttons["quick-mechanics.session"]
        XCTAssertTrue(sessionQuickMechanicsButton.waitForExistence(timeout: 5))
        sessionQuickMechanicsButton.tap()
        XCTAssertTrue(app.navigationBars["Quick Check"].waitForExistence(timeout: 5))
        app.buttons["Done"].tap()
    }

    private func assertQuickCheckFinalTarget(_ expectedValue: String) {
        let finalTarget = app.staticTexts["quick-check.final-target"]
        reveal(finalTarget, maxSwipes: 4)
        XCTAssertTrue(finalTarget.waitForExistence(timeout: 5))
        XCTAssertEqual(finalTarget.label, expectedValue)
    }

    private func reveal(_ element: XCUIElement, maxSwipes: Int) {
        guard !element.exists else { return }

        for _ in 0..<maxSwipes {
            app.swipeUp()
            if element.waitForExistence(timeout: 1) {
                return
            }
        }
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
