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

    func testCharacterDossierPreviewPreparesPrintablePDF() {
        launchForSmoke()
        openCharacterDetail()
        XCTAssertTrue(app.navigationBars["Smoke Acolyte"].waitForExistence(timeout: 8))

        let dossierButton = app.buttons["dossier.open"]
        XCTAssertTrue(dossierButton.waitForExistence(timeout: 5))
        dossierButton.tap()

        XCTAssertTrue(app.navigationBars["Character Dossier"].waitForExistence(timeout: 8))

        let pdfStatus = app.staticTexts["dossier.pdf.status"]
        XCTAssertTrue(pdfStatus.waitForExistence(timeout: 8))
        XCTAssertTrue(pdfStatus.label.localizedCaseInsensitiveContains("ready"))

        let shareButton = app.buttons["dossier.share.pdf"]
        XCTAssertTrue(shareButton.waitForExistence(timeout: 5))
        XCTAssertTrue(shareButton.isEnabled)

        app.buttons["Close"].tap()
        XCTAssertTrue(app.navigationBars["Smoke Acolyte"].waitForExistence(timeout: 8))
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

        let dossierButton = app.buttons["dossier.open"]
        XCTAssertTrue(dossierButton.waitForExistence(timeout: 5))

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
        reveal(sessionQuickMechanicsButton, maxSwipes: 3)
        XCTAssertTrue(sessionQuickMechanicsButton.waitForExistence(timeout: 5))
        sessionQuickMechanicsButton.tap()
        XCTAssertTrue(app.navigationBars["Quick Check"].waitForExistence(timeout: 5))
        app.buttons["Done"].tap()
    }

    func testXPSpendingValidationAppliesBoundedAdvancement() {
        launchForSmoke()
        openCharacterDetail()
        XCTAssertTrue(app.navigationBars["Smoke Acolyte"].waitForExistence(timeout: 8))

        let characteristicsSection = app.staticTexts["Characteristics & Resources"]
        XCTAssertTrue(characteristicsSection.waitForExistence(timeout: 5))
        characteristicsSection.tap()
        XCTAssertTrue(app.navigationBars["Characteristics"].waitForExistence(timeout: 5))

        let openXPSpend = app.buttons["xp-spend.open"]
        reveal(openXPSpend, maxSwipes: 3)
        XCTAssertTrue(openXPSpend.waitForExistence(timeout: 5))
        openXPSpend.tap()

        XCTAssertTrue(app.navigationBars["XP Spending"].waitForExistence(timeout: 5))

        let applyButton = app.buttons["xp-spend.apply"]
        XCTAssertTrue(applyButton.waitForExistence(timeout: 5))
        XCTAssertTrue(applyButton.isEnabled)
        applyButton.tap()

        XCTAssertTrue(app.navigationBars["Characteristics"].waitForExistence(timeout: 8))
        app.navigationBars.buttons.element(boundBy: 0).tap()

        let historySection = app.staticTexts["Campaign Log & History"]
        reveal(historySection, maxSwipes: 3)
        XCTAssertTrue(historySection.waitForExistence(timeout: 5))
        historySection.tap()

        XCTAssertTrue(app.navigationBars["Campaign Log"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Advancement: Weapon Skill +5"].waitForExistence(timeout: 8))
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

        for _ in 0..<3 {
            app.swipeDown()
        }

        let reopenQuickCheck = app.buttons["quick-mechanics.session"]
        reveal(reopenQuickCheck, maxSwipes: 4)
        XCTAssertTrue(reopenQuickCheck.waitForExistence(timeout: 5))
        reopenQuickCheck.tap()
        XCTAssertTrue(app.navigationBars["Quick Check"].waitForExistence(timeout: 5))

        let smokeSessionModifier = app.buttons["quick-check.session-modifier.Smoke"]
        reveal(smokeSessionModifier, maxSwipes: 4)
        XCTAssertTrue(smokeSessionModifier.waitForExistence(timeout: 5))

        let activeCondition = app.otherElements["quick-check.condition.Pinned Down"]
        reveal(activeCondition, maxSwipes: 4)
        XCTAssertTrue(activeCondition.waitForExistence(timeout: 5))

        app.buttons["Done"].tap()
    }

    func testCombatEncounterShortcutsFlow() {
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
        for _ in 0..<6 {
            increaseWounds.tap()
        }
        let woundsValue = app.staticTexts["combat.wounds.value"]
        XCTAssertTrue(woundsValue.waitForExistence(timeout: 5))
        XCTAssertEqual(woundsValue.label, "6")

        let activeWeaponButton = app.buttons["Set Active Weapon Laspistol"]
        reveal(activeWeaponButton, maxSwipes: 3)
        XCTAssertTrue(activeWeaponButton.waitForExistence(timeout: 5))
        activeWeaponButton.tap()

        let aimToggle = app.buttons["combat.toggle.modifier.aim"]
        reveal(aimToggle, maxSwipes: 3)
        XCTAssertTrue(aimToggle.waitForExistence(timeout: 5))
        aimToggle.tap()

        let pinnedToggle = app.buttons["combat.toggle.condition.pinned-down"]
        reveal(pinnedToggle, maxSwipes: 3)
        XCTAssertTrue(pinnedToggle.waitForExistence(timeout: 5))
        pinnedToggle.tap()

        let attackShortcut = app.buttons["combat.shortcut.attack"]
        reveal(attackShortcut, maxSwipes: 3)
        XCTAssertTrue(attackShortcut.waitForExistence(timeout: 5))
        attackShortcut.tap()
        XCTAssertTrue(app.navigationBars["Attack Shortcut"].waitForExistence(timeout: 5))

        let attackCustomModifier = textInput("combat.attack.custom-modifier")
        reveal(attackCustomModifier, maxSwipes: 3)
        XCTAssertTrue(attackCustomModifier.waitForExistence(timeout: 5))
        attackCustomModifier.tap()
        attackCustomModifier.clearAndEnterText("30")

        let applyAttackCustomModifier = app.buttons["combat.attack.apply-custom"]
        XCTAssertTrue(applyAttackCustomModifier.waitForExistence(timeout: 5))
        applyAttackCustomModifier.tap()

        let attackRoll = textInput("combat.attack.roll")
        reveal(attackRoll, maxSwipes: 3)
        XCTAssertTrue(attackRoll.waitForExistence(timeout: 5))
        attackRoll.tap()
        attackRoll.typeText("20")

        let attackRawDamage = textInput("combat.attack.raw-damage")
        reveal(attackRawDamage, maxSwipes: 3)
        XCTAssertTrue(attackRawDamage.waitForExistence(timeout: 5))
        attackRawDamage.tap()
        attackRawDamage.typeText("9")

        let targetWounds = textInput("combat.attack.target-wounds")
        XCTAssertTrue(targetWounds.waitForExistence(timeout: 5))
        targetWounds.tap()
        targetWounds.clearAndEnterText("7")

        let targetArmour = textInput("combat.attack.target-armour")
        XCTAssertTrue(targetArmour.waitForExistence(timeout: 5))
        targetArmour.tap()
        targetArmour.clearAndEnterText("2")

        let targetToughness = textInput("combat.attack.target-toughness")
        XCTAssertTrue(targetToughness.waitForExistence(timeout: 5))
        targetToughness.tap()
        targetToughness.clearAndEnterText("3")

        let appliedDamage = app.staticTexts["combat.attack.damage.applied"]
        reveal(appliedDamage, maxSwipes: 3)
        XCTAssertTrue(appliedDamage.waitForExistence(timeout: 5))

        app.buttons["Close"].tap()
        XCTAssertTrue(app.navigationBars["Session"].waitForExistence(timeout: 5))

        let damageShortcut = app.buttons["combat.shortcut.damage"]
        reveal(damageShortcut, maxSwipes: 3)
        XCTAssertTrue(damageShortcut.waitForExistence(timeout: 5))
        damageShortcut.tap()
        XCTAssertTrue(app.navigationBars["Apply Damage"].waitForExistence(timeout: 5))

        let incomingRawDamage = textInput("combat.damage.raw")
        XCTAssertTrue(incomingRawDamage.waitForExistence(timeout: 5))
        incomingRawDamage.tap()
        incomingRawDamage.clearAndEnterText("8")

        let incomingArmour = textInput("combat.damage.armour")
        XCTAssertTrue(incomingArmour.waitForExistence(timeout: 5))
        incomingArmour.tap()
        incomingArmour.clearAndEnterText("1")

        let incomingPenetration = textInput("combat.damage.penetration")
        XCTAssertTrue(incomingPenetration.waitForExistence(timeout: 5))
        incomingPenetration.tap()
        incomingPenetration.clearAndEnterText("0")

        let applyIncomingDamage = app.buttons["combat.damage.apply"]
        reveal(applyIncomingDamage, maxSwipes: 2)
        XCTAssertTrue(applyIncomingDamage.waitForExistence(timeout: 5))
        applyIncomingDamage.tap()
        XCTAssertTrue(app.navigationBars["Session"].waitForExistence(timeout: 5))

        let dodgeShortcut = app.buttons["combat.shortcut.dodge"]
        reveal(dodgeShortcut, maxSwipes: 3)
        XCTAssertTrue(dodgeShortcut.waitForExistence(timeout: 5))
        dodgeShortcut.tap()
        XCTAssertTrue(app.navigationBars["Dodge Shortcut"].waitForExistence(timeout: 5))

        let dodgeCustomModifier = textInput("combat.reaction.custom-modifier")
        reveal(dodgeCustomModifier, maxSwipes: 3)
        XCTAssertTrue(dodgeCustomModifier.waitForExistence(timeout: 5))
        dodgeCustomModifier.tap()
        dodgeCustomModifier.clearAndEnterText("30")
        app.buttons["Apply Custom Modifier"].tap()

        let dodgeRoll = textInput("combat.reaction.roll")
        reveal(dodgeRoll, maxSwipes: 3)
        XCTAssertTrue(dodgeRoll.waitForExistence(timeout: 5))
        dodgeRoll.tap()
        dodgeRoll.typeText("5")
        app.buttons["Close"].tap()
        XCTAssertTrue(app.navigationBars["Session"].waitForExistence(timeout: 5))

        let parryShortcut = app.buttons["combat.shortcut.parry"]
        reveal(parryShortcut, maxSwipes: 3)
        XCTAssertTrue(parryShortcut.waitForExistence(timeout: 5))
        parryShortcut.tap()
        XCTAssertTrue(app.navigationBars["Parry Shortcut"].waitForExistence(timeout: 5))

        let parryCustomModifier = textInput("combat.reaction.custom-modifier")
        reveal(parryCustomModifier, maxSwipes: 3)
        XCTAssertTrue(parryCustomModifier.waitForExistence(timeout: 5))
        parryCustomModifier.tap()
        parryCustomModifier.clearAndEnterText("40")
        app.buttons["Apply Custom Modifier"].tap()

        let parryRoll = textInput("combat.reaction.roll")
        reveal(parryRoll, maxSwipes: 3)
        XCTAssertTrue(parryRoll.waitForExistence(timeout: 5))
        parryRoll.tap()
        parryRoll.typeText("10")
        app.buttons["Close"].tap()
    }

    func testWeaponCompendiumAutocompleteAddsDetachedEditableCopy() {
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

        let compendiumSearchField = textInput("weapon-compendium.search")
        XCTAssertTrue(compendiumSearchField.waitForExistence(timeout: 5))
        compendiumSearchField.tap()
        compendiumSearchField.typeText("las")

        let laspistolSuggestion = app.buttons["weapon-compendium.pick.local-demo.laspistol"]
        XCTAssertTrue(laspistolSuggestion.waitForExistence(timeout: 5))
        laspistolSuggestion.tap()

        let weaponNameField = app.textFields["Weapon Name"]
        XCTAssertTrue(weaponNameField.waitForExistence(timeout: 5))
        XCTAssertEqual(weaponNameField.value as? String, "Laspistol")
        weaponNameField.clearAndEnterText("Custom Laspistol")

        let penetrationField = app.textFields["Weapon Penetration"]
        XCTAssertTrue(penetrationField.waitForExistence(timeout: 5))
        penetrationField.clearAndEnterText("1")

        app.buttons["Save"].tap()
        XCTAssertTrue(labeledElement(containing: "Custom Laspistol").waitForExistence(timeout: 5))

        labeledElement(containing: "Custom Laspistol").tap()
        XCTAssertTrue(app.navigationBars["Edit Weapon"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.textFields["Weapon Name"].value as? String, "Custom Laspistol")
        XCTAssertEqual(app.textFields["Weapon Penetration"].value as? String, "1")
        app.buttons["Cancel"].tap()

        addWeaponButton.tap()
        XCTAssertTrue(app.navigationBars["Add Weapon"].waitForExistence(timeout: 5))

        let secondCompendiumSearchField = textInput("weapon-compendium.search")
        XCTAssertTrue(secondCompendiumSearchField.waitForExistence(timeout: 5))
        secondCompendiumSearchField.tap()
        secondCompendiumSearchField.typeText("las")

        let secondLaspistolSuggestion = app.buttons["weapon-compendium.pick.local-demo.laspistol"]
        XCTAssertTrue(secondLaspistolSuggestion.waitForExistence(timeout: 5))
        secondLaspistolSuggestion.tap()

        XCTAssertEqual(app.textFields["Weapon Name"].value as? String, "Laspistol")
        XCTAssertEqual(app.textFields["Weapon Penetration"].value as? String, "0")
        app.buttons["Cancel"].tap()

        XCTAssertTrue(labeledElement(containing: "Custom Laspistol").waitForExistence(timeout: 5))
    }

    func testArmourCompendiumAutocompleteAddsDetachedEditableCopy() {
        launchForSmoke()
        openCharacterDetail()
        XCTAssertTrue(app.navigationBars["Smoke Acolyte"].waitForExistence(timeout: 8))

        let equipmentSection = app.staticTexts["Equipment"]
        XCTAssertTrue(equipmentSection.waitForExistence(timeout: 5))
        equipmentSection.tap()
        XCTAssertTrue(app.navigationBars["Equipment"].waitForExistence(timeout: 5))

        let addArmourButton = app.buttons["Add Armour"]
        XCTAssertTrue(addArmourButton.waitForExistence(timeout: 5))
        addArmourButton.tap()
        XCTAssertTrue(app.navigationBars["Add Armour"].waitForExistence(timeout: 5))

        let compendiumSearchField = textInput("armour-compendium.search")
        XCTAssertTrue(compendiumSearchField.waitForExistence(timeout: 5))
        compendiumSearchField.tap()
        compendiumSearchField.typeText("flak")

        let flakSuggestion = app.buttons["armour-compendium.pick.local-demo.flak-coat"]
        XCTAssertTrue(flakSuggestion.waitForExistence(timeout: 5))
        flakSuggestion.tap()

        let locationField = app.textFields["Armour Location"]
        XCTAssertTrue(locationField.waitForExistence(timeout: 5))
        XCTAssertEqual(locationField.value as? String, "Flak Coat (Body, Arms)")
        locationField.clearAndEnterText("Custom Flak Coat")

        let armourPointsField = app.textFields["Armour Points"]
        XCTAssertTrue(armourPointsField.waitForExistence(timeout: 5))
        XCTAssertEqual(armourPointsField.value as? String, "4")
        armourPointsField.clearAndEnterText("5")

        app.buttons["Save"].tap()
        XCTAssertTrue(app.navigationBars["Equipment"].waitForExistence(timeout: 5))
        let customArmourRow = button(containing: "Custom Flak Coat")
        XCTAssertTrue(customArmourRow.waitForExistence(timeout: 5))

        addArmourButton.tap()
        XCTAssertTrue(app.navigationBars["Add Armour"].waitForExistence(timeout: 5))

        let secondCompendiumSearchField = textInput("armour-compendium.search")
        XCTAssertTrue(secondCompendiumSearchField.waitForExistence(timeout: 5))
        secondCompendiumSearchField.tap()
        secondCompendiumSearchField.typeText("flak")

        let secondFlakSuggestion = app.buttons["armour-compendium.pick.local-demo.flak-coat"]
        XCTAssertTrue(secondFlakSuggestion.waitForExistence(timeout: 5))
        secondFlakSuggestion.tap()

        XCTAssertEqual(app.textFields["Armour Location"].value as? String, "Flak Coat (Body, Arms)")
        XCTAssertEqual(app.textFields["Armour Points"].value as? String, "4")
        app.buttons["Cancel"].tap()

        XCTAssertTrue(labeledElement(containing: "Custom Flak Coat").waitForExistence(timeout: 5))
    }

    func testWeaponCompendiumImportReplacesLocalCatalogWithoutMutatingSavedWeapons() {
        app.launchArguments += ["-dh-ui-stage-weapon-compendium-import"]
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

        let compendiumSearchField = textInput("weapon-compendium.search")
        XCTAssertTrue(compendiumSearchField.waitForExistence(timeout: 5))
        compendiumSearchField.tap()
        compendiumSearchField.typeText("las")

        let laspistolSuggestion = app.buttons["weapon-compendium.pick.local-demo.laspistol"]
        XCTAssertTrue(laspistolSuggestion.waitForExistence(timeout: 5))
        laspistolSuggestion.tap()

        let weaponNameField = app.textFields["Weapon Name"]
        XCTAssertTrue(weaponNameField.waitForExistence(timeout: 5))
        weaponNameField.clearAndEnterText("Legacy Laspistol")

        let penetrationField = app.textFields["Weapon Penetration"]
        XCTAssertTrue(penetrationField.waitForExistence(timeout: 5))
        penetrationField.clearAndEnterText("1")

        app.buttons["Save"].tap()
        XCTAssertTrue(labeledElement(containing: "Legacy Laspistol").waitForExistence(timeout: 5))

        let importCompendiumButton = app.buttons["weapon-compendium.import"]
        XCTAssertTrue(importCompendiumButton.waitForExistence(timeout: 5))
        importCompendiumButton.tap()

        XCTAssertTrue(staticText(containing: "UI Imported Catalog").waitForExistence(timeout: 5))
        XCTAssertTrue(staticText(containing: "replaces your current local compendium").waitForExistence(timeout: 5))
        let replaceCompendiumButton = button(containing: "Replace Local Compendium")
        XCTAssertTrue(replaceCompendiumButton.waitForExistence(timeout: 5))
        replaceCompendiumButton.tap()

        addWeaponButton.tap()
        XCTAssertTrue(app.navigationBars["Add Weapon"].waitForExistence(timeout: 5))

        let importedCompendiumSearchField = textInput("weapon-compendium.search")
        XCTAssertTrue(importedCompendiumSearchField.waitForExistence(timeout: 5))
        importedCompendiumSearchField.tap()
        importedCompendiumSearchField.typeText("mnem")

        let importedSuggestion = app.buttons["weapon-compendium.pick.ui-imported.mnemonic-pistol"]
        XCTAssertTrue(importedSuggestion.waitForExistence(timeout: 5))
        importedSuggestion.tap()

        XCTAssertEqual(app.textFields["Weapon Name"].value as? String, "Mnemonic Pistol")
        XCTAssertEqual(app.textFields["Weapon Penetration"].value as? String, "3")
        app.buttons["Cancel"].tap()

        labeledElement(containing: "Legacy Laspistol").tap()
        XCTAssertTrue(app.navigationBars["Edit Weapon"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.textFields["Weapon Name"].value as? String, "Legacy Laspistol")
        XCTAssertEqual(app.textFields["Weapon Penetration"].value as? String, "1")
        app.buttons["Cancel"].tap()
    }

    func testArmourCompendiumImportReplacesLocalCatalogWithoutMutatingSavedArmour() {
        app.launchArguments += ["-dh-ui-stage-armour-compendium-import"]
        launchForSmoke()
        openCharacterDetail()
        XCTAssertTrue(app.navigationBars["Smoke Acolyte"].waitForExistence(timeout: 8))

        let equipmentSection = app.staticTexts["Equipment"]
        XCTAssertTrue(equipmentSection.waitForExistence(timeout: 5))
        equipmentSection.tap()
        XCTAssertTrue(app.navigationBars["Equipment"].waitForExistence(timeout: 5))

        let addArmourButton = app.buttons["Add Armour"]
        XCTAssertTrue(addArmourButton.waitForExistence(timeout: 5))
        addArmourButton.tap()
        XCTAssertTrue(app.navigationBars["Add Armour"].waitForExistence(timeout: 5))

        let compendiumSearchField = textInput("armour-compendium.search")
        XCTAssertTrue(compendiumSearchField.waitForExistence(timeout: 5))
        compendiumSearchField.tap()
        compendiumSearchField.typeText("flak")

        let flakSuggestion = app.buttons["armour-compendium.pick.local-demo.flak-coat"]
        XCTAssertTrue(flakSuggestion.waitForExistence(timeout: 5))
        flakSuggestion.tap()

        let locationField = app.textFields["Armour Location"]
        XCTAssertTrue(locationField.waitForExistence(timeout: 5))
        locationField.clearAndEnterText("Legacy Flak Coat")

        let armourPointsField = app.textFields["Armour Points"]
        XCTAssertTrue(armourPointsField.waitForExistence(timeout: 5))
        armourPointsField.clearAndEnterText("5")

        app.buttons["Save"].tap()
        XCTAssertTrue(labeledElement(containing: "Legacy Flak Coat").waitForExistence(timeout: 5))

        let importCompendiumButton = app.buttons["armour-compendium.import"]
        XCTAssertTrue(importCompendiumButton.waitForExistence(timeout: 5))
        importCompendiumButton.tap()

        XCTAssertTrue(staticText(containing: "UI Imported Armour Catalog").waitForExistence(timeout: 5))
        XCTAssertTrue(staticText(containing: "replaces your current local armour compendium").waitForExistence(timeout: 5))

        let replaceCompendiumButton = button(containing: "Replace Local Armour Compendium")
        XCTAssertTrue(replaceCompendiumButton.waitForExistence(timeout: 5))
        replaceCompendiumButton.tap()

        addArmourButton.tap()
        XCTAssertTrue(app.navigationBars["Add Armour"].waitForExistence(timeout: 5))

        let importedCompendiumSearchField = textInput("armour-compendium.search")
        XCTAssertTrue(importedCompendiumSearchField.waitForExistence(timeout: 5))
        importedCompendiumSearchField.tap()
        importedCompendiumSearchField.typeText("mnem")

        let importedSuggestion = app.buttons["armour-compendium.pick.ui-imported-armour.mnemonic-mesh"]
        XCTAssertTrue(importedSuggestion.waitForExistence(timeout: 5))
        importedSuggestion.tap()

        XCTAssertEqual(app.textFields["Armour Location"].value as? String, "Mnemonic Mesh (Body)")
        XCTAssertEqual(app.textFields["Armour Points"].value as? String, "5")
        app.buttons["Cancel"].tap()

        XCTAssertTrue(labeledElement(containing: "Legacy Flak Coat").waitForExistence(timeout: 5))
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
        let textView = app.textViews[identifier]
        if textView.exists {
            return textView
        }
        return textField
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
