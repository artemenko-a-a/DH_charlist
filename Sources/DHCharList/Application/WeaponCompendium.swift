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
