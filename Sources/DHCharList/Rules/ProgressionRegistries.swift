import Foundation

enum ProgressionCostModel: Equatable, Sendable {
    case fixed(Int)
    case manual

    var defaultCost: Int? {
        switch self {
        case .fixed(let value):
            max(0, value)
        case .manual:
            nil
        }
    }
}

enum TalentCategory: String, Equatable, Sendable {
    case combat
    case fieldcraft
    case mental
    case tech
    case training
}

struct TalentCatalogEntry: Identifiable, Equatable, Sendable {
    let id: String
    let displayName: String
    let category: TalentCategory?
    let costModel: ProgressionCostModel
    let prerequisites: [XPSpendPrerequisite]
    let aptitudeLinks: [String]
    let tags: [String]
    let source: String
    let isCanonical: Bool

    func makeUnlock(
        costOverride: Int? = nil,
        extraPrerequisites: [XPSpendPrerequisite] = []
    ) -> TalentUnlock {
        TalentUnlock(
            talentID: id,
            talentName: displayName,
            cost: costOverride ?? costModel.defaultCost ?? 0,
            prerequisites: prerequisites + extraPrerequisites
        )
    }
}

enum TalentCatalogRegistry {
    static let canonical: [TalentCatalogEntry] = [
        TalentCatalogEntry(
            id: "rapid-reload",
            displayName: "Rapid Reload",
            category: .combat,
            costModel: .fixed(100),
            prerequisites: [],
            aptitudeLinks: ["Agility", "Fieldcraft"],
            tags: ["combat", "ranged"],
            source: "Bounded Talent Registry",
            isCanonical: true
        ),
        TalentCatalogEntry(
            id: "deadeye-shot",
            displayName: "Deadeye Shot",
            category: .combat,
            costModel: .fixed(200),
            prerequisites: [.minimumCharacteristic(.ballisticSkill, 35)],
            aptitudeLinks: ["Ballistic Skill"],
            tags: ["combat", "ranged"],
            source: "Bounded Talent Registry (unverified in local core PDF extraction)",
            isCanonical: false
        ),
        TalentCatalogEntry(
            id: "meditation",
            displayName: "Meditation",
            category: .mental,
            costModel: .fixed(100),
            prerequisites: [],
            aptitudeLinks: ["Willpower"],
            tags: ["mental"],
            source: "Bounded Talent Registry (unverified in local core PDF extraction)",
            isCanonical: false
        ),
        TalentCatalogEntry(
            id: "weapon-tech",
            displayName: "Weapon-Tech",
            category: .tech,
            costModel: .fixed(200),
            prerequisites: [
                .minimumCharacteristic(.intelligence, 40),
                .requiredSkill(name: "Tech-Use", minimumTraining: .trained)
            ],
            aptitudeLinks: ["Intelligence", "Tech"],
            tags: ["tech", "equipment"],
            source: "Bounded Talent Registry",
            isCanonical: true
        ),
        TalentCatalogEntry(
            id: "melee-weapon-training-chain",
            displayName: "Melee Weapon Training (Chain)",
            category: .training,
            costModel: .fixed(100),
            prerequisites: [],
            aptitudeLinks: ["Weapon Skill"],
            tags: ["combat", "training"],
            source: "Bounded Talent Registry",
            isCanonical: true
        )
    ]

    static func lookup(id: String) -> TalentCatalogEntry? {
        canonical.first(where: { $0.id == id })
    }

    static func lookup(name: String) -> TalentCatalogEntry? {
        let normalizedName = normalizedProgressionRegistryToken(name)
        return canonical.first { entry in
            normalizedProgressionRegistryToken(entry.displayName) == normalizedName
        }
    }
}

struct CharacteristicAdvanceCatalogEntry: Identifiable, Equatable, Sendable {
    let id: String
    let characteristic: SkillCharacteristic
    let tier: Int
    let delta: Int
    let costModel: ProgressionCostModel
    let prerequisites: [XPSpendPrerequisite]
    let aptitudeLinks: [String]
    let source: String
    let isCanonical: Bool

    func makeAdvance(
        deltaOverride: Int? = nil,
        costOverride: Int? = nil,
        extraPrerequisites: [XPSpendPrerequisite] = []
    ) -> CharacteristicAdvance {
        CharacteristicAdvance(
            characteristic: characteristic,
            delta: deltaOverride ?? delta,
            cost: costOverride ?? costModel.defaultCost ?? 0,
            prerequisites: prerequisites + extraPrerequisites
        )
    }
}

enum CharacteristicAdvanceCatalogRegistry {
    static let canonical: [CharacteristicAdvanceCatalogEntry] = SkillCharacteristic.allCases.map { characteristic in
        CharacteristicAdvanceCatalogEntry(
            id: "characteristic.\(characteristic.rawValue).tier1",
            characteristic: characteristic,
            tier: 1,
            delta: 5,
            costModel: .manual,
            prerequisites: [],
            aptitudeLinks: [characteristic.label],
            source: "Bounded Advance Registry",
            isCanonical: true
        )
    }

    static func entry(for characteristic: SkillCharacteristic) -> CharacteristicAdvanceCatalogEntry {
        canonical.first(where: { $0.characteristic == characteristic })
            ?? CharacteristicAdvanceCatalogEntry(
                id: "characteristic.\(characteristic.rawValue).ad-hoc",
                characteristic: characteristic,
                tier: 1,
                delta: 5,
                costModel: .manual,
                prerequisites: [],
                aptitudeLinks: [],
                source: "Bounded Advance Registry",
                isCanonical: false
            )
    }
}

struct SkillAdvanceCatalogEntry: Identifiable, Equatable, Sendable {
    let id: String
    let skillMetadata: SkillMetadata
    let targetTraining: SkillTrainingLevel
    let costModel: ProgressionCostModel
    let prerequisites: [XPSpendPrerequisite]
    let aptitudeLinks: [String]
    let source: String
    let isCanonical: Bool

    func defaultCost(for profileAptitudes: [String]) -> Int? {
        guard aptitudeLinks.count == 2 else {
            return nil
        }

        let normalizedProfileAptitudes = Set(profileAptitudes.map(normalizedProgressionRegistryToken))
        let matchingAptitudes = Set(aptitudeLinks.map(normalizedProgressionRegistryToken))
            .intersection(normalizedProfileAptitudes)
            .count

        switch (matchingAptitudes, targetTraining) {
        case (2, .known): return 100
        case (2, .trained): return 200
        case (2, .experienced): return 300
        case (2, .veteran): return 400
        case (1, .known): return 200
        case (1, .trained): return 400
        case (1, .experienced): return 600
        case (1, .veteran): return 800
        case (0, .known): return 300
        case (0, .trained): return 600
        case (0, .experienced): return 900
        case (0, .veteran): return 1200
        case (_, .untrained): return nil
        default: return nil
        }
    }

    func makeAdvance(
        skill: Skill,
        costOverride: Int? = nil,
        extraPrerequisites: [XPSpendPrerequisite] = []
    ) -> SkillAdvance {
        SkillAdvance(
            skillID: skill.id,
            skillName: skill.displayName,
            targetTraining: targetTraining,
            cost: costOverride ?? costModel.defaultCost ?? 0,
            prerequisites: prerequisites + extraPrerequisites
        )
    }
}

enum SkillAdvanceCatalogRegistry {
    static func entry(for skill: Skill, targetTraining: SkillTrainingLevel) -> SkillAdvanceCatalogEntry {
        let metadata = SkillMetadataRegistry.resolve(skill)
        return SkillAdvanceCatalogEntry(
            id: "skill.\(metadata.id).\(targetTraining.rawValue)",
            skillMetadata: metadata,
            targetTraining: targetTraining,
            costModel: .manual,
            prerequisites: [],
            aptitudeLinks: metadata.advancementAptitudes ?? [metadata.linkedCharacteristic.label],
            source: "Bounded Advance Registry",
            isCanonical: metadata.advancementAptitudes != nil && metadata.isCanonical
        )
    }
}

private func normalizedProgressionRegistryToken(_ value: String) -> String {
    value
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .lowercased()
        .replacingOccurrences(of: "-", with: " ")
        .split(whereSeparator: { $0.isWhitespace })
        .joined(separator: " ")
}
