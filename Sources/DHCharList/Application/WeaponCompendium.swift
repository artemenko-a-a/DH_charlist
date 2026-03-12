import Foundation

public struct WeaponCompendiumCatalog: Identifiable, Codable, Equatable, Sendable {
    public var id: String
    public var displayName: String
    public var definitions: [WeaponCompendiumDefinition]

    public init(id: String, displayName: String, definitions: [WeaponCompendiumDefinition]) {
        self.id = id
        self.displayName = displayName
        self.definitions = definitions
    }

    public func definition(id: String) -> WeaponCompendiumDefinition? {
        definitions.first { $0.id == id }
    }

    public static let demo = WeaponCompendiumCatalog(
        id: "local-demo",
        displayName: "Local Demo Catalog",
        definitions: [
            WeaponCompendiumDefinition(
                id: "local-demo.autogun",
                catalogID: "local-demo",
                name: "Autogun",
                type: "Basic",
                range: "100m",
                damage: "1d10+3 I",
                penetration: "0",
                clip: "30",
                reload: "Half",
                traits: ["Reliable"]
            ),
            WeaponCompendiumDefinition(
                id: "local-demo.autopistol",
                catalogID: "local-demo",
                name: "Autopistol",
                type: "Pistol",
                range: "30m",
                damage: "1d10+2 I",
                penetration: "0",
                clip: "18",
                reload: "Half",
                traits: ["Reliable"]
            ),
            WeaponCompendiumDefinition(
                id: "local-demo.chainsword",
                catalogID: "local-demo",
                name: "Chainsword",
                type: "Melee",
                range: "Melee",
                damage: "1d10+2 R",
                penetration: "2",
                clip: "-",
                reload: "-",
                traits: ["Balanced", "Tearing"]
            ),
            WeaponCompendiumDefinition(
                id: "local-demo.combat-shotgun",
                catalogID: "local-demo",
                name: "Combat Shotgun",
                type: "Basic",
                range: "30m",
                damage: "1d10+4 I",
                penetration: "0",
                clip: "8",
                reload: "2 Full",
                traits: ["Scatter"]
            ),
            WeaponCompendiumDefinition(
                id: "local-demo.lasgun",
                catalogID: "local-demo",
                name: "Lasgun",
                type: "Basic",
                range: "100m",
                damage: "1d10+3 E",
                penetration: "0",
                clip: "60",
                reload: "Full",
                traits: ["Reliable"]
            ),
            WeaponCompendiumDefinition(
                id: "local-demo.laspistol",
                catalogID: "local-demo",
                name: "Laspistol",
                type: "Pistol",
                range: "30m",
                damage: "1d10+2 E",
                penetration: "0",
                clip: "30",
                reload: "Half",
                traits: ["Reliable"]
            )
        ]
    )
}

public struct WeaponCompendiumDefinition: Identifiable, Codable, Equatable, Sendable {
    public var id: String
    public var catalogID: String
    public var name: String
    public var type: String
    public var range: String
    public var damage: String
    public var penetration: String
    public var clip: String
    public var reload: String
    public var traits: [String]
    public var notes: String

    public init(
        id: String,
        catalogID: String,
        name: String,
        type: String = "",
        range: String = "",
        damage: String = "",
        penetration: String = "",
        clip: String = "",
        reload: String = "",
        traits: [String] = [],
        notes: String = ""
    ) {
        self.id = id
        self.catalogID = catalogID
        self.name = name
        self.type = type
        self.range = range
        self.damage = damage
        self.penetration = penetration
        self.clip = clip
        self.reload = reload
        self.traits = traits
        self.notes = notes
    }

    public var traitsText: String {
        traits
            .map(trimmedText)
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }

    public var previewLine: String {
        [
            trimmedOrNil(type),
            trimmedOrNil(range),
            trimmedOrNil(damage),
            trimmedOrNil(penetration).map { "Pen \($0)" }
        ]
        .compactMap { $0 }
        .joined(separator: " • ")
    }

    public var supportingLine: String {
        [
            trimmedOrNil(clip).map { "Clip \($0)" },
            trimmedOrNil(reload).map { "Reload \($0)" },
            trimmedOrNil(traitsText)
        ]
        .compactMap { $0 }
        .joined(separator: " • ")
    }

    public func makeWeaponInstance(id: UUID = UUID()) -> Weapon {
        Weapon(
            id: id,
            name: trimmedOrPlaceholder(name, placeholder: "Unnamed Weapon"),
            type: trimmedText(type),
            range: trimmedText(range),
            damage: trimmedText(damage),
            penetration: trimmedText(penetration),
            clip: trimmedText(clip),
            reload: trimmedText(reload),
            traits: trimmedText(traitsText)
        )
    }
}

public protocol WeaponCompendiumRepository: Sendable {
    func fetchCatalog() async throws -> WeaponCompendiumCatalog?
    func saveCatalog(_ catalog: WeaponCompendiumCatalog) async throws
}

public struct WeaponCompendiumUseCases: Sendable {
    private let repository: any WeaponCompendiumRepository

    public init(repository: any WeaponCompendiumRepository) {
        self.repository = repository
    }

    public func currentCatalog() async throws -> WeaponCompendiumCatalog {
        try await repository.fetchCatalog() ?? .demo
    }

    @discardableResult
    public func replaceCatalog(_ catalog: WeaponCompendiumCatalog) async throws -> WeaponCompendiumCatalog {
        try await repository.saveCatalog(catalog)
        return catalog
    }
}

public struct WeaponCompendiumImportPreviewSummary: Equatable, Sendable {
    public let importedCatalogName: String
    public let detectedWeaponCount: Int
    public let existingCatalogName: String
    public let existingWeaponCount: Int

    public init(
        importedCatalogName: String,
        detectedWeaponCount: Int,
        existingCatalogName: String,
        existingWeaponCount: Int
    ) {
        self.importedCatalogName = importedCatalogName
        self.detectedWeaponCount = detectedWeaponCount
        self.existingCatalogName = existingCatalogName
        self.existingWeaponCount = existingWeaponCount
    }

    public var confirmationMessage: String {
        """
        Imported catalog “\(importedCatalogName)” contains \(detectedWeaponCount) \(Self.definitionLabel(count: detectedWeaponCount)).
        This replaces your current local compendium “\(existingCatalogName)” (\(existingWeaponCount) \(Self.definitionLabel(count: existingWeaponCount))); it does not merge.
        Future autocomplete and add-weapon prefills will use the imported catalog.
        Existing character-owned weapons stay detached and unchanged.
        This action is destructive for the current local compendium.
        """
    }

    private static func definitionLabel(count: Int) -> String {
        count == 1 ? "weapon definition" : "weapon definitions"
    }
}

public enum WeaponCompendiumImportError: LocalizedError, Equatable {
    case invalidJSON
    case unsupportedSchemaVersion(Int)
    case invalidCatalogID
    case invalidCatalogDisplayName
    case invalidDefinitionID(index: Int)
    case invalidDefinitionName(index: Int)
    case duplicateDefinitionIDs([String])

    public var errorDescription: String? {
        switch self {
        case .invalidJSON:
            return "Weapon compendium import failed: malformed JSON or unsupported file structure."
        case .unsupportedSchemaVersion(let version):
            return "Weapon compendium import failed: unsupported schema version \(version)."
        case .invalidCatalogID:
            return "Weapon compendium import failed: catalog id is required."
        case .invalidCatalogDisplayName:
            return "Weapon compendium import failed: catalog display name is required."
        case .invalidDefinitionID(let index):
            return "Weapon compendium import failed: definition #\(index + 1) is missing an id."
        case .invalidDefinitionName(let index):
            return "Weapon compendium import failed: definition #\(index + 1) is missing a name."
        case .duplicateDefinitionIDs(let ids):
            let joined = ids.joined(separator: ", ")
            return "Weapon compendium import failed: duplicate definition ids found (\(joined))."
        }
    }
}

public struct WeaponCompendiumJSONImportService: Sendable {
    private let supportedSchemaVersion = 1

    public init() {}

    public func `import`(_ data: Data) throws -> WeaponCompendiumCatalog {
        let decoder = JSONDecoder()
        let envelope: WeaponCompendiumImportEnvelope

        do {
            envelope = try decoder.decode(WeaponCompendiumImportEnvelope.self, from: data)
        } catch {
            throw WeaponCompendiumImportError.invalidJSON
        }

        guard envelope.schemaVersion == supportedSchemaVersion else {
            throw WeaponCompendiumImportError.unsupportedSchemaVersion(envelope.schemaVersion)
        }

        let catalogID = trimmedText(envelope.catalog.id)
        guard !catalogID.isEmpty else {
            throw WeaponCompendiumImportError.invalidCatalogID
        }

        let displayName = trimmedText(envelope.catalog.displayName)
        guard !displayName.isEmpty else {
            throw WeaponCompendiumImportError.invalidCatalogDisplayName
        }

        var seenDefinitionIDs = Set<String>()
        var duplicateDefinitionIDs = Set<String>()
        let definitions = try envelope.catalog.definitions.enumerated().map { index, definition in
            let id = trimmedText(definition.id)
            guard !id.isEmpty else {
                throw WeaponCompendiumImportError.invalidDefinitionID(index: index)
            }

            let normalizedID = id.lowercased()
            if !seenDefinitionIDs.insert(normalizedID).inserted {
                duplicateDefinitionIDs.insert(id)
            }

            let name = trimmedText(definition.name)
            guard !name.isEmpty else {
                throw WeaponCompendiumImportError.invalidDefinitionName(index: index)
            }

            return WeaponCompendiumDefinition(
                id: id,
                catalogID: catalogID,
                name: name,
                type: trimmedText(definition.type ?? ""),
                range: trimmedText(definition.range ?? ""),
                damage: trimmedText(definition.damage ?? ""),
                penetration: trimmedText(definition.penetration ?? ""),
                clip: trimmedText(definition.clip ?? ""),
                reload: trimmedText(definition.reload ?? ""),
                traits: definition.traits ?? [],
                notes: trimmedText(definition.notes ?? "")
            )
        }

        guard duplicateDefinitionIDs.isEmpty else {
            throw WeaponCompendiumImportError.duplicateDefinitionIDs(duplicateDefinitionIDs.sorted())
        }

        return WeaponCompendiumCatalog(
            id: catalogID,
            displayName: displayName,
            definitions: definitions
        )
    }
}

public enum WeaponCompendiumSearch {
    public static func autocomplete(
        definitions: [WeaponCompendiumDefinition],
        query: String,
        limit: Int = 8
    ) -> [WeaponCompendiumDefinition] {
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
    let definition: WeaponCompendiumDefinition
}

private struct WeaponCompendiumImportEnvelope: Codable {
    let schemaVersion: Int
    let catalog: WeaponCompendiumImportCatalog
}

private struct WeaponCompendiumImportCatalog: Codable {
    let id: String
    let displayName: String
    let definitions: [WeaponCompendiumImportDefinition]
}

private struct WeaponCompendiumImportDefinition: Codable {
    let id: String
    let name: String
    let type: String?
    let range: String?
    let damage: String?
    let penetration: String?
    let clip: String?
    let reload: String?
    let traits: [String]?
    let notes: String?
}

private func trimmedText(_ value: String) -> String {
    value.trimmingCharacters(in: .whitespacesAndNewlines)
}

private func trimmedOrNil(_ value: String) -> String? {
    let cleaned = trimmedText(value)
    return cleaned.isEmpty ? nil : cleaned
}

private func trimmedOrPlaceholder(_ value: String, placeholder: String) -> String {
    let cleaned = trimmedText(value)
    return cleaned.isEmpty ? placeholder : cleaned
}
