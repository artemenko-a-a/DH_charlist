import Foundation
import Testing
@testable import DHCharList

@Test func characterDossierComposerBuildsStructuredReadableSummary() {
    let weaponID = UUID()
    let updatedAt = Date(timeIntervalSince1970: 1_700_000_000)
    let character = Character(
        id: UUID(uuidString: "12345678-1234-5678-1234-567812345678")!,
        profile: Profile(
            name: "Adept Voss",
            homeWorld: "Hive World",
            background: "Adeptus Administratum",
            role: "Seeker",
            aptitudes: ["Intelligence", "Perception"],
            description: "Trusted field analyst attached to the cell."
        ),
        characteristics: CharacteristicSet(
            weaponSkill: 31,
            ballisticSkill: 34,
            strength: 29,
            toughness: 30,
            agility: 33,
            intelligence: 45,
            perception: 36,
            willpower: 38,
            fellowship: 27
        ),
        resources: ResourceState(
            currentWounds: 9,
            maxWounds: 12,
            fatigue: 1,
            corruption: 2,
            insanity: 4,
            currentFate: 2,
            maxFate: 3,
            experienceSpent: 500,
            experienceTotal: 700
        ),
        skills: [
            Skill(
                name: "Awareness",
                characteristic: .perception,
                training: .trained,
                specialisations: ["Audio", "Sight"]
            )
        ],
        notes: NotesState(
            talents: ["Rapid Reload"],
            traits: ["Heightened Senses"],
            psychicPowers: ["Precognition"],
            specialAbilities: ["Peer (Administratum)"],
            notes: "Carries a slate of sealed orders."
        ),
        equipment: EquipmentState(
            weapons: [
                Weapon(
                    id: weaponID,
                    name: "Bolt Pistol",
                    type: "Pistol",
                    range: "30m",
                    damage: "1d10+5 X",
                    penetration: "4",
                    clip: "8",
                    reload: "Full",
                    traits: "Tearing"
                )
            ],
            armour: [Armour(location: "Body", armourPoints: 4)],
            movement: MovementProfile(halfMove: 3, fullMove: 6, charge: 9, run: 18),
            inventory: [InventoryItem(name: "Dataslate", quantity: 1, weight: 1.5)]
        ),
        session: SessionState(
            modeEnabled: true,
            pinnedChecks: ["Awareness", "Inquiry"],
            temporaryModifiers: ["Darkness": -20, "Aim": 10],
            activeWeaponID: weaponID,
            combatConditions: ["Pinned behind cover"]
        ),
        history: [
            CharacterHistoryEntry(characterID: UUID(), createdAt: Date(timeIntervalSince1970: 1_700_000_100), title: "Promoted", type: .advancement),
            CharacterHistoryEntry(characterID: UUID(), createdAt: Date(timeIntervalSince1970: 1_700_000_200), title: "Stub round graze", type: .injury),
            CharacterHistoryEntry(characterID: UUID(), createdAt: Date(timeIntervalSince1970: 1_700_000_300), title: "Debrief note", type: .sessionNote),
            CharacterHistoryEntry(characterID: UUID(), createdAt: Date(timeIntervalSince1970: 1_700_000_400), title: "Archive transfer", type: .storyNote)
        ],
        updatedAt: updatedAt
    )

    let dossier = CharacterDossierComposer.compose(for: character)

    #expect(dossier.title == "Adept Voss")
    #expect(dossier.subtitle.contains("Hive World"))
    #expect(dossier.filenameStem == "dh-dossier-adept-voss-12345678")

    let identity = section(named: "Identity", in: dossier)
    #expect(fieldValue("Aptitudes", in: identity) == "Intelligence, Perception")
    #expect(paragraphTexts(in: identity).contains("Trusted field analyst attached to the cell."))

    let skills = section(named: "Skills", in: dossier)
    #expect(fieldValue("Awareness", in: skills)?.contains("Target 46") == true)
    #expect(fieldValue("Awareness", in: skills)?.contains("Specialisations: Audio, Sight") == true)

    let session = section(named: "Session Snapshot", in: dossier)
    #expect(fieldValue("Mode", in: session) == "Active")
    #expect(fieldValue("Active Weapon", in: session) == "Bolt Pistol")
    #expect(fieldValue("Temporary Modifiers", in: session)?.contains("Aim: +10") == true)
    #expect(fieldValue("Temporary Modifiers", in: session)?.contains("Darkness: -20") == true)

    let history = section(named: "Recent History", in: dossier)
    #expect(bulletTexts(in: history).count == 3)
    #expect(bulletTexts(in: history).first?.contains("Story Note") == true)
}

@Test func characterDossierComposerOmitsEmptyOptionalSectionsForSparseCharacter() {
    let character = Character(profile: Profile(name: "Sparse Operative"))

    let dossier = CharacterDossierComposer.compose(for: character)

    #expect(section(named: "Identity", in: dossier) != nil)
    #expect(section(named: "Characteristics", in: dossier) != nil)
    #expect(section(named: "Resources", in: dossier) != nil)
    #expect(section(named: "Session Snapshot", in: dossier) != nil)
    #expect(section(named: "Skills", in: dossier) == nil)
    #expect(section(named: "Notes and Abilities", in: dossier) == nil)
    #expect(section(named: "Equipment", in: dossier) == nil)
    #expect(section(named: "Recent History", in: dossier) == nil)
}

@Test func characterDossierFilenameStemSanitizesCharacterName() {
    let character = Character(
        id: UUID(uuidString: "87654321-4321-8765-4321-876543218765")!,
        profile: Profile(name: "Interrogator-Prime / Ordo Xenos")
    )

    let dossier = CharacterDossierComposer.compose(for: character)

    #expect(dossier.filenameStem == "dh-dossier-interrogator-prime-ordo-xenos-87654321")
}

private func section(named title: String, in dossier: CharacterDossier) -> CharacterDossier.Section? {
    dossier.sections.first(where: { $0.title == title })
}

private func fieldValue(_ label: String, in section: CharacterDossier.Section?) -> String? {
    guard let section else { return nil }

    for item in section.items {
        if case let .field(itemLabel, value) = item, itemLabel == label {
            return value
        }
    }

    return nil
}

private func paragraphTexts(in section: CharacterDossier.Section?) -> [String] {
    guard let section else { return [] }

    return section.items.compactMap { item in
        if case let .paragraph(text) = item {
            return text
        }
        return nil
    }
}

private func bulletTexts(in section: CharacterDossier.Section?) -> [String] {
    guard let section else { return [] }

    return section.items.compactMap { item in
        if case let .bullet(text) = item {
            return text
        }
        return nil
    }
}
