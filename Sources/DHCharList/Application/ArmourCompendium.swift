import Foundation

public struct ArmourCompendiumCatalog: Identifiable, Codable, Equatable, Sendable {
    public var id: String
    public var displayName: String
    public var definitions: [ArmourCompendiumDefinition]

    public init(id: String, displayName: String, definitions: [ArmourCompendiumDefinition]) {
        self.id = id
        self.displayName = displayName
        self.definitions = definitions
    }

    public func definition(id: String) -> ArmourCompendiumDefinition? {
        definitions.first { $0.id == id }
    }

    public static let demo = ArmourCompendiumCatalog(
        id: "local-demo",
        displayName: "Local Demo Armour Catalog",
        definitions: [
            ArmourCompendiumDefinition(
                id: "local-demo.carapace-breastplate",
                catalogID: "local-demo",
                name: "Carapace Breastplate",
                category: "Body Armour",
                coverage: ["Body"],
                armourPoints: 6,
                weight: "15kg",
                availability: "Very Rare",
                traits: ["Rigid"]
            ),
            ArmourCompendiumDefinition(
                id: "local-demo.flak-coat",
                catalogID: "local-demo",
                name: "Flak Coat",
                category: "Body Armour",
                coverage: ["Body", "Arms"],
                armourPoints: 4,
                weight: "8kg",
                availability: "Scarce",
                traits: ["Flak"]
            ),
            ArmourCompendiumDefinition(
                id: "local-demo.guard-helm",
                catalogID: "local-demo",
                name: "Guard Helm",
                category: "Head Armour",
                coverage: ["Head"],
                armourPoints: 3,
                weight: "2kg",
                availability: "Common",
                traits: ["Enclosed"]
            ),
            ArmourCompendiumDefinition(
                id: "local-demo.mesh-vest",
                catalogID: "local-demo",
                name: "Mesh Vest",
                category: "Body Armour",
                coverage: ["Body"],
                armourPoints: 5,
                weight: "5kg",
                availability: "Rare",
                traits: ["Flexible"]
            )
        ]
    )
}

public struct ArmourCompendiumDefinition: Identifiable, Codable, Equatable, Sendable {
    public var id: String
    public var catalogID: String
    public var name: String
    public var category: String
    public var coverage: [String]
    public var armourPoints: Int
    public var weight: String
    public var availability: String
    public var traits: [String]
    public var notes: String

    public init(
        id: String,
        catalogID: String,
        name: String,
        category: String = "",
        coverage: [String] = [],
        armourPoints: Int,
        weight: String = "",
        availability: String = "",
        traits: [String] = [],
        notes: String = ""
    ) {
        self.id = id
        self.catalogID = catalogID
        self.name = name
        self.category = category
        self.coverage = coverage
        self.armourPoints = armourPoints
        self.weight = weight
        self.availability = availability
        self.traits = traits
        self.notes = notes
    }

    public var coverageText: String {
        coverage
            .map(compendiumTrimmedText)
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }

    public var traitsText: String {
        traits
            .map(compendiumTrimmedText)
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }

    public var previewLine: String {
        [
            compendiumTrimmedOrNil(category),
            compendiumTrimmedOrNil(coverageText),
            "AP \(armourPoints)"
        ]
        .compactMap { $0 }
        .joined(separator: " • ")
    }

    public var supportingLine: String {
        [
            compendiumTrimmedOrNil(weight).map { "Weight \($0)" },
            compendiumTrimmedOrNil(availability),
            compendiumTrimmedOrNil(traitsText)
        ]
        .compactMap { $0 }
        .joined(separator: " • ")
    }

    public var characterLocationText: String {
        let cleanedName = compendiumTrimmedOrPlaceholder(name, placeholder: "Unnamed Armour")
        guard let cleanedCoverage = compendiumTrimmedOrNil(coverageText) else {
            return cleanedName
        }
        return "\(cleanedName) (\(cleanedCoverage))"
    }

    public func makeArmourInstance(id: UUID = UUID()) -> Armour {
        Armour(
            id: id,
            location: characterLocationText,
            armourPoints: armourPoints
        )
    }
}

public protocol ArmourCompendiumRepository: Sendable {
    func fetchCatalog() async throws -> ArmourCompendiumCatalog?
    func saveCatalog(_ catalog: ArmourCompendiumCatalog) async throws
}

public struct ArmourCompendiumUseCases: Sendable {
    private let repository: any ArmourCompendiumRepository

    public init(repository: any ArmourCompendiumRepository) {
        self.repository = repository
    }

    public func currentCatalog() async throws -> ArmourCompendiumCatalog {
        try await repository.fetchCatalog() ?? .demo
    }

    @discardableResult
    public func replaceCatalog(_ catalog: ArmourCompendiumCatalog) async throws -> ArmourCompendiumCatalog {
        try await repository.saveCatalog(catalog)
        return catalog
    }
}

public enum ArmourCompendiumSearch {
    public static func autocomplete(
        definitions: [ArmourCompendiumDefinition],
        query: String,
        limit: Int = 8
    ) -> [ArmourCompendiumDefinition] {
        let normalizedQuery = normalize(query)
        guard !normalizedQuery.isEmpty else { return [] }

        return definitions
            .compactMap { definition -> SearchMatchCandidate? in
                let normalizedName = normalize(definition.name)
                guard let rank = rankMatch(name: normalizedName, query: normalizedQuery) else {
                    return nil
                }
                return SearchMatchCandidate(rank: rank, definition: definition)
            }
            .sorted {
                if $0.rank != $1.rank {
                    return $0.rank < $1.rank
                }
                if $0.definition.name.count != $1.definition.name.count {
                    return $0.definition.name.count < $1.definition.name.count
                }
                return $0.definition.name.localizedCaseInsensitiveCompare($1.definition.name) == .orderedAscending
            }
            .prefix(limit)
            .map(\.definition)
    }

    private static func rankMatch(name: String, query: String) -> Int? {
        if name == query {
            return 0
        }
        if name.hasPrefix(query) {
            return 1
        }
        if name.contains(query) {
            return 2
        }
        return nil
    }

    private static func normalize(_ value: String) -> String {
        value
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }
}

private struct SearchMatchCandidate {
    let rank: Int
    let definition: ArmourCompendiumDefinition
}

private func compendiumTrimmedText(_ value: String) -> String {
    value.trimmingCharacters(in: .whitespacesAndNewlines)
}

private func compendiumTrimmedOrNil(_ value: String) -> String? {
    let cleaned = compendiumTrimmedText(value)
    return cleaned.isEmpty ? nil : cleaned
}

private func compendiumTrimmedOrPlaceholder(_ value: String, placeholder: String) -> String {
    let cleaned = compendiumTrimmedText(value)
    return cleaned.isEmpty ? placeholder : cleaned
}
