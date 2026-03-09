import XCTest

final class DHCharListHostSmokeUITests: DHCharListHostUITestCase {
    func testPersistenceStatusShowsJSONDefaultBackend() {
        launchForSmoke()
        openPersistenceStatus()

        let requested = app.staticTexts["persistence.status.requested.value"]
        let active = app.staticTexts["persistence.status.active.value"]
        let fallback = app.staticTexts["persistence.status.fallback.value"]

        XCTAssertTrue(requested.waitForExistence(timeout: 5))
        XCTAssertEqual(requested.label, "JSON File")
        XCTAssertTrue(active.waitForExistence(timeout: 5))
        XCTAssertEqual(active.label, "JSON File")
        XCTAssertTrue(fallback.waitForExistence(timeout: 5))
        XCTAssertEqual(fallback.label, "No")
    }

    func testPersistenceStatusShowsSwiftDataWhenRequested() {
        app.launchArguments.removeAll { $0 == "-dh-ui-persistence-json" }
        app.launchArguments += ["-dh-ui-persistence-swiftdata"]
        launchForSmoke()
        openPersistenceStatus()

        let requested = app.staticTexts["persistence.status.requested.value"]
        let active = app.staticTexts["persistence.status.active.value"]
        let fallback = app.staticTexts["persistence.status.fallback.value"]

        XCTAssertTrue(requested.waitForExistence(timeout: 5))
        XCTAssertEqual(requested.label, "SwiftData")
        XCTAssertTrue(active.waitForExistence(timeout: 5))
        XCTAssertEqual(active.label, "SwiftData")
        XCTAssertTrue(fallback.waitForExistence(timeout: 5))
        XCTAssertEqual(fallback.label, "No")
    }

    func testImportReplaceAllPreviewCanBeCancelledSafely() {
        app.launchArguments += ["-dh-ui-stage-import-preview"]
        launchForSmoke()

        let replaceButton = app.buttons["Replace Local Characters"]
        let cancelButton = button(containing: "Cancel")
        XCTAssertTrue(replaceButton.waitForExistence(timeout: 8))
        XCTAssertTrue(cancelButton.waitForExistence(timeout: 5))
        XCTAssertTrue(staticText(containing: "Imported file contains 1 character.").waitForExistence(timeout: 5))
        XCTAssertTrue(staticText(containing: "does not merge").waitForExistence(timeout: 5))
        XCTAssertTrue(staticText(containing: "will be removed").waitForExistence(timeout: 5))

        cancelButton.tap()

        XCTAssertTrue(labeledElement(containing: "Smoke Acolyte").waitForExistence(timeout: 8))
        XCTAssertFalse(labeledElement(containing: "Imported Preview").exists)
    }

    func testImportReplaceAllPreviewCanBeConfirmedExplicitly() {
        app.launchArguments += ["-dh-ui-stage-import-preview"]
        launchForSmoke()

        let replaceButton = app.buttons["Replace Local Characters"]
        XCTAssertTrue(replaceButton.waitForExistence(timeout: 8))

        replaceButton.tap()

        let firstCharacterCell = app.cells.element(boundBy: 1)
        XCTAssertTrue(firstCharacterCell.waitForExistence(timeout: 8))
        firstCharacterCell.tap()

        XCTAssertTrue(app.navigationBars["Imported Preview"].waitForExistence(timeout: 8))
        XCTAssertFalse(labeledElement(containing: "Smoke Acolyte").exists)
    }

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

    func testCombatWorkspaceActivePlayFlow() {
        launchForSmoke()
        openCharacterDetail()
        XCTAssertTrue(app.navigationBars["Smoke Acolyte"].waitForExistence(timeout: 8))

        let equipmentSection = app.staticTexts["Equipment"]
        XCTAssertTrue(equipmentSection.waitForExistence(timeout: 5))
        equipmentSection.tap()
        XCTAssertTrue(app.navigationBars["Equipment"].waitForExistence(timeout: 5))

        let addWeaponButton = app.buttons["Add Weapon"]
        XCTAssertTrue(addWeaponButton.waitForExistence(timeout: 5))
        addWeaponButton.tap()
        XCTAssertTrue(app.navigationBars["Add Weapon"].waitForExistence(timeout: 5))

        let weaponNameField = app.textFields["Weapon Name"]
        XCTAssertTrue(weaponNameField.waitForExistence(timeout: 5))
        weaponNameField.tap()
        weaponNameField.typeText("Laspistol")
        app.buttons["Save"].tap()

        app.navigationBars.buttons.element(boundBy: 0).tap()

        let sessionSection = app.staticTexts["Session Mode"]
        reveal(sessionSection, maxSwipes: 3)
        XCTAssertTrue(sessionSection.waitForExistence(timeout: 5))
        sessionSection.tap()
        XCTAssertTrue(app.navigationBars["Session"].waitForExistence(timeout: 5))

        let increaseWounds = app.buttons["combat.wounds.increment"]
        XCTAssertTrue(increaseWounds.waitForExistence(timeout: 5))
        increaseWounds.tap()
        let woundsValue = app.staticTexts["combat.wounds.value"]
        XCTAssertTrue(woundsValue.waitForExistence(timeout: 5))
        XCTAssertEqual(woundsValue.label, "1")

        let activeWeaponButton = app.buttons["Set Active Weapon Laspistol"]
        reveal(activeWeaponButton, maxSwipes: 3)
        XCTAssertTrue(activeWeaponButton.waitForExistence(timeout: 5))
        activeWeaponButton.tap()
        let activeWeaponName = app.staticTexts["combat.active-weapon.name"]
        XCTAssertTrue(activeWeaponName.waitForExistence(timeout: 5))
        XCTAssertEqual(activeWeaponName.label, "Laspistol")

        let weaponSkillQuickCheck = app.buttons["quick-mechanics.session.weapon-skill"]
        reveal(weaponSkillQuickCheck, maxSwipes: 2)
        XCTAssertTrue(weaponSkillQuickCheck.waitForExistence(timeout: 5))
        weaponSkillQuickCheck.tap()
        XCTAssertTrue(app.navigationBars["Quick Check"].waitForExistence(timeout: 5))
        app.buttons["Done"].tap()

        let addConditionButton = app.buttons["combat.add-condition"]
        reveal(addConditionButton, maxSwipes: 3)
        XCTAssertTrue(addConditionButton.waitForExistence(timeout: 5))
        addConditionButton.tap()
        XCTAssertTrue(app.navigationBars["Add Condition"].waitForExistence(timeout: 5))

        let conditionField = textInput("combat.condition.text")
        XCTAssertTrue(conditionField.waitForExistence(timeout: 5))
        conditionField.tap()
        conditionField.typeText("Pinned Down")
        app.buttons["Save"].tap()
        XCTAssertTrue(app.staticTexts["Pinned Down"].waitForExistence(timeout: 5))

        let addPinnedCheckButton = app.buttons["Add Pinned Check"]
        reveal(addPinnedCheckButton, maxSwipes: 3)
        XCTAssertTrue(addPinnedCheckButton.waitForExistence(timeout: 5))
        addPinnedCheckButton.tap()
        XCTAssertTrue(app.navigationBars["Add Check"].waitForExistence(timeout: 5))

        let pinnedCheckField = textInput("Pinned Check")
        XCTAssertTrue(pinnedCheckField.waitForExistence(timeout: 5))
        pinnedCheckField.tap()
        pinnedCheckField.typeText("Dodge +10")
        app.buttons["Save"].tap()
        XCTAssertTrue(app.staticTexts["Dodge +10"].waitForExistence(timeout: 5))

        let addTemporaryModifierButton = app.buttons["Add Temporary Modifier"]
        reveal(addTemporaryModifierButton, maxSwipes: 3)
        XCTAssertTrue(addTemporaryModifierButton.waitForExistence(timeout: 5))
        addTemporaryModifierButton.tap()
        XCTAssertTrue(app.navigationBars["Add Modifier"].waitForExistence(timeout: 5))

        let modifierLabelField = app.textFields["Modifier Label"]
        XCTAssertTrue(modifierLabelField.waitForExistence(timeout: 5))
        modifierLabelField.tap()
        modifierLabelField.typeText("Smoke")

        let modifierValueField = app.textFields["Modifier Value"]
        XCTAssertTrue(modifierValueField.waitForExistence(timeout: 5))
        modifierValueField.tap()
        modifierValueField.clearAndEnterText("-20")
        app.buttons["Save"].tap()
        XCTAssertTrue(app.staticTexts["Smoke"].waitForExistence(timeout: 5))
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

    private func textInput(_ identifier: String) -> XCUIElement {
        let textField = app.textFields[identifier]
        if textField.exists {
            return textField
        }
        return app.textViews[identifier]
    }

    private func staticText(containing snippet: String) -> XCUIElement {
        app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", snippet)).firstMatch
    }

    private func button(containing snippet: String) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", snippet)).firstMatch
    }

    private func labeledElement(containing snippet: String) -> XCUIElement {
        app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@", snippet)).firstMatch
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
