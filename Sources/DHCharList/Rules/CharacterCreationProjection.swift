import Foundation

struct DHIICreationStartingPackagePreview: Equatable, Sendable {
    let projectedCharacter: Character?
    let projectedInfluence: Int?
    let compatibility: DHIICharacterModelCompatibilityReport
    let validationMessages: [String]

    var isValid: Bool {
        projectedCharacter != nil && validationMessages.isEmpty
    }
}

extension DHIICharacterCreationEngine {
    static func homeWorldTalentOptions(for id: DHIIHomeWorldID?) -> [String] {
        switch id {
        case .forgeWorld:
            ["Technical Knock", "Weapon-Tech"]
        default:
            []
        }
    }

    static func backgroundSkillOptionGroups(for id: DHIIBackgroundID?) -> [[String]] {
        switch id {
        case .adeptusAdministratum:
            [["Commerce", "Medicae"]]
        case .adeptusArbites:
            [["Inquiry", "Interrogation"]]
        case .adeptusAstraTelepathica:
            [["Deceive", "Interrogation"], ["Psyniscience", "Scrutiny"]]
        case .adeptusMechanicus:
            [["Awareness", "Operate (Pick One)"]]
        case .adeptusMinistorum:
            [["Inquiry", "Scrutiny"]]
        case .imperialGuard:
            [["Medicae", "Operate (Surface)"]]
        case .outcast:
            [["Acrobatics", "Sleight of Hand"]]
        default:
            []
        }
    }

    static func backgroundTalentOptions(for id: DHIIBackgroundID?) -> [String] {
        switch id {
        case .adeptusMinistorum:
            ["Weapon Training (Flame)", "Weapon Training (Low-Tech, Solid Projectile)"]
        default:
            []
        }
    }

    static func backgroundEquipmentOptionGroups(for id: DHIIBackgroundID?) -> [[String]] {
        switch id {
        case .adeptusAdministratum:
            [["Laspistol", "Stub Automatic"]]
        case .adeptusArbites:
            [["Shotgun", "Shock Maul"], ["Enforcer Light Carapace Armour", "Carapace Chestplate"]]
        case .adeptusAstraTelepathica:
            [["Staff", "Whip"], ["Light Flak Cloak", "Flak Vest"]]
        case .adeptusMechanicus:
            [["Autogun", "Hand Cannon"], ["Monotask Servo-Skull (Utility)", "Optical Mechadendrite"]]
        case .adeptusMinistorum:
            [["Hand Flamer", "Warhammer and Stub Revolver"], ["Imperial Robes", "Flak Vest"]]
        case .imperialGuard:
            [["Lasgun", "Laspistol and Sword"]]
        case .outcast:
            [["Autopistol", "Laspistol"], ["Armoured Bodyglove", "Flak Vest"], ["Obscura", "Slaught"]]
        default:
            []
        }
    }

    static func previewStartingPackage(
        for draft: DHIICreationDraft,
        baseCharacter: Character = Character(profile: .init()),
        weaponCatalog: WeaponCompendiumCatalog = .demo,
        armourCatalog: ArmourCompendiumCatalog = .demo
    ) -> DHIICreationStartingPackagePreview {
        let aptitudeComposition = draft.aptitudeComposition
        let characteristicPreview = draft.characteristicGeneration

        var unsupportedTargets: [DHIICreationEffectTarget] = []
        var unsupportedRuleKeys: [String] = []
        var warningMessages: [String] = []
        var contextualMessages: [String] = []
        var validationMessages: [String] = []

        if let homeWorld = draft.homeWorldDefinition,
           let preview = previewHomeWorldSelection(rawValue: homeWorld.displayName) {
            unsupportedTargets.append(contentsOf: preview.compatibility.unsupportedTargets)
            warningMessages.append(contentsOf: preview.compatibility.warningMessages)
            contextualMessages.append(contentsOf: preview.compatibility.contextualMessages)
        } else if draft.homeWorldID == nil {
            validationMessages.append("A canonical home world is required before projecting a starting package.")
        }

        if let background = draft.backgroundDefinition,
           let preview = previewBackgroundSelection(rawValue: background.displayName) {
            unsupportedRuleKeys.append(contentsOf: preview.compatibility.unsupportedRuleKeys)
            warningMessages.append(contentsOf: preview.compatibility.warningMessages)
            contextualMessages.append(contentsOf: preview.compatibility.contextualMessages)
        } else if draft.backgroundID == nil {
            validationMessages.append("A canonical background is required before projecting a starting package.")
        }

        if let role = draft.roleDefinition,
           let preview = previewRoleSelection(rawValue: role.displayName) {
            unsupportedRuleKeys.append(contentsOf: preview.compatibility.unsupportedRuleKeys)
            warningMessages.append(contentsOf: preview.compatibility.warningMessages)
            contextualMessages.append(contentsOf: preview.compatibility.contextualMessages)
        } else if draft.roleID == nil {
            validationMessages.append("A canonical role is required before projecting a starting package.")
        }

        if aptitudeComposition.isFullyResolved == false {
            validationMessages.append(contentsOf: aptitudeComposition.unresolvedChoices)
        }
        unsupportedRuleKeys.append(contentsOf: aptitudeComposition.compatibility.unsupportedRuleKeys)
        warningMessages.append(contentsOf: aptitudeComposition.compatibility.warningMessages)
        contextualMessages.append(contentsOf: aptitudeComposition.compatibility.contextualMessages)

        if let characteristicPreview {
            unsupportedTargets.append(contentsOf: characteristicPreview.compatibility.unsupportedTargets)
            warningMessages.append(contentsOf: characteristicPreview.compatibility.warningMessages)
            contextualMessages.append(contentsOf: characteristicPreview.compatibility.contextualMessages)
            if characteristicPreview.isValid == false {
                validationMessages.append(contentsOf: characteristicPreview.validationMessages)
            }
        } else {
            validationMessages.append("Characteristic generation must be resolved before projecting a starting package.")
        }

        validationMessages.append(contentsOf: missingChoiceMessages(for: draft))

        if draft.startingWoundsRoll == nil {
            validationMessages.append("Starting wounds require a 1d5 roll before projection.")
        }
        if draft.startingFateRoll == nil {
            validationMessages.append("Starting fate requires a 1d10 roll before projection.")
        }

        let compatibility = DHIICharacterModelCompatibilityReport(
            unsupportedTargets: stableUniqueTargets(unsupportedTargets),
            unsupportedRuleKeys: stableUniqueStrings(unsupportedRuleKeys),
            warningMessages: stableUniqueStrings(warningMessages),
            contextualMessages: stableUniqueStrings(contextualMessages)
        )

        guard validationMessages.isEmpty,
              let homeWorld = draft.homeWorldDefinition,
              let characteristicValues = characteristicPreview?.values,
              let projectedCharacteristics = characteristicPreview?.projectedCharacteristics,
              let startingWoundsRoll = draft.startingWoundsRoll,
              let startingFateRoll = draft.startingFateRoll else {
            return DHIICreationStartingPackagePreview(
                projectedCharacter: nil,
                projectedInfluence: characteristicPreview?.values?.influence,
                compatibility: compatibility,
                validationMessages: stableUniqueStrings(validationMessages)
            )
        }

        let projectedPackage = buildStartingPackage(
            for: draft,
            weaponCatalog: weaponCatalog,
            armourCatalog: armourCatalog
        )

        var projected = baseCharacter
        projected.profile.homeWorld = homeWorld.displayName
        projected.profile.background = draft.backgroundDefinition?.displayName ?? projected.profile.background
        projected.profile.role = draft.roleDefinition?.displayName ?? projected.profile.role
        projected.profile.aptitudes = aptitudeComposition.effectiveAptitudes
        projected.characteristics = projectedCharacteristics
        projected.resources = ResourceState(
            currentWounds: homeWorld.wounds.base + startingWoundsRoll,
            maxWounds: homeWorld.wounds.base + startingWoundsRoll,
            fatigue: 0,
            corruption: 0,
            insanity: 0,
            currentFate: homeWorld.fateThreshold.baseThreshold + (startingFateRoll >= homeWorld.fateThreshold.emperorsBlessingTarget ? 1 : 0),
            maxFate: homeWorld.fateThreshold.baseThreshold + (startingFateRoll >= homeWorld.fateThreshold.emperorsBlessingTarget ? 1 : 0),
            experienceSpent: 0,
            experienceTotal: 1_000
        )
        projected.skills = projectedPackage.skills
        projected.notes = projectedPackage.notes
        projected.equipment = EquipmentState(
            weapons: projectedPackage.weapons,
            armour: projectedPackage.armour,
            movement: movementProfile(for: projectedCharacteristics),
            inventory: projectedPackage.inventory
        )
        projected.dhiiEngineState = persistedEngineState(for: draft)

        return DHIICreationStartingPackagePreview(
            projectedCharacter: projected,
            projectedInfluence: characteristicValues.influence,
            compatibility: compatibility,
            validationMessages: []
        )
    }

    private static func missingChoiceMessages(for draft: DHIICreationDraft) -> [String] {
        var messages: [String] = []

        if draft.homeWorldTalentOptions.isEmpty == false, draft.homeWorldTalentChoice == nil,
           let homeWorld = draft.homeWorldDefinition {
            messages.append("\(homeWorld.displayName): requires an explicit home world talent choice (\(draft.homeWorldTalentOptions.joined(separator: " or "))).")
        }

        if let background = draft.backgroundDefinition {
            for (index, options) in draft.backgroundSkillOptionGroups.enumerated() where draft.backgroundSkillChoices[safe: index] == nil {
                messages.append("\(background.displayName): requires starting skill choice \(index + 1) (\(options.joined(separator: " or "))).")
            }

            if draft.backgroundTalentOptions.isEmpty == false, draft.backgroundTalentChoice == nil {
                messages.append("\(background.displayName): requires an explicit background talent choice (\(draft.backgroundTalentOptions.joined(separator: " or "))).")
            }

            for (index, options) in draft.backgroundEquipmentOptionGroups.enumerated() where draft.backgroundEquipmentChoices[safe: index] == nil {
                messages.append("\(background.displayName): requires starting equipment choice \(index + 1) (\(options.joined(separator: " or "))).")
            }
        }

        if draft.roleTalentOptions.isEmpty == false, draft.roleTalentChoice == nil,
           let role = draft.roleDefinition {
            messages.append("\(role.displayName): requires an explicit role talent choice (\(draft.roleTalentOptions.joined(separator: " or "))).")
        }

        return messages
    }

    private static func buildStartingPackage(
        for draft: DHIICreationDraft,
        weaponCatalog: WeaponCompendiumCatalog,
        armourCatalog: ArmourCompendiumCatalog
    ) -> DHIIPackageAccumulator {
        var package = DHIIPackageAccumulator()

        if let background = draft.backgroundDefinition {
            package.skills.append(contentsOf: projectedBackgroundSkills(for: draft, background: background))
            package.notes.talents.append(contentsOf: projectedBackgroundTalents(for: draft, background: background))
            package.notes.traits.append(contentsOf: background.startingTraits)
            package.notes.specialAbilities.append("\(background.backgroundBonus.name): \(background.backgroundBonus.summary)")
            appendBackgroundEquipment(for: draft, into: &package, weaponCatalog: weaponCatalog, armourCatalog: armourCatalog)
        }

        if let role = draft.roleDefinition {
            if let roleTalentChoice = draft.roleTalentChoice {
                package.notes.talents.append(roleTalentChoice)
            }
            package.notes.specialAbilities.append("\(role.roleBonus.name): \(role.roleBonus.summary)")
        }

        if let homeWorld = draft.homeWorldDefinition {
            if let homeWorldTalentChoice = draft.homeWorldTalentChoice {
                package.notes.talents.append(homeWorldTalentChoice)
            }
            if homeWorld.id == .voidborn {
                package.notes.talents.append("Strong Minded")
            }
            package.notes.specialAbilities.append("\(homeWorld.homeWorldBonus.name): \(homeWorld.homeWorldBonus.summary)")
        }

        package.skills = stableUniqueSkills(package.skills)
        package.notes.talents = stableUniqueStrings(package.notes.talents)
        package.notes.traits = stableUniqueStrings(package.notes.traits)
        package.notes.specialAbilities = stableUniqueStrings(package.notes.specialAbilities)
        package.inventory = stableUniqueInventory(package.inventory)
        return package
    }

    private static func projectedBackgroundSkills(
        for draft: DHIICreationDraft,
        background: DHIIBackgroundDefinition
    ) -> [Skill] {
        switch background.id {
        case .adeptusAdministratum:
            return [
                makeSkill(name: draft.backgroundSkillChoices[safe: 0] ?? "Commerce", characteristic: .intelligence),
                makeSkill(name: "Common Lore", characteristic: .intelligence, specialisations: ["Adeptus Administratum"]),
                makeSkill(name: "Linguistics", characteristic: .intelligence, specialisations: ["High Gothic"]),
                makeSkill(name: "Logic", characteristic: .intelligence),
                makeSkill(name: "Scholastic Lore", characteristic: .intelligence, specialisations: ["Pick One"])
            ]
        case .adeptusArbites:
            return [
                makeSkill(name: "Awareness", characteristic: .perception),
                makeSkill(name: "Common Lore", characteristic: .intelligence, specialisations: ["Adeptus Arbites", "Underworld"]),
                makeSkill(name: draft.backgroundSkillChoices[safe: 0] ?? "Inquiry", characteristic: draft.backgroundSkillChoices[safe: 0] == "Interrogation" ? .willpower : .fellowship),
                makeSkill(name: "Intimidate", characteristic: .strength),
                makeSkill(name: "Scrutiny", characteristic: .perception)
            ]
        case .adeptusAstraTelepathica:
            return [
                makeSkill(name: "Awareness", characteristic: .perception),
                makeSkill(name: "Common Lore", characteristic: .intelligence, specialisations: ["Adeptus Astra Telepathica"]),
                makeSkill(name: draft.backgroundSkillChoices[safe: 0] ?? "Deceive", characteristic: draft.backgroundSkillChoices[safe: 0] == "Interrogation" ? .willpower : .fellowship),
                makeSkill(name: "Forbidden Lore", characteristic: .intelligence, specialisations: ["The Warp"]),
                makeSkill(name: draft.backgroundSkillChoices[safe: 1] ?? "Psyniscience", characteristic: draft.backgroundSkillChoices[safe: 1] == "Scrutiny" ? .perception : .perception)
            ]
        case .adeptusMechanicus:
            return [
                makeSkill(name: draft.backgroundSkillChoices[safe: 0] ?? "Awareness", characteristic: draft.backgroundSkillChoices[safe: 0] == "Operate (Pick One)" ? .agility : .perception, specialisations: draft.backgroundSkillChoices[safe: 0] == "Operate (Pick One)" ? ["Pick One"] : []),
                makeSkill(name: "Common Lore", characteristic: .intelligence, specialisations: ["Adeptus Mechanicus"]),
                makeSkill(name: "Logic", characteristic: .intelligence),
                makeSkill(name: "Security", characteristic: .intelligence),
                makeSkill(name: "Tech-Use", characteristic: .intelligence)
            ]
        case .adeptusMinistorum:
            return [
                makeSkill(name: "Charm", characteristic: .fellowship),
                makeSkill(name: "Command", characteristic: .fellowship),
                makeSkill(name: "Common Lore", characteristic: .intelligence, specialisations: ["Adeptus Ministorum"]),
                makeSkill(name: draft.backgroundSkillChoices[safe: 0] ?? "Inquiry", characteristic: draft.backgroundSkillChoices[safe: 0] == "Scrutiny" ? .perception : .fellowship),
                makeSkill(name: "Linguistics", characteristic: .intelligence, specialisations: ["High Gothic"])
            ]
        case .imperialGuard:
            return [
                makeSkill(name: "Athletics", characteristic: .strength),
                makeSkill(name: "Command", characteristic: .fellowship),
                makeSkill(name: "Common Lore", characteristic: .intelligence, specialisations: ["Imperial Guard"]),
                makeSkill(name: draft.backgroundSkillChoices[safe: 0] ?? "Medicae", characteristic: draft.backgroundSkillChoices[safe: 0] == "Operate (Surface)" ? .agility : .intelligence, specialisations: draft.backgroundSkillChoices[safe: 0] == "Operate (Surface)" ? ["Surface"] : []),
                makeSkill(name: "Navigate", characteristic: .intelligence, specialisations: ["Surface"])
            ]
        case .outcast:
            return [
                makeSkill(name: draft.backgroundSkillChoices[safe: 0] ?? "Acrobatics", characteristic: .agility),
                makeSkill(name: "Common Lore", characteristic: .intelligence, specialisations: ["Underworld"]),
                makeSkill(name: "Deceive", characteristic: .fellowship),
                makeSkill(name: "Dodge", characteristic: .agility),
                makeSkill(name: "Stealth", characteristic: .agility)
            ]
        }
    }

    private static func projectedBackgroundTalents(
        for draft: DHIICreationDraft,
        background: DHIIBackgroundDefinition
    ) -> [String] {
        var talents = background.startingTalents
        if background.id == .adeptusMinistorum {
            talents = [draft.backgroundTalentChoice ?? "Weapon Training (Flame)"]
        }
        return talents
    }

    private static func appendBackgroundEquipment(
        for draft: DHIICreationDraft,
        into package: inout DHIIPackageAccumulator,
        weaponCatalog: WeaponCompendiumCatalog,
        armourCatalog: ArmourCompendiumCatalog
    ) {
        guard let backgroundID = draft.backgroundID else {
            return
        }

        switch backgroundID {
        case .adeptusAdministratum:
            appendWeapon(named: draft.backgroundEquipmentChoices[safe: 0] ?? "Laspistol", into: &package, using: weaponCatalog)
            appendInventoryItem(named: "Imperial Robes", into: &package)
            appendInventoryItem(named: "Autoquill", into: &package)
            appendInventoryItem(named: "Chrono", into: &package)
            appendInventoryItem(named: "Dataslate", into: &package)
            appendInventoryItem(named: "Medi-kit", into: &package)
        case .adeptusArbites:
            appendWeapon(named: draft.backgroundEquipmentChoices[safe: 0] ?? "Shotgun", into: &package, using: weaponCatalog)
            appendInventoryItem(named: draft.backgroundEquipmentChoices[safe: 1] ?? "Enforcer Light Carapace Armour", into: &package)
            appendInventoryItem(named: "3 Doses of Stimm", into: &package)
            appendInventoryItem(named: "Manacles", into: &package)
            appendInventoryItem(named: "12 Lho Sticks", into: &package)
        case .adeptusAstraTelepathica:
            appendWeapon(named: "Laspistol", into: &package, using: weaponCatalog)
            appendWeapon(named: draft.backgroundEquipmentChoices[safe: 0] ?? "Staff", into: &package, using: weaponCatalog)
            appendInventoryItem(named: draft.backgroundEquipmentChoices[safe: 1] ?? "Light Flak Cloak", into: &package)
            appendInventoryItem(named: "Micro-bead", into: &package)
        case .adeptusMechanicus:
            appendWeapon(named: draft.backgroundEquipmentChoices[safe: 0] ?? "Autogun", into: &package, using: weaponCatalog)
            appendInventoryItem(named: draft.backgroundEquipmentChoices[safe: 1] ?? "Monotask Servo-Skull (Utility)", into: &package)
            appendInventoryItem(named: "Imperial Robes", into: &package)
            appendInventoryItem(named: "2 Vials of Sacred Unguents", into: &package)
        case .adeptusMinistorum:
            appendEquipmentChoice(named: draft.backgroundEquipmentChoices[safe: 0] ?? "Hand Flamer", into: &package, using: weaponCatalog)
            appendInventoryItem(named: draft.backgroundEquipmentChoices[safe: 1] ?? "Imperial Robes", into: &package)
            appendInventoryItem(named: "Backpack", into: &package)
            appendInventoryItem(named: "Glow-globe", into: &package)
            appendInventoryItem(named: "Monotask Servo-Skull (Laud Hailer)", into: &package)
        case .imperialGuard:
            appendEquipmentChoice(named: draft.backgroundEquipmentChoices[safe: 0] ?? "Lasgun", into: &package, using: weaponCatalog)
            appendInventoryItem(named: "Combat Vest", into: &package)
            appendInventoryItem(named: "Imperial Guard Flak Armour", into: &package)
            appendInventoryItem(named: "Grapnel and Line", into: &package)
            appendInventoryItem(named: "12 Lho Sticks", into: &package)
            appendInventoryItem(named: "Magnoculars", into: &package)
        case .outcast:
            appendWeapon(named: draft.backgroundEquipmentChoices[safe: 0] ?? "Autopistol", into: &package, using: weaponCatalog)
            appendWeapon(named: "Chainsword", into: &package, using: weaponCatalog)
            appendInventoryItem(named: draft.backgroundEquipmentChoices[safe: 1] ?? "Armoured Bodyglove", into: &package)
            appendInventoryItem(named: "Injector", into: &package)
            appendInventoryItem(named: "2 Doses of \(draft.backgroundEquipmentChoices[safe: 2] ?? "Obscura")", into: &package)
        }

        _ = armourCatalog
    }
}

private struct DHIIPackageAccumulator {
    var skills: [Skill] = []
    var notes: NotesState = .init()
    var weapons: [Weapon] = []
    var armour: [Armour] = []
    var inventory: [InventoryItem] = []
}

private func makeSkill(name: String, characteristic: SkillCharacteristic, specialisations: [String] = []) -> Skill {
    Skill(name: name, characteristic: characteristic, training: .known, specialisations: specialisations)
}

private func appendWeapon(
    named name: String,
    into package: inout DHIIPackageAccumulator,
    using catalog: WeaponCompendiumCatalog
) {
    let weapon = projectedWeapon(named: name, using: catalog)
    package.weapons.append(weapon)
    if let ammo = standardAmmoItem(for: weapon) {
        package.inventory.append(ammo)
    }
}

private func appendEquipmentChoice(
    named name: String,
    into package: inout DHIIPackageAccumulator,
    using catalog: WeaponCompendiumCatalog
) {
    switch normalizedProjectionToken(name) {
    case "warhammer-and-stub-revolver":
        appendWeapon(named: "Warhammer", into: &package, using: catalog)
        appendWeapon(named: "Stub Revolver", into: &package, using: catalog)
    case "laspistol-and-sword":
        appendWeapon(named: "Laspistol", into: &package, using: catalog)
        appendWeapon(named: "Sword", into: &package, using: catalog)
    default:
        appendWeapon(named: name, into: &package, using: catalog)
    }
}

private func appendInventoryItem(named name: String, into package: inout DHIIPackageAccumulator) {
    package.inventory.append(InventoryItem(name: name))
}

private func projectedWeapon(named name: String, using catalog: WeaponCompendiumCatalog) -> Weapon {
    let normalized = normalizedProjectionToken(name)
    if let definition = catalog.definitions.first(where: { normalizedProjectionToken($0.name) == normalized }) {
        return definition.makeWeaponInstance()
    }

    switch normalized {
    case "shotgun":
        return Weapon(name: "Shotgun", type: "Basic", range: "30m")
    case "shock-maul":
        return Weapon(name: "Shock Maul", type: "Melee", range: "Melee")
    case "staff":
        return Weapon(name: "Staff", type: "Melee", range: "Melee")
    case "whip":
        return Weapon(name: "Whip", type: "Melee", range: "Melee")
    case "hand-cannon":
        return Weapon(name: "Hand Cannon", type: "Pistol", range: "30m")
    case "hand-flamer":
        return Weapon(name: "Hand Flamer", type: "Pistol", range: "10m")
    case "warhammer":
        return Weapon(name: "Warhammer", type: "Melee", range: "Melee")
    case "stub-automatic":
        return Weapon(name: "Stub Automatic", type: "Pistol", range: "30m")
    case "stub-revolver":
        return Weapon(name: "Stub Revolver", type: "Pistol", range: "30m")
    case "sword":
        return Weapon(name: "Sword", type: "Melee", range: "Melee")
    default:
        return Weapon(name: name)
    }
}

private func standardAmmoItem(for weapon: Weapon) -> InventoryItem? {
    guard let metadata = WeaponTypeRegistry.resolve(weapon.type),
          metadata.classification != .melee else {
        return nil
    }
    return InventoryItem(name: "Standard Ammunition for \(weapon.name)", quantity: 2)
}

private func movementProfile(for characteristics: CharacteristicSet) -> MovementProfile {
    let agilityBonus = max(0, characteristics.bonus.agility)
    return MovementProfile(
        halfMove: agilityBonus,
        fullMove: agilityBonus * 2,
        charge: agilityBonus * 3,
        run: agilityBonus * 6
    )
}

private func normalizedProjectionToken(_ value: String) -> String {
    let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    return trimmed
        .map { $0.isLetter || $0.isNumber ? String($0) : "-" }
        .joined()
        .split(separator: "-", omittingEmptySubsequences: true)
        .joined(separator: "-")
}

private func stableUniqueStrings(_ values: [String]) -> [String] {
    var resolved: [String] = []
    var seen: Set<String> = []
    for value in values {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else {
            continue
        }
        let token = normalizedProjectionToken(trimmed)
        if seen.insert(token).inserted {
            resolved.append(trimmed)
        }
    }
    return resolved
}

private func stableUniqueTargets(_ values: [DHIICreationEffectTarget]) -> [DHIICreationEffectTarget] {
    var resolved: [DHIICreationEffectTarget] = []
    var seen: Set<String> = []
    for value in values {
        let token = switch value {
        case .characteristic(let characteristic):
            "characteristic.\(characteristic.rawValue)"
        case .influence:
            "influence"
        }
        if seen.insert(token).inserted {
            resolved.append(value)
        }
    }
    return resolved
}

private func stableUniqueSkills(_ skills: [Skill]) -> [Skill] {
    var resolved: [Skill] = []
    var seen: Set<String> = []
    for skill in skills {
        let token = [
            normalizedProjectionToken(skill.name),
            skill.characteristic.rawValue,
            skill.specialisations.map(normalizedProjectionToken).joined(separator: "|")
        ].joined(separator: "::")
        if seen.insert(token).inserted {
            resolved.append(skill)
        }
    }
    return resolved
}

private func stableUniqueInventory(_ items: [InventoryItem]) -> [InventoryItem] {
    var resolved: [InventoryItem] = []
    var seen: Set<String> = []
    for item in items {
        let token = normalizedProjectionToken(item.name)
        if seen.insert(token).inserted {
            resolved.append(item)
        }
    }
    return resolved
}

func validatedIndexedChoices(_ choices: [String], optionGroups: [[String]]) -> [String] {
    optionGroups.enumerated().compactMap { index, options in
        guard let choice = choices[safe: index] else {
            return nil
        }
        return validatedChoice(choice, options: options)
    }
}

func replacingIndexedChoice(
    _ choices: [String],
    with newChoice: String?,
    at index: Int,
    optionGroups: [[String]]
) -> [String] {
    guard optionGroups.indices.contains(index) else {
        return validatedIndexedChoices(choices, optionGroups: optionGroups)
    }

    var next = validatedIndexedChoices(choices, optionGroups: optionGroups)
    while next.count < optionGroups.count {
        next.append("")
    }
    next[index] = validatedChoice(newChoice, options: optionGroups[index]) ?? ""
    return next.enumerated().compactMap { _, value in
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

func validatedStartingRoll(_ roll: Int?, allowedRange: ClosedRange<Int>) -> Int? {
    guard let roll, allowedRange.contains(roll) else {
        return nil
    }
    return roll
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
