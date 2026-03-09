import Foundation

struct CharacterDossier: Equatable, Sendable {
    struct Section: Identifiable, Equatable, Sendable {
        let title: String
        let subtitle: String?
        let items: [Item]

        var id: String { title }
    }

    enum Item: Equatable, Sendable {
        case field(label: String, value: String)
        case paragraph(String)
        case bullet(String)
    }

    let title: String
    let subtitle: String
    let metadataLine: String
    let filenameStem: String
    let sections: [Section]
}

enum CharacterDossierComposer {
    static func compose(for character: Character) -> CharacterDossier {
        let displayName = normalizedText(character.profile.name, fallback: "Unnamed Character")
        let subtitleParts = [
            trimmedText(character.profile.homeWorld),
            trimmedText(character.profile.background),
            trimmedText(character.profile.role)
        ].filter { !$0.isEmpty }

        var sections: [CharacterDossier.Section] = [
            identitySection(for: character),
            characteristicsSection(for: character.characteristics),
            resourcesSection(for: character.resources),
            sessionSection(for: character)
        ]

        if let skillsSection = skillsSection(for: character) {
            sections.insert(skillsSection, at: 3)
        }

        if let notesSection = notesSection(for: character.notes) {
            sections.append(notesSection)
        }

        if let equipmentSection = equipmentSection(for: character.equipment) {
            sections.append(equipmentSection)
        }

        if let historySection = historySection(for: character.history) {
            sections.append(historySection)
        }

        return CharacterDossier(
            title: displayName,
            subtitle: subtitleParts.isEmpty ? "Dark Heresy II Character Dossier" : subtitleParts.joined(separator: " · "),
            metadataLine: "Updated \(character.updatedAt.formatted(date: .abbreviated, time: .shortened))",
            filenameStem: filenameStem(for: displayName, id: character.id),
            sections: sections
        )
    }

    private static func identitySection(for character: Character) -> CharacterDossier.Section {
        var items: [CharacterDossier.Item] = [
            .field(label: "Name", value: normalizedText(character.profile.name, fallback: "Unnamed Character")),
            .field(label: "Home World", value: normalizedText(character.profile.homeWorld)),
            .field(label: "Background", value: normalizedText(character.profile.background)),
            .field(label: "Role", value: normalizedText(character.profile.role))
        ]

        let aptitudes = character.profile.aptitudes
            .map(trimmedText)
            .filter { !$0.isEmpty }
        if !aptitudes.isEmpty {
            items.append(.field(label: "Aptitudes", value: aptitudes.joined(separator: ", ")))
        }

        let description = trimmedText(character.profile.description)
        if !description.isEmpty {
            items.append(.paragraph(description))
        }

        return CharacterDossier.Section(
            title: "Identity",
            subtitle: "Profile and dossier summary",
            items: items
        )
    }

    private static func characteristicsSection(for characteristics: CharacteristicSet) -> CharacterDossier.Section {
        let items: [CharacterDossier.Item] = [
            .field(label: "Weapon Skill", value: characteristicValueLabel(characteristics.weaponSkill, bonus: characteristics.bonus.weaponSkill)),
            .field(label: "Ballistic Skill", value: characteristicValueLabel(characteristics.ballisticSkill, bonus: characteristics.bonus.ballisticSkill)),
            .field(label: "Strength", value: characteristicValueLabel(characteristics.strength, bonus: characteristics.bonus.strength)),
            .field(label: "Toughness", value: characteristicValueLabel(characteristics.toughness, bonus: characteristics.bonus.toughness)),
            .field(label: "Agility", value: characteristicValueLabel(characteristics.agility, bonus: characteristics.bonus.agility)),
            .field(label: "Intelligence", value: characteristicValueLabel(characteristics.intelligence, bonus: characteristics.bonus.intelligence)),
            .field(label: "Perception", value: characteristicValueLabel(characteristics.perception, bonus: characteristics.bonus.perception)),
            .field(label: "Willpower", value: characteristicValueLabel(characteristics.willpower, bonus: characteristics.bonus.willpower)),
            .field(label: "Fellowship", value: characteristicValueLabel(characteristics.fellowship, bonus: characteristics.bonus.fellowship))
        ]

        return CharacterDossier.Section(
            title: "Characteristics",
            subtitle: "Core thresholds and bonuses",
            items: items
        )
    }

    private static func resourcesSection(for resources: ResourceState) -> CharacterDossier.Section {
        CharacterDossier.Section(
            title: "Resources",
            subtitle: "Condition, fate, and experience",
            items: [
                .field(label: "Wounds", value: "\(resources.currentWounds) / \(resources.maxWounds)"),
                .field(label: "Fatigue", value: "\(resources.fatigue)"),
                .field(label: "Corruption", value: "\(resources.corruption)"),
                .field(label: "Insanity", value: "\(resources.insanity)"),
                .field(label: "Fate", value: "\(resources.currentFate) / \(resources.maxFate)"),
                .field(
                    label: "Experience",
                    value: "\(resources.experienceSpent) spent / \(resources.experienceTotal) total / \(resources.experienceAvailable) available"
                )
            ]
        )
    }

    private static func skillsSection(for character: Character) -> CharacterDossier.Section? {
        let sortedSkills = character.skills.sorted {
            if $0.displayName == $1.displayName {
                return $0.id.uuidString < $1.id.uuidString
            }
            return $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
        }

        guard !sortedSkills.isEmpty else { return nil }

        let items = sortedSkills.map { skill in
            let target = DerivedValueCalculator.skillTarget(for: skill, characteristics: character.characteristics)
            var details = [
                skill.characteristic.label,
                "\(skill.training.label) (\(skill.training.modifier.signedValueLabel))",
                "Target \(target)"
            ]

            let specialisations = skill.specialisations
                .map(trimmedText)
                .filter { !$0.isEmpty }
            if !specialisations.isEmpty {
                details.append("Specialisations: \(specialisations.joined(separator: ", "))")
            }

            return CharacterDossier.Item.field(label: skill.displayName, value: details.joined(separator: " · "))
        }

        return CharacterDossier.Section(
            title: "Skills",
            subtitle: "Operational competencies (\(sortedSkills.count))",
            items: items
        )
    }

    private static func notesSection(for notes: NotesState) -> CharacterDossier.Section? {
        var items: [CharacterDossier.Item] = []

        appendJoinedField(label: "Talents", values: notes.talents, to: &items)
        appendJoinedField(label: "Traits", values: notes.traits, to: &items)
        appendJoinedField(label: "Mutations", values: notes.mutations, to: &items)
        appendJoinedField(label: "Disorders", values: notes.disorders, to: &items)
        appendJoinedField(label: "Psychic Powers", values: notes.psychicPowers, to: &items)
        appendJoinedField(label: "Special Abilities", values: notes.specialAbilities, to: &items)

        let freeformNotes = trimmedText(notes.notes)
        if !freeformNotes.isEmpty {
            items.append(.paragraph(freeformNotes))
        }

        guard !items.isEmpty else { return nil }

        return CharacterDossier.Section(
            title: "Notes and Abilities",
            subtitle: "Traits, powers, and narrative context",
            items: items
        )
    }

    private static func equipmentSection(for equipment: EquipmentState) -> CharacterDossier.Section? {
        var items: [CharacterDossier.Item] = []

        if equipment.movement.halfMove != 0 || equipment.movement.fullMove != 0 || equipment.movement.charge != 0 || equipment.movement.run != 0 {
            items.append(
                .field(
                    label: "Movement",
                    value: "Half \(equipment.movement.halfMove) · Full \(equipment.movement.fullMove) · Charge \(equipment.movement.charge) · Run \(equipment.movement.run)"
                )
            )
        }

        for weapon in equipment.weapons {
            let details = compactJoined(
                [
                    trimmedText(weapon.type),
                    prefixed("Range", value: weapon.range),
                    prefixed("Damage", value: weapon.damage),
                    prefixed("Pen", value: weapon.penetration),
                    prefixed("Clip", value: weapon.clip),
                    prefixed("Reload", value: weapon.reload),
                    prefixed("Traits", value: weapon.traits)
                ]
            )
            items.append(.field(label: normalizedText(weapon.name, fallback: "Unnamed Weapon"), value: details))
        }

        for armour in equipment.armour {
            items.append(.field(label: normalizedText(armour.location, fallback: "Armour"), value: "AP \(armour.armourPoints)"))
        }

        for item in equipment.inventory {
            var details = ["Qty \(item.quantity)"]
            if item.weight > 0 {
                details.append("Weight \(weightLabel(item.weight)) kg")
            }
            items.append(.field(label: normalizedText(item.name, fallback: "Inventory Item"), value: details.joined(separator: " · ")))
        }

        guard !items.isEmpty else { return nil }

        return CharacterDossier.Section(
            title: "Equipment",
            subtitle: "Loadout, armour, and carried items",
            items: items
        )
    }

    private static func sessionSection(for character: Character) -> CharacterDossier.Section {
        let activeWeaponName: String
        if let activeWeaponID = character.session.activeWeaponID,
           let activeWeapon = character.equipment.weapons.first(where: { $0.id == activeWeaponID }) {
            activeWeaponName = normalizedText(activeWeapon.name, fallback: "Unnamed Weapon")
        } else {
            activeWeaponName = "None"
        }

        var items: [CharacterDossier.Item] = [
            .field(label: "Mode", value: character.session.modeEnabled ? "Active" : "Standby"),
            .field(
                label: "Live Condition",
                value: "Wounds \(character.resources.currentWounds)/\(character.resources.maxWounds) · Fatigue \(character.resources.fatigue) · Fate \(character.resources.currentFate)/\(character.resources.maxFate)"
            ),
            .field(label: "Active Weapon", value: activeWeaponName)
        ]

        if !character.session.pinnedChecks.isEmpty {
            items.append(.field(label: "Pinned Checks", value: compactJoined(character.session.pinnedChecks.map(trimmedText))))
        }

        if !character.session.temporaryModifiers.isEmpty {
            let modifiers = character.session.temporaryModifiers
                .map { key, value in "\(trimmedText(key)): \(value.signedValueLabel)" }
                .sorted()
            items.append(.field(label: "Temporary Modifiers", value: modifiers.joined(separator: " · ")))
        }

        if !character.session.combatConditions.isEmpty {
            let conditions = character.session.combatConditions
                .map(trimmedText)
                .filter { !$0.isEmpty }
            if !conditions.isEmpty {
                items.append(.field(label: "Combat Conditions", value: conditions.joined(separator: " · ")))
            }
        }

        return CharacterDossier.Section(
            title: "Session Snapshot",
            subtitle: "Combat and live-play reference",
            items: items
        )
    }

    private static func historySection(for history: [CharacterHistoryEntry]) -> CharacterDossier.Section? {
        let recentEntries = history
            .sorted { $0.createdAt > $1.createdAt }
            .prefix(3)
            .map { entry in
                let title = normalizedText(entry.title, fallback: "Untitled Entry")
                return CharacterDossier.Item.bullet(
                    "\(entry.createdAt.formatted(date: .abbreviated, time: .shortened)) · \(historyTypeLabel(entry.type)) · \(title)"
                )
            }

        guard !recentEntries.isEmpty else { return nil }

        return CharacterDossier.Section(
            title: "Recent History",
            subtitle: "Latest campaign notes",
            items: Array(recentEntries)
        )
    }

    private static func characteristicValueLabel(_ value: Int, bonus: Int) -> String {
        "\(value) (Bonus \(bonus))"
    }

    private static func appendJoinedField(label: String, values: [String], to items: inout [CharacterDossier.Item]) {
        let cleanedValues = values
            .map(trimmedText)
            .filter { !$0.isEmpty }
        guard !cleanedValues.isEmpty else { return }
        items.append(.field(label: label, value: cleanedValues.joined(separator: ", ")))
    }

    private static func compactJoined(_ values: [String]) -> String {
        let cleaned = values
            .map(trimmedText)
            .filter { !$0.isEmpty }
        return cleaned.isEmpty ? "—" : cleaned.joined(separator: " · ")
    }

    private static func prefixed(_ prefix: String, value: String) -> String {
        let cleaned = trimmedText(value)
        return cleaned.isEmpty ? "" : "\(prefix) \(cleaned)"
    }

    private static func historyTypeLabel(_ type: CharacterHistoryEntryType) -> String {
        switch type {
        case .sessionNote:
            return "Session Note"
        case .advancement:
            return "Advancement"
        case .injury:
            return "Injury"
        case .corruptionOrInsanity:
            return "Corruption / Insanity"
        case .equipmentChange:
            return "Equipment Change"
        case .storyNote:
            return "Story Note"
        case .custom:
            return "Custom"
        }
    }

    private static func filenameStem(for name: String, id: UUID) -> String {
        let slugComponents = name
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
        let slug = slugComponents.isEmpty ? "character" : slugComponents.joined(separator: "-")
        let identifier = String(id.uuidString.prefix(8)).lowercased()
        return "dh-dossier-\(slug)-\(identifier)"
    }

    private static func normalizedText(_ text: String, fallback: String = "—") -> String {
        let trimmed = trimmedText(text)
        return trimmed.isEmpty ? fallback : trimmed
    }

    private static func trimmedText(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func weightLabel(_ value: Double) -> String {
        if value.rounded() == value {
            return String(Int(value))
        }
        return String(format: "%.1f", value)
    }
}
