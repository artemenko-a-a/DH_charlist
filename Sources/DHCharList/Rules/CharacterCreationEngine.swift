import Foundation

enum DHIICreationEffectTarget: Equatable, Sendable {
    case characteristic(SkillCharacteristic)
    case influence

    var displayName: String {
        switch self {
        case .characteristic(let characteristic):
            characteristic.label
        case .influence:
            "Influence"
        }
    }
}

struct DHIICharacteristicModifierRule: Equatable, Sendable {
    let target: DHIICreationEffectTarget
    let delta: Int

    var summary: String {
        "\(delta >= 0 ? "+" : "-")\(target.displayName)"
    }
}

struct DHIIFateThresholdRule: Equatable, Sendable {
    let baseThreshold: Int
    let emperorsBlessingTarget: Int

    var summary: String {
        "\(baseThreshold) (Emperor's Blessing \(emperorsBlessingTarget)+)"
    }
}

struct DHIIWoundsRule: Equatable, Sendable {
    let base: Int
    let diceCount: Int
    let diceSides: Int

    var minimum: Int { base + diceCount }
    var maximum: Int { base + (diceCount * diceSides) }
    var summary: String { "\(base)+\(diceCount)d\(diceSides)" }
}

struct DHIIHomeWorldBonusRule: Equatable, Sendable {
    let name: String
    let summary: String
}

enum DHIIHomeWorldID: String, CaseIterable, Codable, Sendable {
    case feralWorld
    case forgeWorld
    case highborn
    case hiveWorld
    case shrineWorld
    case voidborn

    var displayName: String {
        switch self {
        case .feralWorld: "Feral World"
        case .forgeWorld: "Forge World"
        case .highborn: "Highborn"
        case .hiveWorld: "Hive World"
        case .shrineWorld: "Shrine World"
        case .voidborn: "Voidborn"
        }
    }
}

struct DHIIHomeWorldDefinition: Identifiable, Equatable, Sendable {
    let id: DHIIHomeWorldID
    let aliases: [String]
    let characteristicModifiers: [DHIICharacteristicModifierRule]
    let fateThreshold: DHIIFateThresholdRule
    let homeWorldBonus: DHIIHomeWorldBonusRule
    let aptitude: String
    let wounds: DHIIWoundsRule
    let recommendedBackgrounds: [String]
    let sourceCitation: String

    var displayName: String { id.displayName }

    var characteristicModifierSummary: String {
        characteristicModifiers.map(\.summary).joined(separator: ", ")
    }

    var recommendedBackgroundSummary: String {
        recommendedBackgrounds.joined(separator: ", ")
    }
}

struct DHIICharacterModelCompatibilityReport: Equatable, Sendable {
    let unsupportedTargets: [DHIICreationEffectTarget]
    let unsupportedRuleKeys: [String]
    let warningMessages: [String]
    let contextualMessages: [String]

    var isFullySupported: Bool {
        unsupportedTargets.isEmpty && unsupportedRuleKeys.isEmpty
    }

    init(
        unsupportedTargets: [DHIICreationEffectTarget] = [],
        unsupportedRuleKeys: [String] = [],
        warningMessages: [String] = [],
        contextualMessages: [String] = []
    ) {
        self.unsupportedTargets = unsupportedTargets
        self.unsupportedRuleKeys = unsupportedRuleKeys
        self.warningMessages = warningMessages
        self.contextualMessages = contextualMessages
    }
}

struct DHIIHomeWorldPreview: Equatable, Sendable {
    let definition: DHIIHomeWorldDefinition
    let compatibility: DHIICharacterModelCompatibilityReport
}

struct DHIIBackgroundBonusRule: Equatable, Sendable {
    let name: String
    let summary: String
}

enum DHIIBackgroundID: String, CaseIterable, Codable, Sendable {
    case adeptusAdministratum
    case adeptusArbites
    case adeptusAstraTelepathica
    case adeptusMechanicus
    case adeptusMinistorum
    case imperialGuard
    case outcast

    var displayName: String {
        switch self {
        case .adeptusAdministratum: "Adeptus Administratum"
        case .adeptusArbites: "Adeptus Arbites"
        case .adeptusAstraTelepathica: "Adeptus Astra Telepathica"
        case .adeptusMechanicus: "Adeptus Mechanicus"
        case .adeptusMinistorum: "Adeptus Ministorum"
        case .imperialGuard: "Imperial Guard"
        case .outcast: "Outcast"
        }
    }
}

struct DHIIBackgroundDefinition: Identifiable, Equatable, Sendable {
    let id: DHIIBackgroundID
    let aliases: [String]
    let aptitudeOptions: [String]
    let startingSkills: [String]
    let startingTalents: [String]
    let startingTraits: [String]
    let startingEquipment: [String]
    let backgroundBonus: DHIIBackgroundBonusRule
    let recommendedRoles: [String]
    let unsupportedProjectionRuleKeys: [String]
    let sourceCitation: String

    var displayName: String { id.displayName }
    var aptitudeSummary: String { aptitudeOptions.joined(separator: " or ") }
    var startingSkillSummary: String { startingSkills.joined(separator: ", ") }
    var startingTalentSummary: String { startingTalents.joined(separator: ", ") }
    var startingTraitSummary: String { startingTraits.isEmpty ? "None" : startingTraits.joined(separator: ", ") }
    var startingEquipmentSummary: String { startingEquipment.joined(separator: ", ") }
    var recommendedRoleSummary: String { recommendedRoles.joined(separator: ", ") }
}

struct DHIIBackgroundPreview: Equatable, Sendable {
    let definition: DHIIBackgroundDefinition
    let compatibility: DHIICharacterModelCompatibilityReport
}

struct DHIIRoleBonusRule: Equatable, Sendable {
    let name: String
    let summary: String
}

enum DHIIRoleID: String, CaseIterable, Codable, Sendable {
    case assassin
    case chirurgeon
    case desperado
    case hierophant
    case mystic
    case sage
    case seeker
    case warrior

    var displayName: String {
        switch self {
        case .assassin: "Assassin"
        case .chirurgeon: "Chirurgeon"
        case .desperado: "Desperado"
        case .hierophant: "Hierophant"
        case .mystic: "Mystic"
        case .sage: "Sage"
        case .seeker: "Seeker"
        case .warrior: "Warrior"
        }
    }
}

enum DHIIRoleAptitudeRule: Equatable, Sendable {
    case fixed(String)
    case choice(String, String)

    var summary: String {
        switch self {
        case .fixed(let aptitude):
            aptitude
        case .choice(let first, let second):
            "\(first) or \(second)"
        }
    }
}

struct DHIIRoleDefinition: Identifiable, Equatable, Sendable {
    let id: DHIIRoleID
    let aliases: [String]
    let aptitudeRules: [DHIIRoleAptitudeRule]
    let roleTalentChoices: [String]
    let roleBonus: DHIIRoleBonusRule
    let unsupportedProjectionRuleKeys: [String]
    let sourceCitation: String

    var displayName: String { id.displayName }
    var aptitudeSummary: String { aptitudeRules.map(\.summary).joined(separator: ", ") }
    var roleTalentChoiceSummary: String { roleTalentChoices.joined(separator: " or ") }
}

struct DHIIRolePreview: Equatable, Sendable {
    let definition: DHIIRoleDefinition
    let compatibility: DHIICharacterModelCompatibilityReport
}

struct DHIIAptitudeComposition: Equatable, Sendable {
    let resolvedAptitudes: [String]
    let effectiveAptitudes: [String]
    let legacyFallbackAptitudes: [String]
    let unresolvedChoices: [String]
    let compatibility: DHIICharacterModelCompatibilityReport

    var isFullyResolved: Bool { unresolvedChoices.isEmpty }
}

struct DHIICreationDraft: Equatable, Sendable {
    let homeWorldID: DHIIHomeWorldID?
    let backgroundID: DHIIBackgroundID?
    let roleID: DHIIRoleID?
    let backgroundAptitudeChoice: String?
    let roleAptitudeChoice: String?
    let legacyFallbackAptitudes: [String]
    let unrecognizedHomeWorldInput: String?
    let unrecognizedBackgroundInput: String?
    let unrecognizedRoleInput: String?
    let characteristicGenerationState: DHIICharacteristicGenerationState?

    var homeWorldDefinition: DHIIHomeWorldDefinition? {
        homeWorldID.flatMap { id in
            DHIICharacterCreationEngine.canonicalHomeWorlds.first { $0.id == id }
        }
    }

    var backgroundDefinition: DHIIBackgroundDefinition? {
        backgroundID.flatMap { id in
            DHIICharacterCreationEngine.canonicalBackgrounds.first { $0.id == id }
        }
    }

    var roleDefinition: DHIIRoleDefinition? {
        roleID.flatMap { id in
            DHIICharacterCreationEngine.canonicalRoles.first { $0.id == id }
        }
    }

    var aptitudeComposition: DHIIAptitudeComposition {
        DHIICharacterCreationEngine.composeAptitudes(for: self)
    }

    var characteristicGeneration: DHIICharacteristicGenerationPreview? {
        DHIICharacterCreationEngine.previewCharacteristicGeneration(for: self)
    }

    func settingHomeWorld(_ id: DHIIHomeWorldID?) -> DHIICreationDraft {
        DHIICreationDraft(
            homeWorldID: id,
            backgroundID: backgroundID,
            roleID: roleID,
            backgroundAptitudeChoice: backgroundAptitudeChoice,
            roleAptitudeChoice: roleAptitudeChoice,
            legacyFallbackAptitudes: legacyFallbackAptitudes,
            unrecognizedHomeWorldInput: nil,
            unrecognizedBackgroundInput: unrecognizedBackgroundInput,
            unrecognizedRoleInput: unrecognizedRoleInput,
            characteristicGenerationState: characteristicGenerationState
        )
    }

    func settingBackground(_ id: DHIIBackgroundID?) -> DHIICreationDraft {
        let validOptions = id.flatMap { backgroundID in
            DHIICharacterCreationEngine.canonicalBackgrounds.first { $0.id == backgroundID }?.aptitudeOptions
        } ?? []

        return DHIICreationDraft(
            homeWorldID: homeWorldID,
            backgroundID: id,
            roleID: roleID,
            backgroundAptitudeChoice: validatedChoice(backgroundAptitudeChoice, options: validOptions),
            roleAptitudeChoice: roleAptitudeChoice,
            legacyFallbackAptitudes: legacyFallbackAptitudes,
            unrecognizedHomeWorldInput: unrecognizedHomeWorldInput,
            unrecognizedBackgroundInput: nil,
            unrecognizedRoleInput: unrecognizedRoleInput,
            characteristicGenerationState: characteristicGenerationState
        )
    }

    func settingBackgroundAptitudeChoice(_ choice: String?) -> DHIICreationDraft {
        let validOptions = backgroundDefinition?.aptitudeOptions ?? []

        return DHIICreationDraft(
            homeWorldID: homeWorldID,
            backgroundID: backgroundID,
            roleID: roleID,
            backgroundAptitudeChoice: validatedChoice(choice, options: validOptions),
            roleAptitudeChoice: roleAptitudeChoice,
            legacyFallbackAptitudes: legacyFallbackAptitudes,
            unrecognizedHomeWorldInput: unrecognizedHomeWorldInput,
            unrecognizedBackgroundInput: unrecognizedBackgroundInput,
            unrecognizedRoleInput: unrecognizedRoleInput,
            characteristicGenerationState: characteristicGenerationState
        )
    }

    func settingRole(_ id: DHIIRoleID?) -> DHIICreationDraft {
        let validOptions = id.flatMap { roleID in
            DHIICharacterCreationEngine.canonicalRoles.first { $0.id == roleID }?.aptitudeRules.compactMap { rule -> String? in
                guard case .choice(let first, let second) = rule else {
                    return nil
                }
                return [first, second].joined(separator: "||")
            }.first?.components(separatedBy: "||")
        } ?? []

        return DHIICreationDraft(
            homeWorldID: homeWorldID,
            backgroundID: backgroundID,
            roleID: id,
            backgroundAptitudeChoice: backgroundAptitudeChoice,
            roleAptitudeChoice: validatedChoice(roleAptitudeChoice, options: validOptions),
            legacyFallbackAptitudes: legacyFallbackAptitudes,
            unrecognizedHomeWorldInput: unrecognizedHomeWorldInput,
            unrecognizedBackgroundInput: unrecognizedBackgroundInput,
            unrecognizedRoleInput: nil,
            characteristicGenerationState: characteristicGenerationState
        )
    }

    func settingRoleAptitudeChoice(_ choice: String?) -> DHIICreationDraft {
        let validOptions = roleDefinition?.aptitudeRules.compactMap { rule -> String? in
            guard case .choice(let first, let second) = rule else {
                return nil
            }
            return [first, second].joined(separator: "||")
        }.first?.components(separatedBy: "||") ?? []

        return DHIICreationDraft(
            homeWorldID: homeWorldID,
            backgroundID: backgroundID,
            roleID: roleID,
            backgroundAptitudeChoice: backgroundAptitudeChoice,
            roleAptitudeChoice: validatedChoice(choice, options: validOptions),
            legacyFallbackAptitudes: legacyFallbackAptitudes,
            unrecognizedHomeWorldInput: unrecognizedHomeWorldInput,
            unrecognizedBackgroundInput: unrecognizedBackgroundInput,
            unrecognizedRoleInput: unrecognizedRoleInput,
            characteristicGenerationState: characteristicGenerationState
        )
    }
}

enum DHIICharacterCreationEngine {
    static let backgroundCreationNotes: [String] = [
        "Starting skills from a background are gained at Known (+0).",
        "Starting talents granted by a background ignore normal prerequisites during character creation.",
        "Starting ranged weapons from a background come with two clips of their standard ammunition, which the current character model does not yet track structurally."
    ]

    static let canonicalHomeWorlds: [DHIIHomeWorldDefinition] = [
        DHIIHomeWorldDefinition(
            id: .feralWorld,
            aliases: ["Feral", "Feral World"],
            characteristicModifiers: [
                DHIICharacteristicModifierRule(target: .characteristic(.strength), delta: 1),
                DHIICharacteristicModifierRule(target: .characteristic(.toughness), delta: 1),
                DHIICharacteristicModifierRule(target: .influence, delta: -1)
            ],
            fateThreshold: DHIIFateThresholdRule(baseThreshold: 2, emperorsBlessingTarget: 3),
            homeWorldBonus: DHIIHomeWorldBonusRule(
                name: "The Old Ways",
                summary: "Any Low-Tech weapon the character uses loses Primitive and gains Proven (3)."
            ),
            aptitude: "Toughness",
            wounds: DHIIWoundsRule(base: 9, diceCount: 1, diceSides: 5),
            recommendedBackgrounds: ["Adeptus Arbites", "Adeptus Astra Telepathica", "Imperial Guard", "Outcast"],
            sourceCitation: "Dark Heresy Second Edition Core Rulebook p. 32"
        ),
        DHIIHomeWorldDefinition(
            id: .forgeWorld,
            aliases: ["Forge", "Forge World"],
            characteristicModifiers: [
                DHIICharacteristicModifierRule(target: .characteristic(.intelligence), delta: 1),
                DHIICharacteristicModifierRule(target: .characteristic(.toughness), delta: 1),
                DHIICharacteristicModifierRule(target: .characteristic(.fellowship), delta: -1)
            ],
            fateThreshold: DHIIFateThresholdRule(baseThreshold: 3, emperorsBlessingTarget: 8),
            homeWorldBonus: DHIIHomeWorldBonusRule(
                name: "Omnissiah's Chosen",
                summary: "The character starts with either the Technical Knock or Weapon-Tech talent."
            ),
            aptitude: "Intelligence",
            wounds: DHIIWoundsRule(base: 8, diceCount: 1, diceSides: 5),
            recommendedBackgrounds: ["Adeptus Administratum", "Adeptus Arbites", "Adeptus Mechanicus", "Imperial Guard"],
            sourceCitation: "Dark Heresy Second Edition Core Rulebook p. 34"
        ),
        DHIIHomeWorldDefinition(
            id: .highborn,
            aliases: ["Highborn"],
            characteristicModifiers: [
                DHIICharacteristicModifierRule(target: .characteristic(.fellowship), delta: 1),
                DHIICharacteristicModifierRule(target: .influence, delta: 1),
                DHIICharacteristicModifierRule(target: .characteristic(.toughness), delta: -1)
            ],
            fateThreshold: DHIIFateThresholdRule(baseThreshold: 4, emperorsBlessingTarget: 10),
            homeWorldBonus: DHIIHomeWorldBonusRule(
                name: "Breeding Counts",
                summary: "Whenever the character would reduce Influence, reduce it by 1 less to a minimum reduction of 1."
            ),
            aptitude: "Fellowship",
            wounds: DHIIWoundsRule(base: 9, diceCount: 1, diceSides: 5),
            recommendedBackgrounds: ["Adeptus Administratum", "Adeptus Arbites", "Adeptus Astra Telepathica", "Adeptus Ministorum"],
            sourceCitation: "Dark Heresy Second Edition Core Rulebook p. 36"
        ),
        DHIIHomeWorldDefinition(
            id: .hiveWorld,
            aliases: ["Hive", "Hive World"],
            characteristicModifiers: [
                DHIICharacteristicModifierRule(target: .characteristic(.agility), delta: 1),
                DHIICharacteristicModifierRule(target: .characteristic(.perception), delta: 1),
                DHIICharacteristicModifierRule(target: .characteristic(.willpower), delta: -1)
            ],
            fateThreshold: DHIIFateThresholdRule(baseThreshold: 2, emperorsBlessingTarget: 6),
            homeWorldBonus: DHIIHomeWorldBonusRule(
                name: "Teeming Masses in Metal Mountains",
                summary: "Crowds count as open terrain for movement, and enclosed spaces grant +20 to Navigate (Surface)."
            ),
            aptitude: "Perception",
            wounds: DHIIWoundsRule(base: 8, diceCount: 1, diceSides: 5),
            recommendedBackgrounds: ["Adeptus Arbites", "Adeptus Mechanicus", "Imperial Guard", "Outcast"],
            sourceCitation: "Dark Heresy Second Edition Core Rulebook p. 38"
        ),
        DHIIHomeWorldDefinition(
            id: .shrineWorld,
            aliases: ["Shrine", "Shrine World"],
            characteristicModifiers: [
                DHIICharacteristicModifierRule(target: .characteristic(.fellowship), delta: 1),
                DHIICharacteristicModifierRule(target: .characteristic(.willpower), delta: 1),
                DHIICharacteristicModifierRule(target: .characteristic(.perception), delta: -1)
            ],
            fateThreshold: DHIIFateThresholdRule(baseThreshold: 3, emperorsBlessingTarget: 6),
            homeWorldBonus: DHIIHomeWorldBonusRule(
                name: "Faith in the Creed",
                summary: "When the character spends a Fate point, roll 1d10; on 1 the total Fate pool is not reduced."
            ),
            aptitude: "Willpower",
            wounds: DHIIWoundsRule(base: 7, diceCount: 1, diceSides: 5),
            recommendedBackgrounds: ["Adeptus Administratum", "Adeptus Arbites", "Adeptus Ministorum", "Imperial Guard"],
            sourceCitation: "Dark Heresy Second Edition Core Rulebook p. 40"
        ),
        DHIIHomeWorldDefinition(
            id: .voidborn,
            aliases: ["Voidborn", "Void Born"],
            characteristicModifiers: [
                DHIICharacteristicModifierRule(target: .characteristic(.intelligence), delta: 1),
                DHIICharacteristicModifierRule(target: .characteristic(.willpower), delta: 1),
                DHIICharacteristicModifierRule(target: .characteristic(.strength), delta: -1)
            ],
            fateThreshold: DHIIFateThresholdRule(baseThreshold: 3, emperorsBlessingTarget: 5),
            homeWorldBonus: DHIIHomeWorldBonusRule(
                name: "Child of the Dark",
                summary: "The character starts with Strong Minded and gains +30 to move in zero gravity."
            ),
            aptitude: "Intelligence",
            wounds: DHIIWoundsRule(base: 7, diceCount: 1, diceSides: 5),
            recommendedBackgrounds: ["Adeptus Astra Telepathica", "Adeptus Mechanicus", "Adeptus Ministorum", "Outcast"],
            sourceCitation: "Dark Heresy Second Edition Core Rulebook p. 42"
        )
    ]

    static let canonicalBackgrounds: [DHIIBackgroundDefinition] = [
        DHIIBackgroundDefinition(
            id: .adeptusAdministratum,
            aliases: ["Administratum", "Adeptus Administratum"],
            aptitudeOptions: ["Knowledge", "Social"],
            startingSkills: [
                "Commerce or Medicae",
                "Common Lore (Adeptus Administratum)",
                "Linguistics (High Gothic)",
                "Logic",
                "Scholastic Lore (Pick One)"
            ],
            startingTalents: ["Weapon Training (Las or Solid Projectile)"],
            startingTraits: [],
            startingEquipment: [
                "Laspistol or stub automatic",
                "Imperial robes",
                "autoquill",
                "chrono",
                "dataslate",
                "medi-kit"
            ],
            backgroundBonus: DHIIBackgroundBonusRule(
                name: "Master of Paperwork",
                summary: "Availability of all items is treated as one level more available."
            ),
            recommendedRoles: ["Chirurgeon", "Hierophant", "Sage", "Seeker"],
            unsupportedProjectionRuleKeys: ["availability_modifier"],
            sourceCitation: "Dark Heresy Second Edition Core Rulebook pp. 44-45"
        ),
        DHIIBackgroundDefinition(
            id: .adeptusArbites,
            aliases: ["Arbites", "Adeptus Arbites"],
            aptitudeOptions: ["Offence", "Defence"],
            startingSkills: [
                "Awareness",
                "Common Lore (Adeptus Arbites, Underworld)",
                "Inquiry or Interrogation",
                "Intimidate",
                "Scrutiny"
            ],
            startingTalents: ["Weapon Training (Shock or Solid Projectile)"],
            startingTraits: [],
            startingEquipment: [
                "Shotgun or shock maul",
                "Enforcer light carapace armour or carapace chestplate",
                "3 doses of stimm",
                "manacles",
                "12 lho sticks"
            ],
            backgroundBonus: DHIIBackgroundBonusRule(
                name: "The Face of the Law",
                summary: "The character can re-roll Intimidate and Interrogation tests, and can substitute Willpower bonus for degrees of success on those tests."
            ),
            recommendedRoles: ["Assassin", "Desperado", "Seeker", "Warrior"],
            unsupportedProjectionRuleKeys: ["skill_specific_reroll", "degrees_of_success_substitution"],
            sourceCitation: "Dark Heresy Second Edition Core Rulebook pp. 46-47"
        ),
        DHIIBackgroundDefinition(
            id: .adeptusAstraTelepathica,
            aliases: ["Telepathica", "Adeptus Astra Telepathica", "Astra Telepathica"],
            aptitudeOptions: ["Defence", "Psyker"],
            startingSkills: [
                "Awareness",
                "Common Lore (Adeptus Astra Telepathica)",
                "Deceive or Interrogation",
                "Forbidden Lore (the Warp)",
                "Psyniscience or Scrutiny"
            ],
            startingTalents: ["Weapon Training (Las, Low-Tech)"],
            startingTraits: [],
            startingEquipment: [
                "Laspistol",
                "staff or whip",
                "light flak cloak or flak vest",
                "micro-bead or psy focus"
            ],
            backgroundBonus: DHIIBackgroundBonusRule(
                name: "The Constant Threat / Tested on Terra",
                summary: "Psychic Phenomenon results within 10m can be adjusted by Willpower bonus, and a Psyker elite advance taken during character creation also grants Sanctioned."
            ),
            recommendedRoles: ["Chirurgeon", "Mystic", "Sage", "Seeker"],
            unsupportedProjectionRuleKeys: ["psychic_phenomena_modifier", "conditional_creation_hook"],
            sourceCitation: "Dark Heresy Second Edition Core Rulebook pp. 48-49"
        ),
        DHIIBackgroundDefinition(
            id: .adeptusMechanicus,
            aliases: ["Mechanicus", "Adeptus Mechanicus"],
            aptitudeOptions: ["Knowledge", "Tech"],
            startingSkills: [
                "Awareness or Operate (Pick One)",
                "Common Lore (Adeptus Mechanicus)",
                "Logic",
                "Security",
                "Tech-Use"
            ],
            startingTalents: ["Mechadendrite Use (Utility)", "Weapon Training (Solid Projectile)"],
            startingTraits: ["Mechanicus Implants"],
            startingEquipment: [
                "Autogun or hand cannon",
                "monotask servo-skull (utility) or optical mechadendrite",
                "Imperial robes",
                "2 vials of sacred unguents"
            ],
            backgroundBonus: DHIIBackgroundBonusRule(
                name: "Replace the Weak Flesh",
                summary: "Availability of all cybernetics is treated as two levels more available."
            ),
            recommendedRoles: ["Chirurgeon", "Hierophant", "Sage", "Seeker"],
            unsupportedProjectionRuleKeys: ["cybernetic_availability_modifier"],
            sourceCitation: "Dark Heresy Second Edition Core Rulebook pp. 50-51"
        ),
        DHIIBackgroundDefinition(
            id: .adeptusMinistorum,
            aliases: ["Ministorum", "Adeptus Ministorum"],
            aptitudeOptions: ["Leadership", "Social"],
            startingSkills: [
                "Charm",
                "Command",
                "Common Lore (Adeptus Ministorum)",
                "Inquiry or Scrutiny",
                "Linguistics (High Gothic)"
            ],
            startingTalents: ["Weapon Training (Flame) or Weapon Training (Low-Tech, Solid Projectile)"],
            startingTraits: [],
            startingEquipment: [
                "Hand flamer (or warhammer and stub revolver)",
                "Imperial robes or flak vest",
                "backpack",
                "glow-globe",
                "monotask servo-skull (laud hailer)"
            ],
            backgroundBonus: DHIIBackgroundBonusRule(
                name: "Faith is All",
                summary: "When spending a Fate point for +10 to a test, the character gains +20 instead."
            ),
            recommendedRoles: ["Chirurgeon", "Hierophant", "Seeker", "Warrior"],
            unsupportedProjectionRuleKeys: ["fate_spend_modifier"],
            sourceCitation: "Dark Heresy Second Edition Core Rulebook pp. 52-53"
        ),
        DHIIBackgroundDefinition(
            id: .imperialGuard,
            aliases: ["Guard", "Imperial Guard"],
            aptitudeOptions: ["Fieldcraft", "Leadership"],
            startingSkills: [
                "Athletics",
                "Command",
                "Common Lore (Imperial Guard)",
                "Medicae or Operate (Surface)",
                "Navigate (Surface)"
            ],
            startingTalents: ["Weapon Training (Las, Low-Tech)"],
            startingTraits: [],
            startingEquipment: [
                "Lasgun (or laspistol and sword)",
                "combat vest",
                "Imperial Guard flak armour",
                "grapnel and line",
                "12 lho sticks",
                "magnoculars"
            ],
            backgroundBonus: DHIIBackgroundBonusRule(
                name: "Hammer of the Emperor",
                summary: "Damage dice showing 1 or 2 can be re-rolled against a target an ally attacked since the end of the character's last turn."
            ),
            recommendedRoles: ["Assassin", "Desperado", "Hierophant", "Warrior"],
            unsupportedProjectionRuleKeys: ["combat_state_dependent_damage_reroll"],
            sourceCitation: "Dark Heresy Second Edition Core Rulebook pp. 54-55"
        ),
        DHIIBackgroundDefinition(
            id: .outcast,
            aliases: ["Outcast"],
            aptitudeOptions: ["Fieldcraft", "Social"],
            startingSkills: [
                "Acrobatics or Sleight of Hand",
                "Common Lore (Underworld)",
                "Deceive",
                "Dodge",
                "Stealth"
            ],
            startingTalents: ["Weapon Training (Chain, and Las or Solid Projectile)"],
            startingTraits: [],
            startingEquipment: [
                "Autopistol or laspistol",
                "chainsword",
                "armoured bodyglove or flak vest",
                "injector",
                "2 doses of obscura or slaught"
            ],
            backgroundBonus: DHIIBackgroundBonusRule(
                name: "Never Quit",
                summary: "The character counts Toughness bonus as two higher when determining Fatigue."
            ),
            recommendedRoles: ["Assassin", "Desperado", "Seeker"],
            unsupportedProjectionRuleKeys: ["fatigue_threshold_modifier"],
            sourceCitation: "Dark Heresy Second Edition Core Rulebook pp. 56-57"
        )
    ]

    static let canonicalRoles: [DHIIRoleDefinition] = [
        DHIIRoleDefinition(
            id: .assassin,
            aliases: ["Assassin"],
            aptitudeRules: [
                .fixed("Agility"),
                .choice("Ballistic Skill", "Weapon Skill"),
                .fixed("Fieldcraft"),
                .fixed("Finesse"),
                .fixed("Perception")
            ],
            roleTalentChoices: ["Jaded", "Leap Up"],
            roleBonus: DHIIRoleBonusRule(
                name: "Sure Kill",
                summary: "After a successful hit, the character can spend a Fate point to add the attack roll's degrees of success to the damage of the first hit."
            ),
            unsupportedProjectionRuleKeys: ["aptitude_choice_provenance", "role_talent_choice", "role_bonus_hook"],
            sourceCitation: "Dark Heresy Second Edition Core Rulebook pp. 58-59"
        ),
        DHIIRoleDefinition(
            id: .chirurgeon,
            aliases: ["Chirurgeon"],
            aptitudeRules: [
                .fixed("Fieldcraft"),
                .fixed("Intelligence"),
                .fixed("Knowledge"),
                .fixed("Strength"),
                .fixed("Toughness")
            ],
            roleTalentChoices: ["Resistance (Pick One)", "Takedown"],
            roleBonus: DHIIRoleBonusRule(
                name: "Dedicated Healer",
                summary: "After failing a First Aid test, the character can spend a Fate point to automatically succeed with degrees of success equal to Intelligence bonus."
            ),
            unsupportedProjectionRuleKeys: ["role_talent_choice", "role_bonus_hook"],
            sourceCitation: "Dark Heresy Second Edition Core Rulebook p. 59"
        ),
        DHIIRoleDefinition(
            id: .desperado,
            aliases: ["Desperado"],
            aptitudeRules: [
                .fixed("Agility"),
                .fixed("Ballistic Skill"),
                .fixed("Defence"),
                .fixed("Fellowship"),
                .fixed("Finesse")
            ],
            roleTalentChoices: ["Catfall", "Quick Draw"],
            roleBonus: DHIIRoleBonusRule(
                name: "Move and Shoot",
                summary: "Once per round, after a Move action, the character can make a Standard Attack with a wielded pistol as a Free Action."
            ),
            unsupportedProjectionRuleKeys: ["role_talent_choice", "role_bonus_hook"],
            sourceCitation: "Dark Heresy Second Edition Core Rulebook p. 60"
        ),
        DHIIRoleDefinition(
            id: .hierophant,
            aliases: ["Hierophant"],
            aptitudeRules: [
                .fixed("Fellowship"),
                .fixed("Offence"),
                .fixed("Social"),
                .fixed("Toughness"),
                .fixed("Willpower")
            ],
            roleTalentChoices: ["Double Team", "Hatred (Pick One)"],
            roleBonus: DHIIRoleBonusRule(
                name: "Sway the Masses",
                summary: "The character can spend a Fate point to automatically succeed at Charm, Command, or Intimidate with degrees of success equal to Willpower bonus."
            ),
            unsupportedProjectionRuleKeys: ["role_talent_choice", "role_bonus_hook"],
            sourceCitation: "Dark Heresy Second Edition Core Rulebook p. 61"
        ),
        DHIIRoleDefinition(
            id: .mystic,
            aliases: ["Mystic"],
            aptitudeRules: [
                .fixed("Defence"),
                .fixed("Intelligence"),
                .fixed("Knowledge"),
                .fixed("Perception"),
                .fixed("Willpower")
            ],
            roleTalentChoices: ["Resistance (Psychic Powers)", "Warp Sense"],
            roleBonus: DHIIRoleBonusRule(
                name: "Stare into the Warp",
                summary: "The character starts with the Psyker elite advance; the rulebook also recommends Willpower 35+ for this role."
            ),
            unsupportedProjectionRuleKeys: ["psyker_elite_advance_hook", "role_talent_choice", "role_bonus_hook"],
            sourceCitation: "Dark Heresy Second Edition Core Rulebook p. 62"
        ),
        DHIIRoleDefinition(
            id: .sage,
            aliases: ["Sage"],
            aptitudeRules: [
                .fixed("Intelligence"),
                .fixed("Knowledge"),
                .fixed("Perception"),
                .fixed("Tech"),
                .fixed("Willpower")
            ],
            roleTalentChoices: ["Ambidextrous", "Clues from the Crowds"],
            roleBonus: DHIIRoleBonusRule(
                name: "Quest for Knowledge",
                summary: "The character can spend a Fate point to automatically succeed at Logic or any Lore test with degrees of success equal to Intelligence bonus."
            ),
            unsupportedProjectionRuleKeys: ["role_talent_choice", "role_bonus_hook"],
            sourceCitation: "Dark Heresy Second Edition Core Rulebook p. 63"
        ),
        DHIIRoleDefinition(
            id: .seeker,
            aliases: ["Seeker"],
            aptitudeRules: [
                .fixed("Fellowship"),
                .fixed("Intelligence"),
                .fixed("Perception"),
                .fixed("Social"),
                .fixed("Tech")
            ],
            roleTalentChoices: ["Keen Intuition", "Disarm"],
            roleBonus: DHIIRoleBonusRule(
                name: "Nothing Escapes My Sight",
                summary: "The character can spend a Fate point to automatically succeed at Awareness or Inquiry with degrees of success equal to Perception bonus."
            ),
            unsupportedProjectionRuleKeys: ["role_talent_choice", "role_bonus_hook"],
            sourceCitation: "Dark Heresy Second Edition Core Rulebook p. 64"
        ),
        DHIIRoleDefinition(
            id: .warrior,
            aliases: ["Warrior"],
            aptitudeRules: [
                .fixed("Ballistic Skill"),
                .fixed("Defence"),
                .fixed("Offence"),
                .fixed("Strength"),
                .fixed("Weapon Skill")
            ],
            roleTalentChoices: ["Iron Jaw", "Rapid Reload"],
            roleBonus: DHIIRoleBonusRule(
                name: "Expert at Violence",
                summary: "After a successful attack and before hits are determined, the character can spend a Fate point to replace attack-roll degrees of success with Weapon Skill bonus or Ballistic Skill bonus."
            ),
            unsupportedProjectionRuleKeys: ["role_talent_choice", "role_bonus_hook"],
            sourceCitation: "Dark Heresy Second Edition Core Rulebook p. 65"
        )
    ]

    static func canonicalHomeWorld(for rawValue: String) -> DHIIHomeWorldDefinition? {
        let normalized = normalizedCatalogToken(rawValue)
        guard normalized != nil else {
            return nil
        }

        return canonicalHomeWorlds.first { definition in
            definition.aliases.contains { alias in
                normalizedCatalogToken(alias) == normalized
            } || normalizedCatalogToken(definition.displayName) == normalized
        }
    }

    static func canonicalBackground(for rawValue: String) -> DHIIBackgroundDefinition? {
        let normalized = normalizedCatalogToken(rawValue)
        guard normalized != nil else {
            return nil
        }

        return canonicalBackgrounds.first { definition in
            definition.aliases.contains { alias in
                normalizedCatalogToken(alias) == normalized
            } || normalizedCatalogToken(definition.displayName) == normalized
        }
    }

    static func canonicalRole(for rawValue: String) -> DHIIRoleDefinition? {
        let normalized = normalizedCatalogToken(rawValue)
        guard normalized != nil else {
            return nil
        }

        return canonicalRoles.first { definition in
            definition.aliases.contains { alias in
                normalizedCatalogToken(alias) == normalized
            } || normalizedCatalogToken(definition.displayName) == normalized
        }
    }

    static func previewHomeWorldSelection(rawValue: String) -> DHIIHomeWorldPreview? {
        guard let definition = canonicalHomeWorld(for: rawValue) else {
            return nil
        }

        return DHIIHomeWorldPreview(
            definition: definition,
            compatibility: compatibilityReport(for: definition)
        )
    }

    static func previewBackgroundSelection(
        rawValue: String,
        homeWorldRawValue: String? = nil
    ) -> DHIIBackgroundPreview? {
        guard let definition = canonicalBackground(for: rawValue) else {
            return nil
        }

        return DHIIBackgroundPreview(
            definition: definition,
            compatibility: compatibilityReport(for: definition, homeWorldRawValue: homeWorldRawValue)
        )
    }

    static func previewRoleSelection(
        rawValue: String,
        backgroundRawValue: String? = nil
    ) -> DHIIRolePreview? {
        guard let definition = canonicalRole(for: rawValue) else {
            return nil
        }

        return DHIIRolePreview(
            definition: definition,
            compatibility: compatibilityReport(for: definition, backgroundRawValue: backgroundRawValue)
        )
    }

    static func creationDraft(from profile: Profile) -> DHIICreationDraft {
        let homeWorldDefinition = canonicalHomeWorld(for: profile.homeWorld)
        let backgroundDefinition = canonicalBackground(for: profile.background)
        let roleDefinition = canonicalRole(for: profile.role)

        var remainingLegacyAptitudes = sanitizedLegacyAptitudes(from: profile.aptitudes)
        let backgroundChoice = inferAndConsumeChoice(
            options: backgroundDefinition?.aptitudeOptions ?? [],
            from: &remainingLegacyAptitudes
        )
        let roleChoice = inferAndConsumeChoice(
            options: roleDefinition?.aptitudeRules.compactMap { rule -> String? in
                guard case .choice(let first, let second) = rule else {
                    return nil
                }
                return [first, second].joined(separator: "||")
            }.first?.components(separatedBy: "||") ?? [],
            from: &remainingLegacyAptitudes
        )

        return DHIICreationDraft(
            homeWorldID: homeWorldDefinition?.id,
            backgroundID: backgroundDefinition?.id,
            roleID: roleDefinition?.id,
            backgroundAptitudeChoice: backgroundChoice,
            roleAptitudeChoice: roleChoice,
            legacyFallbackAptitudes: remainingLegacyAptitudes,
            unrecognizedHomeWorldInput: unrecognizedLegacyInput(profile.homeWorld, recognized: homeWorldDefinition != nil),
            unrecognizedBackgroundInput: unrecognizedLegacyInput(profile.background, recognized: backgroundDefinition != nil),
            unrecognizedRoleInput: unrecognizedLegacyInput(profile.role, recognized: roleDefinition != nil),
            characteristicGenerationState: nil
        )
    }

    static func composeAptitudes(for profile: Profile) -> DHIIAptitudeComposition {
        composeAptitudes(for: creationDraft(from: profile))
    }

    static func composeAptitudes(for draft: DHIICreationDraft) -> DHIIAptitudeComposition {
        var resolvedAptitudes: [String] = []
        var unresolvedChoices: [String] = []
        var unsupportedRuleKeys: [String] = []
        var contextualMessages: [String] = []

        if let homeWorld = draft.homeWorldDefinition {
            appendAptitude(homeWorld.aptitude, into: &resolvedAptitudes)
        } else if draft.unrecognizedHomeWorldInput != nil {
            contextualMessages.append("Home world is not yet a canonical DHII selection, so its aptitude could not be composed.")
        }

        if let background = draft.backgroundDefinition {
            if background.aptitudeOptions.isEmpty == false {
                if let aptitude = validatedChoice(draft.backgroundAptitudeChoice, options: background.aptitudeOptions) {
                    appendAptitude(aptitude, into: &resolvedAptitudes)
                } else {
                    unresolvedChoices.append("\(background.displayName): \(explicitChoiceRequiredMessage(for: background.aptitudeOptions))")
                    unsupportedRuleKeys.append("background_aptitude_choice")
                }
            }
        } else if draft.unrecognizedBackgroundInput != nil {
            contextualMessages.append("Background is not yet a canonical DHII selection, so its aptitude choice could not be composed.")
        }

        if let role = draft.roleDefinition {
            for rule in role.aptitudeRules {
                switch rule {
                case .fixed(let aptitude):
                    appendAptitude(aptitude, into: &resolvedAptitudes)
                case .choice(let first, let second):
                    if let aptitude = validatedChoice(draft.roleAptitudeChoice, options: [first, second]) {
                        appendAptitude(aptitude, into: &resolvedAptitudes)
                    } else {
                        unresolvedChoices.append("\(role.displayName): \(explicitChoiceRequiredMessage(for: [first, second]))")
                        unsupportedRuleKeys.append("role_aptitude_choice")
                    }
                }
            }
        } else if draft.unrecognizedRoleInput != nil {
            contextualMessages.append("Role is not yet a canonical DHII selection, so its aptitudes could not be composed.")
        }

        let effectiveAptitudes = stableUniqueAptitudes(resolvedAptitudes + draft.legacyFallbackAptitudes)
        let legacyFallbackAptitudes = draft.legacyFallbackAptitudes

        return DHIIAptitudeComposition(
            resolvedAptitudes: resolvedAptitudes,
            effectiveAptitudes: effectiveAptitudes,
            legacyFallbackAptitudes: legacyFallbackAptitudes,
            unresolvedChoices: unresolvedChoices,
            compatibility: DHIICharacterModelCompatibilityReport(
                unsupportedRuleKeys: unsupportedRuleKeys,
                warningMessages: unresolvedChoices,
                contextualMessages: contextualMessages
            )
        )
    }

    static func compatibilityReport(for definition: DHIIHomeWorldDefinition) -> DHIICharacterModelCompatibilityReport {
        let unsupportedTargets = definition.characteristicModifiers.compactMap { modifier -> DHIICreationEffectTarget? in
            switch modifier.target {
            case .influence:
                return .influence
            case .characteristic:
                return nil
            }
        }

        let warningMessages = unsupportedTargets.map { target in
            "\(target.displayName) is part of \(definition.displayName) creation rules, but the current saved character snapshot does not yet store it as a first-class DHII engine field."
        }

        return DHIICharacterModelCompatibilityReport(
            unsupportedTargets: unsupportedTargets,
            warningMessages: warningMessages
        )
    }

    static func compatibilityReport(
        for definition: DHIIBackgroundDefinition,
        homeWorldRawValue: String?
    ) -> DHIICharacterModelCompatibilityReport {
        let warningMessages = definition.unsupportedProjectionRuleKeys.map { ruleKey in
            backgroundProjectionWarning(for: ruleKey, definition: definition)
        }

        var contextualMessages: [String] = []
        if let homeWorldRawValue,
           let homeWorld = canonicalHomeWorld(for: homeWorldRawValue) {
            if homeWorld.recommendedBackgrounds.contains(definition.displayName) {
                contextualMessages.append("Current home world preview recommends this background.")
            } else {
                contextualMessages.append("Current home world preview does not list this among its recommended backgrounds.")
            }
        }

        return DHIICharacterModelCompatibilityReport(
            unsupportedRuleKeys: definition.unsupportedProjectionRuleKeys,
            warningMessages: warningMessages,
            contextualMessages: contextualMessages
        )
    }

    static func compatibilityReport(
        for definition: DHIIRoleDefinition,
        backgroundRawValue: String?
    ) -> DHIICharacterModelCompatibilityReport {
        let warningMessages = definition.unsupportedProjectionRuleKeys.map { ruleKey in
            roleProjectionWarning(for: ruleKey, definition: definition)
        }

        var contextualMessages: [String] = []
        if let backgroundRawValue,
           let background = canonicalBackground(for: backgroundRawValue) {
            if background.recommendedRoles.contains(definition.displayName) {
                contextualMessages.append("Current background preview recommends this role.")
            } else {
                contextualMessages.append("Current background preview does not list this among its recommended roles.")
            }
        }

        return DHIICharacterModelCompatibilityReport(
            unsupportedRuleKeys: definition.unsupportedProjectionRuleKeys,
            warningMessages: warningMessages,
            contextualMessages: contextualMessages
        )
    }

    static func backgroundProjectionWarning(
        for ruleKey: String,
        definition: DHIIBackgroundDefinition
    ) -> String {
        switch ruleKey {
        case "availability_modifier":
            "\(definition.displayName) changes Availability during creation, but the current engine does not yet project requisition or item-availability modifiers."
        case "skill_specific_reroll":
            "\(definition.displayName) grants skill-specific re-roll behavior, but the current engine does not yet project per-skill re-roll hooks."
        case "degrees_of_success_substitution":
            "\(definition.displayName) can substitute Willpower bonus for degrees of success on certain tests, but the current engine does not yet project that rules hook."
        case "psychic_phenomena_modifier":
            "\(definition.displayName) modifies Psychic Phenomenon results within 10m, but the current engine does not yet project psychic-phenomena state."
        case "conditional_creation_hook":
            "\(definition.displayName) conditionally grants Sanctioned during character creation, but the current engine does not yet project that creation-time hook."
        case "cybernetic_availability_modifier":
            "\(definition.displayName) changes cybernetic Availability, but the current engine does not yet project cybernetic requisition modifiers."
        case "fate_spend_modifier":
            "\(definition.displayName) modifies Fate spending outcomes, but the current engine does not yet project that Fate-spend hook."
        case "combat_state_dependent_damage_reroll":
            "\(definition.displayName) depends on combat-state damage re-rolls, but the current engine does not yet project combat-state package hooks."
        case "fatigue_threshold_modifier":
            "\(definition.displayName) changes Fatigue determination, but the current engine does not yet project a rules-backed Fatigue threshold."
        default:
            "\(definition.displayName) includes a creation rule the current engine does not yet project safely."
        }
    }

    static func roleProjectionWarning(
        for ruleKey: String,
        definition: DHIIRoleDefinition
    ) -> String {
        switch ruleKey {
        case "aptitude_choice_provenance":
            "\(definition.displayName) contains an aptitude choice slot, but the current engine does not yet persist typed role-choice provenance."
        case "role_talent_choice":
            "\(definition.displayName) grants a role-talent choice, but the current engine does not yet project role-talent selection state."
        case "role_bonus_hook":
            "\(definition.displayName) grants a role bonus, but the current engine does not yet project that Fate- or combat-hook into the saved character model."
        case "psyker_elite_advance_hook":
            "\(definition.displayName) starts with the Psyker elite advance, but the current engine does not yet project that creation-time hook."
        default:
            "\(definition.displayName) includes a role rule the current engine does not yet project safely."
        }
    }
}

private func normalizedCatalogToken(_ value: String) -> String? {
    let cleaned = value.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !cleaned.isEmpty else {
        return nil
    }

    let pieces = cleaned.lowercased().map { character -> String in
        if character.isLetter || character.isNumber {
            return String(character)
        }
        return "-"
    }

    let normalized = pieces.joined()
        .split(separator: "-", omittingEmptySubsequences: true)
        .joined(separator: "-")
    return normalized.isEmpty ? nil : normalized
}

private enum DHIICanonicalChoiceResolution {
    case resolved(String)
    case unresolved(String)
    case notApplicable
}

private func resolveChoice(
    options: [String],
    using legacyAptitudes: [String]
) -> DHIICanonicalChoiceResolution {
    guard options.isEmpty == false else {
        return .notApplicable
    }

    let normalizedLegacy = Set(legacyAptitudes.compactMap(normalizedCatalogToken))
    let matchingOptions = options.filter { option in
        guard let normalizedOption = normalizedCatalogToken(option) else {
            return false
        }
        return normalizedLegacy.contains(normalizedOption)
    }

    switch matchingOptions.count {
    case 1:
        return .resolved(matchingOptions[0])
    case let count where count > 1:
        return .unresolved("multiple legacy aptitudes match the available choice slot (\(options.joined(separator: " or "))).")
    default:
        return .unresolved("requires an explicit aptitude choice (\(options.joined(separator: " or "))) that the current typed creation state does not yet store.")
    }
}

private func explicitChoiceRequiredMessage(for options: [String]) -> String {
    "requires an explicit aptitude choice (\(options.joined(separator: " or "))) that the current typed creation state does not yet store."
}

private func inferAndConsumeChoice(
    options: [String],
    from legacyAptitudes: inout [String]
) -> String? {
    switch resolveChoice(options: options, using: legacyAptitudes) {
    case .resolved(let aptitude):
        if let index = legacyAptitudes.firstIndex(where: { normalizedCatalogToken($0) == normalizedCatalogToken(aptitude) }) {
            legacyAptitudes.remove(at: index)
        }
        return aptitude
    case .unresolved, .notApplicable:
        return nil
    }
}

private func validatedChoice(_ choice: String?, options: [String]) -> String? {
    guard let choice,
          let normalizedChoice = normalizedCatalogToken(choice) else {
        return nil
    }

    return options.first { option in
        normalizedCatalogToken(option) == normalizedChoice
    }
}

private func unrecognizedLegacyInput(_ rawValue: String, recognized: Bool) -> String? {
    guard recognized == false else {
        return nil
    }

    let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? nil : trimmed
}

private func appendAptitude(_ aptitude: String, into aptitudes: inout [String]) {
    guard let normalized = normalizedCatalogToken(aptitude) else {
        return
    }

    if aptitudes.contains(where: { normalizedCatalogToken($0) == normalized }) == false {
        aptitudes.append(aptitude)
    }
}

private func stableUniqueAptitudes(_ aptitudes: [String]) -> [String] {
    var resolved: [String] = []
    for aptitude in aptitudes {
        appendAptitude(aptitude, into: &resolved)
    }
    return resolved
}

private func sanitizedLegacyAptitudes(from aptitudes: [String]) -> [String] {
    stableUniqueAptitudes(
        aptitudes.compactMap { aptitude in
            let trimmed = aptitude.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }
    )
}
