import Foundation

enum XPSpendValidationError: Equatable, Sendable {
    case insufficientExperience(required: Int, available: Int)
    case missingUpgradeTarget(String)
    case invalidUpgrade(String)
    case unmetPrerequisite(XPSpendPrerequisite)

    var message: String {
        switch self {
        case .insufficientExperience(let required, let available):
            "Requires \(required) XP but only \(available) XP is currently available."
        case .missingUpgradeTarget(let target):
            target
        case .invalidUpgrade(let detail):
            detail
        case .unmetPrerequisite(let prerequisite):
            prerequisite.failureLabel
        }
    }
}

enum XPSpendPrerequisite: Equatable, Sendable {
    case availableExperience(Int)
    case minimumCharacteristic(SkillCharacteristic, Int)
    case requiredSkill(name: String, minimumTraining: SkillTrainingLevel)
    case requiredAptitude(String)
    case requiredTalent(String)
    case requiredTrait(String)

    var label: String {
        switch self {
        case .availableExperience(let value):
            "Available XP \(value)+"
        case .minimumCharacteristic(let characteristic, let value):
            "\(characteristic.label) \(value)+"
        case .requiredSkill(let name, let minimumTraining):
            "\(name.trimmedOrPlaceholder("Unnamed Skill")) \(minimumTraining.label)+"
        case .requiredAptitude(let aptitude):
            "Aptitude: \(aptitude.trimmedOrPlaceholder("Unnamed Aptitude"))"
        case .requiredTalent(let talent):
            "Talent: \(talent.trimmedOrPlaceholder("Unnamed Talent"))"
        case .requiredTrait(let trait):
            "Trait: \(trait.trimmedOrPlaceholder("Unnamed Trait"))"
        }
    }

    var failureLabel: String {
        switch self {
        case .availableExperience:
            label
        case .minimumCharacteristic(let characteristic, let value):
            "Requires \(characteristic.label) \(value)+."
        case .requiredSkill(let name, let minimumTraining):
            "Requires \(name.trimmedOrPlaceholder("Unnamed Skill")) at \(minimumTraining.label) or higher."
        case .requiredAptitude(let aptitude):
            "Requires aptitude \(aptitude.trimmedOrPlaceholder("Unnamed Aptitude"))."
        case .requiredTalent(let talent):
            "Requires talent \(talent.trimmedOrPlaceholder("Unnamed Talent"))."
        case .requiredTrait(let trait):
            "Requires trait \(trait.trimmedOrPlaceholder("Unnamed Trait"))."
        }
    }
}

struct XPPrerequisiteEvaluation: Equatable, Sendable {
    let prerequisite: XPSpendPrerequisite
    let isSatisfied: Bool
    let detail: String
}

struct XPSpendBreakdown: Equatable, Sendable {
    let cost: Int
    let availableExperience: Int
    let projectedRemainingExperience: Int
    let prerequisiteEvaluations: [XPPrerequisiteEvaluation]
}

struct CharacteristicAdvance: Equatable, Sendable {
    let characteristic: SkillCharacteristic
    let delta: Int
    let cost: Int
    let prerequisites: [XPSpendPrerequisite]

    init(
        characteristic: SkillCharacteristic,
        delta: Int = 5,
        cost: Int,
        prerequisites: [XPSpendPrerequisite] = []
    ) {
        self.characteristic = characteristic
        self.delta = delta
        self.cost = cost
        self.prerequisites = prerequisites
    }
}

struct SkillAdvance: Equatable, Sendable {
    let skillID: UUID
    let skillName: String
    let targetTraining: SkillTrainingLevel
    let cost: Int
    let prerequisites: [XPSpendPrerequisite]

    init(
        skillID: UUID,
        skillName: String,
        targetTraining: SkillTrainingLevel,
        cost: Int,
        prerequisites: [XPSpendPrerequisite] = []
    ) {
        self.skillID = skillID
        self.skillName = skillName
        self.targetTraining = targetTraining
        self.cost = cost
        self.prerequisites = prerequisites
    }
}

enum XPSpendUpgrade: Equatable, Sendable {
    case characteristicAdvance(CharacteristicAdvance)
    case skillAdvance(SkillAdvance)

    var cost: Int {
        switch self {
        case .characteristicAdvance(let advance):
            advance.cost
        case .skillAdvance(let advance):
            advance.cost
        }
    }

    var prerequisites: [XPSpendPrerequisite] {
        switch self {
        case .characteristicAdvance(let advance):
            advance.prerequisites
        case .skillAdvance(let advance):
            advance.prerequisites
        }
    }

    var summary: String {
        switch self {
        case .characteristicAdvance(let advance):
            "\(advance.characteristic.label) \(advance.delta > 0 ? "+\(advance.delta)" : "\(advance.delta)")"
        case .skillAdvance(let advance):
            "\(advance.skillName.trimmedOrPlaceholder("Unnamed Skill")) to \(advance.targetTraining.label)"
        }
    }
}

struct XPSpendRequest: Equatable, Sendable {
    let character: Character
    let upgrade: XPSpendUpgrade

    init(character: Character, upgrade: XPSpendUpgrade) {
        self.character = character
        self.upgrade = upgrade
    }
}

struct XPSpendResult: Equatable, Sendable {
    let upgrade: XPSpendUpgrade
    let isValid: Bool
    let breakdown: XPSpendBreakdown
    let validationErrors: [XPSpendValidationError]
    let appliedCharacter: Character?
    let historyTitle: String?
    let historyBody: String?

    var cost: Int { breakdown.cost }
    var availableExperience: Int { breakdown.availableExperience }
    var projectedRemainingExperience: Int { breakdown.projectedRemainingExperience }
}

enum XPProgressionResolver {
    static func validate(_ request: XPSpendRequest) -> XPSpendResult {
        resolve(request, applyIfValid: false)
    }

    static func apply(_ request: XPSpendRequest) -> XPSpendResult {
        resolve(request, applyIfValid: true)
    }

    private static func resolve(_ request: XPSpendRequest, applyIfValid: Bool) -> XPSpendResult {
        let availableExperience = request.character.resources.experienceAvailable
        let allPrerequisites = [XPSpendPrerequisite.availableExperience(request.upgrade.cost)] + request.upgrade.prerequisites
        let evaluations = allPrerequisites.map { evaluate($0, for: request.character) }
        let projectedRemainingExperience = availableExperience - request.upgrade.cost

        var validationErrors = targetValidationErrors(for: request)
        validationErrors.append(contentsOf: evaluations.compactMap { evaluation in
            guard evaluation.isSatisfied == false else {
                return nil
            }

            switch evaluation.prerequisite {
            case .availableExperience(let required):
                return .insufficientExperience(required: required, available: availableExperience)
            default:
                return .unmetPrerequisite(evaluation.prerequisite)
            }
        })

        let breakdown = XPSpendBreakdown(
            cost: request.upgrade.cost,
            availableExperience: availableExperience,
            projectedRemainingExperience: projectedRemainingExperience,
            prerequisiteEvaluations: evaluations
        )

        guard validationErrors.isEmpty, applyIfValid else {
            return XPSpendResult(
                upgrade: request.upgrade,
                isValid: validationErrors.isEmpty,
                breakdown: breakdown,
                validationErrors: validationErrors,
                appliedCharacter: nil,
                historyTitle: nil,
                historyBody: nil
            )
        }

        var updatedCharacter = request.character
        applyUpgrade(request.upgrade, to: &updatedCharacter)
        updatedCharacter.resources.experienceSpent += request.upgrade.cost

        return XPSpendResult(
            upgrade: request.upgrade,
            isValid: true,
            breakdown: breakdown,
            validationErrors: [],
            appliedCharacter: updatedCharacter,
            historyTitle: "Advancement: \(request.upgrade.summary)",
            historyBody: historyBody(for: request, breakdown: breakdown)
        )
    }

    private static func targetValidationErrors(for request: XPSpendRequest) -> [XPSpendValidationError] {
        switch request.upgrade {
        case .characteristicAdvance(let advance):
            guard advance.delta > 0 else {
                return [.invalidUpgrade("Characteristic advances must increase the selected characteristic.")]
            }
            guard advance.cost >= 0 else {
                return [.invalidUpgrade("XP cost cannot be negative.")]
            }
            return []

        case .skillAdvance(let advance):
            guard advance.cost >= 0 else {
                return [.invalidUpgrade("XP cost cannot be negative.")]
            }
            guard let currentSkill = request.character.skills.first(where: { $0.id == advance.skillID }) else {
                return [.missingUpgradeTarget("The selected skill no longer exists on this character.")]
            }
            guard currentSkill.training.progressionRank < advance.targetTraining.progressionRank else {
                return [.invalidUpgrade("Skill advances must move to a higher training level than the character already has.")]
            }
            return []
        }
    }

    private static func evaluate(_ prerequisite: XPSpendPrerequisite, for character: Character) -> XPPrerequisiteEvaluation {
        switch prerequisite {
        case .availableExperience(let required):
            let available = character.resources.experienceAvailable
            return XPPrerequisiteEvaluation(
                prerequisite: prerequisite,
                isSatisfied: available >= required,
                detail: "\(available) XP currently available."
            )

        case .minimumCharacteristic(let characteristic, let minimum):
            let currentValue = character.characteristics.value(for: characteristic)
            return XPPrerequisiteEvaluation(
                prerequisite: prerequisite,
                isSatisfied: currentValue >= minimum,
                detail: "\(characteristic.label) is currently \(currentValue)."
            )

        case .requiredSkill(let name, let minimumTraining):
            let matchedSkill = character.skills.first {
                normalizedProgressionToken($0.displayName) == normalizedProgressionToken(name)
            }
            let currentTraining = matchedSkill?.training ?? .untrained
            return XPPrerequisiteEvaluation(
                prerequisite: prerequisite,
                isSatisfied: currentTraining.progressionRank >= minimumTraining.progressionRank,
                detail: "\(name.trimmedOrPlaceholder("Unnamed Skill")) is currently \(currentTraining.label)."
            )

        case .requiredAptitude(let aptitude):
            let required = aptitude.trimmedOrPlaceholder("Unnamed Aptitude")
            let hasAptitude = character.profile.aptitudes.contains {
                normalizedProgressionToken($0) == normalizedProgressionToken(required)
            }
            return XPPrerequisiteEvaluation(
                prerequisite: prerequisite,
                isSatisfied: hasAptitude,
                detail: hasAptitude ? "Character already has \(required)." : "\(required) is not listed on the profile."
            )

        case .requiredTalent(let talent):
            let required = talent.trimmedOrPlaceholder("Unnamed Talent")
            let hasTalent = character.notes.talents.contains {
                normalizedProgressionToken($0) == normalizedProgressionToken(required)
            }
            return XPPrerequisiteEvaluation(
                prerequisite: prerequisite,
                isSatisfied: hasTalent,
                detail: hasTalent ? "Character already knows \(required)." : "\(required) is not present in talents."
            )

        case .requiredTrait(let trait):
            let required = trait.trimmedOrPlaceholder("Unnamed Trait")
            let hasTrait = character.notes.traits.contains {
                normalizedProgressionToken($0) == normalizedProgressionToken(required)
            }
            return XPPrerequisiteEvaluation(
                prerequisite: prerequisite,
                isSatisfied: hasTrait,
                detail: hasTrait ? "Character already has \(required)." : "\(required) is not present in traits."
            )
        }
    }

    private static func applyUpgrade(_ upgrade: XPSpendUpgrade, to character: inout Character) {
        switch upgrade {
        case .characteristicAdvance(let advance):
            character.characteristics.adjust(advance.characteristic, by: advance.delta)

        case .skillAdvance(let advance):
            guard let index = character.skills.firstIndex(where: { $0.id == advance.skillID }) else {
                return
            }
            character.skills[index].training = advance.targetTraining
        }
    }

    private static func historyBody(for request: XPSpendRequest, breakdown: XPSpendBreakdown) -> String {
        let lines = [
            "Spent \(breakdown.cost) XP on \(request.upgrade.summary).",
            "Available before: \(breakdown.availableExperience) XP.",
            "Available after: \(breakdown.projectedRemainingExperience) XP."
        ]
        return lines.joined(separator: "\n")
    }
}

private extension CharacteristicSet {
    mutating func adjust(_ characteristic: SkillCharacteristic, by delta: Int) {
        switch characteristic {
        case .weaponSkill:
            weaponSkill += delta
        case .ballisticSkill:
            ballisticSkill += delta
        case .strength:
            strength += delta
        case .toughness:
            toughness += delta
        case .agility:
            agility += delta
        case .intelligence:
            intelligence += delta
        case .perception:
            perception += delta
        case .willpower:
            willpower += delta
        case .fellowship:
            fellowship += delta
        }
    }
}

extension SkillTrainingLevel {
    var progressionRank: Int {
        switch self {
        case .untrained:
            0
        case .known:
            1
        case .trained:
            2
        case .veteran:
            3
        }
    }
}

private extension String {
    func trimmedOrPlaceholder(_ placeholder: String) -> String {
        let cleaned = trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? placeholder : cleaned
    }
}

private func normalizedProgressionToken(_ value: String) -> String {
    value
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .lowercased()
        .replacingOccurrences(of: "-", with: " ")
        .split(whereSeparator: { $0.isWhitespace })
        .joined(separator: " ")
}
