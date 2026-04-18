import Foundation

enum DHIICreationCharacteristic: String, CaseIterable, Sendable {
    case weaponSkill
    case ballisticSkill
    case strength
    case toughness
    case agility
    case intelligence
    case perception
    case willpower
    case fellowship
    case influence

    var displayName: String {
        switch self {
        case .weaponSkill:
            "Weapon Skill"
        case .ballisticSkill:
            "Ballistic Skill"
        case .strength:
            "Strength"
        case .toughness:
            "Toughness"
        case .agility:
            "Agility"
        case .intelligence:
            "Intelligence"
        case .perception:
            "Perception"
        case .willpower:
            "Willpower"
        case .fellowship:
            "Fellowship"
        case .influence:
            "Influence"
        }
    }

    var persistedCharacteristic: SkillCharacteristic? {
        switch self {
        case .weaponSkill:
            .weaponSkill
        case .ballisticSkill:
            .ballisticSkill
        case .strength:
            .strength
        case .toughness:
            .toughness
        case .agility:
            .agility
        case .intelligence:
            .intelligence
        case .perception:
            .perception
        case .willpower:
            .willpower
        case .fellowship:
            .fellowship
        case .influence:
            nil
        }
    }
}

struct DHIICreationCharacteristicValues: Equatable, Sendable {
    var weaponSkill: Int
    var ballisticSkill: Int
    var strength: Int
    var toughness: Int
    var agility: Int
    var intelligence: Int
    var perception: Int
    var willpower: Int
    var fellowship: Int
    var influence: Int

    static let zero = DHIICreationCharacteristicValues(
        weaponSkill: 0,
        ballisticSkill: 0,
        strength: 0,
        toughness: 0,
        agility: 0,
        intelligence: 0,
        perception: 0,
        willpower: 0,
        fellowship: 0,
        influence: 0
    )

    subscript(characteristic: DHIICreationCharacteristic) -> Int {
        get {
            switch characteristic {
            case .weaponSkill:
                weaponSkill
            case .ballisticSkill:
                ballisticSkill
            case .strength:
                strength
            case .toughness:
                toughness
            case .agility:
                agility
            case .intelligence:
                intelligence
            case .perception:
                perception
            case .willpower:
                willpower
            case .fellowship:
                fellowship
            case .influence:
                influence
            }
        }
        set {
            switch characteristic {
            case .weaponSkill:
                weaponSkill = newValue
            case .ballisticSkill:
                ballisticSkill = newValue
            case .strength:
                strength = newValue
            case .toughness:
                toughness = newValue
            case .agility:
                agility = newValue
            case .intelligence:
                intelligence = newValue
            case .perception:
                perception = newValue
            case .willpower:
                willpower = newValue
            case .fellowship:
                fellowship = newValue
            case .influence:
                influence = newValue
            }
        }
    }

    var totalAllocatedPoints: Int {
        weaponSkill
            + ballisticSkill
            + strength
            + toughness
            + agility
            + intelligence
            + perception
            + willpower
            + fellowship
            + influence
    }

    var projectedCharacteristicSet: CharacteristicSet {
        CharacteristicSet(
            weaponSkill: weaponSkill,
            ballisticSkill: ballisticSkill,
            strength: strength,
            toughness: toughness,
            agility: agility,
            intelligence: intelligence,
            perception: perception,
            willpower: willpower,
            fellowship: fellowship
        )
    }
}

struct DHIICharacteristicGenerationContribution: Equatable, Sendable {
    let label: String
    let value: Int
}

struct DHIICharacteristicGenerationBreakdown: Equatable, Sendable {
    let characteristic: DHIICreationCharacteristic
    let rolledDice: [Int]
    let keptDice: [Int]
    let contributions: [DHIICharacteristicGenerationContribution]
    let finalValue: Int
}

enum DHIICharacteristicGenerationMode: Equatable, Sendable {
    case randomRoll
    case pointAllocation
}

enum DHIICharacteristicGenerationValidationError: Error, Equatable, Sendable {
    case invalidRollValue(Int)
    case insufficientRolls(required: Int, provided: Int)
    case negativeAllocation(DHIICreationCharacteristic, Int)
    case overspentPoints(spent: Int, available: Int)
    case characteristicExceedsCap(DHIICreationCharacteristic, value: Int, cap: Int)
}

struct DHIICharacteristicGenerationPreview: Equatable, Sendable {
    let mode: DHIICharacteristicGenerationMode
    let values: DHIICreationCharacteristicValues?
    let projectedCharacteristics: CharacteristicSet?
    let rerolledCharacteristic: DHIICreationCharacteristic?
    let spentPoints: Int?
    let remainingPoints: Int?
    let breakdowns: [DHIICharacteristicGenerationBreakdown]
    let compatibility: DHIICharacterModelCompatibilityReport
    let validationMessages: [String]

    var isValid: Bool { validationMessages.isEmpty }

    func breakdown(for characteristic: DHIICreationCharacteristic) -> DHIICharacteristicGenerationBreakdown? {
        breakdowns.first { $0.characteristic == characteristic }
    }
}

struct DHIIRandomCharacteristicGenerationState: Equatable, Sendable {
    let generatedForHomeWorldID: DHIIHomeWorldID?
    let rollsByCharacteristic: [DHIICreationCharacteristic: [Int]]
    let rerolledCharacteristic: DHIICreationCharacteristic?
}

struct DHIIPointAllocationCharacteristicGenerationState: Equatable, Sendable {
    let allocations: DHIICreationCharacteristicValues
}

enum DHIICharacteristicGenerationState: Equatable, Sendable {
    case randomRoll(DHIIRandomCharacteristicGenerationState)
    case pointAllocation(DHIIPointAllocationCharacteristicGenerationState)
}

extension DHIICreationDraft {
    func settingPointAllocation(_ allocations: DHIICreationCharacteristicValues) throws -> DHIICreationDraft {
        try DHIICharacterCreationEngine.validatePointAllocation(allocations, for: self)
        return withCharacteristicGenerationState(.pointAllocation(.init(allocations: allocations)))
    }

    func withCharacteristicGenerationState(_ state: DHIICharacteristicGenerationState?) -> DHIICreationDraft {
        DHIICreationDraft(
            homeWorldID: homeWorldID,
            backgroundID: backgroundID,
            roleID: roleID,
            backgroundAptitudeChoice: backgroundAptitudeChoice,
            roleAptitudeChoice: roleAptitudeChoice,
            homeWorldTalentChoice: homeWorldTalentChoice,
            backgroundSkillChoices: backgroundSkillChoices,
            backgroundTalentChoice: backgroundTalentChoice,
            backgroundEquipmentChoices: backgroundEquipmentChoices,
            roleTalentChoice: roleTalentChoice,
            startingWoundsRoll: startingWoundsRoll,
            startingFateRoll: startingFateRoll,
            legacyFallbackAptitudes: legacyFallbackAptitudes,
            unrecognizedHomeWorldInput: unrecognizedHomeWorldInput,
            unrecognizedBackgroundInput: unrecognizedBackgroundInput,
            unrecognizedRoleInput: unrecognizedRoleInput,
            characteristicGenerationState: state
        )
    }
}

extension DHIICharacterCreationEngine {
    static func generateRandomCharacteristics(
        for draft: DHIICreationDraft,
        rolls: [Int],
        rerolling characteristic: DHIICreationCharacteristic? = nil
    ) throws -> DHIICreationDraft {
        var currentIndex = 0
        var collected: [DHIICreationCharacteristic: [Int]] = [:]

        for characteristic in DHIICreationCharacteristic.allCases {
            let rollCount = randomRollCount(
                for: characteristic,
                homeWorld: draft.homeWorldDefinition
            )
            collected[characteristic] = try consumeRolls(
                from: rolls,
                index: &currentIndex,
                count: rollCount
            )
        }

        if let characteristic {
            let rollCount = randomRollCount(
                for: characteristic,
                homeWorld: draft.homeWorldDefinition
            )
            collected[characteristic] = try consumeRolls(
                from: rolls,
                index: &currentIndex,
                count: rollCount
            )
        }

        return draft.withCharacteristicGenerationState(
            .randomRoll(
                DHIIRandomCharacteristicGenerationState(
                    generatedForHomeWorldID: draft.homeWorldID,
                    rollsByCharacteristic: collected,
                    rerolledCharacteristic: characteristic
                )
            )
        )
    }

    static func validatePointAllocation(
        _ allocations: DHIICreationCharacteristicValues,
        for draft: DHIICreationDraft
    ) throws {
        for characteristic in DHIICreationCharacteristic.allCases {
            let allocation = allocations[characteristic]
            if allocation < 0 {
                throw DHIICharacteristicGenerationValidationError.negativeAllocation(characteristic, allocation)
            }

            let finalValue = pointAllocationBaseValue(
                for: characteristic,
                homeWorld: draft.homeWorldDefinition
            ) + allocation
            if finalValue > pointAllocationCap {
                throw DHIICharacteristicGenerationValidationError.characteristicExceedsCap(
                    characteristic,
                    value: finalValue,
                    cap: pointAllocationCap
                )
            }
        }

        let spent = allocations.totalAllocatedPoints
        if spent > pointAllocationBudget {
            throw DHIICharacteristicGenerationValidationError.overspentPoints(
                spent: spent,
                available: pointAllocationBudget
            )
        }
    }

    static func previewCharacteristicGeneration(for draft: DHIICreationDraft) -> DHIICharacteristicGenerationPreview? {
        guard let state = draft.characteristicGenerationState else {
            return nil
        }

        switch state {
        case .randomRoll(let randomState):
            return previewRandomCharacteristicGeneration(
                randomState,
                for: draft
            )
        case .pointAllocation(let pointAllocationState):
            return previewPointAllocation(
                pointAllocationState,
                for: draft
            )
        }
    }

    static let pointAllocationBudget = 60
    static let pointAllocationCap = 40
    static let randomGenerationBaseValue = 20
    static let pointAllocationBaseScore = 25
    static let pointAllocationModifierDelta = 5
}

private extension DHIICharacterCreationEngine {
    static func previewRandomCharacteristicGeneration(
        _ state: DHIIRandomCharacteristicGenerationState,
        for draft: DHIICreationDraft
    ) -> DHIICharacteristicGenerationPreview {
        guard state.generatedForHomeWorldID == draft.homeWorldID else {
            let sourceWorld = state.generatedForHomeWorldID?.displayName ?? "an untyped home world"
            let currentWorld = draft.homeWorldID?.displayName ?? "an untyped home world"
            let message = "Random-roll characteristics were generated for \(sourceWorld) and must be regenerated after changing home world to \(currentWorld)."

            return DHIICharacteristicGenerationPreview(
                mode: .randomRoll,
                values: nil,
                projectedCharacteristics: nil,
                rerolledCharacteristic: state.rerolledCharacteristic,
                spentPoints: nil,
                remainingPoints: nil,
                breakdowns: [],
                compatibility: DHIICharacterModelCompatibilityReport(
                    contextualMessages: [message]
                ),
                validationMessages: [message]
            )
        }

        var values = DHIICreationCharacteristicValues.zero
        var breakdowns: [DHIICharacteristicGenerationBreakdown] = []

        for characteristic in DHIICreationCharacteristic.allCases {
            let rolledDice = state.rollsByCharacteristic[characteristic] ?? []
            let keptDice = keptDice(
                from: rolledDice,
                for: characteristic,
                homeWorld: draft.homeWorldDefinition
            )
            let finalValue = randomGenerationBaseValue + keptDice.reduce(0, +)
            values[characteristic] = finalValue
            breakdowns.append(
                DHIICharacteristicGenerationBreakdown(
                    characteristic: characteristic,
                    rolledDice: rolledDice,
                    keptDice: keptDice,
                    contributions: [
                        DHIICharacteristicGenerationContribution(label: "Base Value", value: randomGenerationBaseValue),
                        DHIICharacteristicGenerationContribution(label: "Retained Roll 1", value: keptDice.first ?? 0),
                        DHIICharacteristicGenerationContribution(label: "Retained Roll 2", value: keptDice.dropFirst().first ?? 0)
                    ],
                    finalValue: finalValue
                )
            )
        }

        return DHIICharacteristicGenerationPreview(
            mode: .randomRoll,
            values: values,
            projectedCharacteristics: values.projectedCharacteristicSet,
            rerolledCharacteristic: state.rerolledCharacteristic,
            spentPoints: nil,
            remainingPoints: nil,
            breakdowns: breakdowns,
            compatibility: influenceProjectionCompatibilityReport(),
            validationMessages: []
        )
    }

    static func previewPointAllocation(
        _ state: DHIIPointAllocationCharacteristicGenerationState,
        for draft: DHIICreationDraft
    ) -> DHIICharacteristicGenerationPreview {
        var values = DHIICreationCharacteristicValues.zero
        var breakdowns: [DHIICharacteristicGenerationBreakdown] = []
        var validationMessages: [String] = []
        let spentPoints = state.allocations.totalAllocatedPoints

        if spentPoints > pointAllocationBudget {
            validationMessages.append("Point allocation spends \(spentPoints) points, exceeding the DHII budget of \(pointAllocationBudget).")
        }

        for characteristic in DHIICreationCharacteristic.allCases {
            let baseValue = pointAllocationBaseScore
            let modifier = pointAllocationModifier(for: characteristic, homeWorld: draft.homeWorldDefinition)
            let allocatedPoints = state.allocations[characteristic]
            let finalValue = baseValue + modifier + allocatedPoints
            values[characteristic] = finalValue

            if finalValue > pointAllocationCap {
                validationMessages.append("\(characteristic.displayName) exceeds the DHII point-allocation cap of \(pointAllocationCap) after applying current home-world modifiers.")
            }

            breakdowns.append(
                DHIICharacteristicGenerationBreakdown(
                    characteristic: characteristic,
                    rolledDice: [],
                    keptDice: [],
                    contributions: [
                        DHIICharacteristicGenerationContribution(label: "Base Value", value: baseValue),
                        DHIICharacteristicGenerationContribution(label: "Home World Modifier", value: modifier),
                        DHIICharacteristicGenerationContribution(label: "Allocated Points", value: allocatedPoints)
                    ],
                    finalValue: finalValue
                )
            )
        }

        let projectedCharacteristics = validationMessages.isEmpty
            ? values.projectedCharacteristicSet
            : nil

        return DHIICharacteristicGenerationPreview(
            mode: .pointAllocation,
            values: values,
            projectedCharacteristics: projectedCharacteristics,
            rerolledCharacteristic: nil,
            spentPoints: spentPoints,
            remainingPoints: pointAllocationBudget - spentPoints,
            breakdowns: breakdowns,
            compatibility: influenceProjectionCompatibilityReport(),
            validationMessages: validationMessages
        )
    }

    static func randomRollCount(
        for characteristic: DHIICreationCharacteristic,
        homeWorld: DHIIHomeWorldDefinition?
    ) -> Int {
        pointAllocationModifier(for: characteristic, homeWorld: homeWorld) == 0 ? 2 : 3
    }

    static func pointAllocationBaseValue(
        for characteristic: DHIICreationCharacteristic,
        homeWorld: DHIIHomeWorldDefinition?
    ) -> Int {
        pointAllocationBaseScore + pointAllocationModifier(for: characteristic, homeWorld: homeWorld)
    }

    static func pointAllocationModifier(
        for characteristic: DHIICreationCharacteristic,
        homeWorld: DHIIHomeWorldDefinition?
    ) -> Int {
        let delta = homeWorld?.characteristicModifiers.first(where: { $0.target.matches(characteristic) })?.delta ?? 0
        return delta * pointAllocationModifierDelta
    }

    static func keptDice(
        from rolledDice: [Int],
        for characteristic: DHIICreationCharacteristic,
        homeWorld: DHIIHomeWorldDefinition?
    ) -> [Int] {
        let delta = homeWorld?.characteristicModifiers.first(where: { $0.target.matches(characteristic) })?.delta ?? 0
        switch delta {
        case let value where value > 0:
            return Array(rolledDice.sorted(by: >).prefix(2))
        case let value where value < 0:
            return Array(rolledDice.sorted().prefix(2))
        default:
            return Array(rolledDice.prefix(2))
        }
    }
}

private extension DHIICreationEffectTarget {
    func matches(_ characteristic: DHIICreationCharacteristic) -> Bool {
        switch (self, characteristic) {
        case (.influence, .influence):
            true
        case (.characteristic(let value), _):
            value == characteristic.persistedCharacteristic
        default:
            false
        }
    }
}

private func influenceProjectionCompatibilityReport() -> DHIICharacterModelCompatibilityReport {
    DHIICharacterModelCompatibilityReport(
        unsupportedTargets: [.influence],
        warningMessages: [
            "Influence is generated in the DHII creation engine, but the current saved character snapshot does not yet store it as a first-class field."
        ]
    )
}

private func consumeRolls(
    from rolls: [Int],
    index: inout Int,
    count: Int
) throws -> [Int] {
    guard index + count <= rolls.count else {
        throw DHIICharacteristicGenerationValidationError.insufficientRolls(
            required: index + count,
            provided: rolls.count
        )
    }

    let slice = Array(rolls[index..<(index + count)])
    for roll in slice where roll < 1 || roll > 10 {
        throw DHIICharacteristicGenerationValidationError.invalidRollValue(roll)
    }
    index += count
    return slice
}
