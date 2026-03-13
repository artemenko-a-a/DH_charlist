import Foundation

enum ProgressionCostModel: Equatable, Sendable {
    case fixed(Int)

    var defaultCost: Int {
        switch self {
        case .fixed(let value):
            max(0, value)
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
            cost: costOverride ?? costModel.defaultCost,
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
            aptitudeLinks: ["Agility"],
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
            source: "Bounded Talent Registry",
            isCanonical: true
        ),
        TalentCatalogEntry(
            id: "meditation",
            displayName: "Meditation",
            category: .mental,
            costModel: .fixed(100),
            prerequisites: [],
            aptitudeLinks: ["Willpower"],
            tags: ["mental"],
            source: "Bounded Talent Registry",
            isCanonical: true
        ),
        TalentCatalogEntry(
            id: "weapon-tech",
            displayName: "Weapon-Tech",
            category: .tech,
            costModel: .fixed(200),
            prerequisites: [.requiredSkill(name: "Tech-Use", minimumTraining: .known)],
            aptitudeLinks: ["Intelligence"],
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
            cost: costOverride ?? costModel.defaultCost,
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
            costModel: .fixed(100),
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
                costModel: .fixed(100),
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

    func makeAdvance(
        skill: Skill,
        costOverride: Int? = nil,
        extraPrerequisites: [XPSpendPrerequisite] = []
    ) -> SkillAdvance {
        SkillAdvance(
            skillID: skill.id,
            skillName: skill.displayName,
            targetTraining: targetTraining,
            cost: costOverride ?? costModel.defaultCost,
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
            costModel: .fixed(100),
            prerequisites: [],
            aptitudeLinks: [metadata.linkedCharacteristic.label],
            source: "Bounded Advance Registry",
            isCanonical: metadata.isCanonical
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
