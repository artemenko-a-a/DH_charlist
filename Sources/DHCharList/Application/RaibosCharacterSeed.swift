import Foundation

public enum RaibosCharacterSeed {
    public static let characterID = UUID(uuidString: "00000000-0000-4000-8000-000000002D02")!
    public static let displayName = "Райбос-2 Д-2"

    private static let seedDate = Date(timeIntervalSince1970: 1_778_803_200)
    private static let laspistolID = UUID(uuidString: "00000000-0000-4000-8000-000000001001")!
    private static let lasgunID = UUID(uuidString: "00000000-0000-4000-8000-000000001002")!

    public static var character: Character {
        Character(
            id: characterID,
            profile: Profile(
                name: displayName,
                homeWorld: "Мир-кузница Райбос",
                background: "",
                role: "Хирургеон",
                aptitudes: ["Общая", "Интеллект", "Техно", "Полевое", "Внимательность", "Познание"],
                description: [
                    "Возраст: 27. Пол: М. Комплекция: худой. Кожа: бледная. Волосы: лысый.",
                    "Внесено с бумажного чарника и сверено по пользовательским уточнениям перед игровой сессией."
                ].joined(separator: "\n")
            ),
            characteristics: CharacteristicSet(
                weaponSkill: 31,
                ballisticSkill: 31,
                strength: 30,
                toughness: 40,
                agility: 34,
                intelligence: 52,
                perception: 43,
                willpower: 34,
                fellowship: 22
            ),
            resources: ResourceState(
                currentWounds: 14,
                maxWounds: 14,
                fatigue: 0,
                corruption: 0,
                insanity: 2,
                currentFate: 3,
                maxFate: 3,
                experienceSpent: 0,
                experienceTotal: 0
            ),
            skills: [
                Skill(id: UUID(uuidString: "00000000-0000-4000-8000-000000003001")!, name: "Бдительность", characteristic: .perception, training: .trained),
                Skill(id: UUID(uuidString: "00000000-0000-4000-8000-000000003002")!, name: "Уклонение", characteristic: .agility, training: .known),
                Skill(id: UUID(uuidString: "00000000-0000-4000-8000-000000003003")!, name: "Логика", characteristic: .intelligence, training: .known),
                Skill(id: UUID(uuidString: "00000000-0000-4000-8000-000000003004")!, name: "Медика", characteristic: .intelligence, training: .veteran),
                Skill(id: UUID(uuidString: "00000000-0000-4000-8000-000000003005")!, name: "Управление", characteristic: .agility, training: .known, specialisations: ["Космическое"]),
                Skill(id: UUID(uuidString: "00000000-0000-4000-8000-000000003006")!, name: "Проницательность", characteristic: .perception, training: .known),
                Skill(id: UUID(uuidString: "00000000-0000-4000-8000-000000003007")!, name: "Технопользование", characteristic: .intelligence, training: .veteran),
                Skill(id: UUID(uuidString: "00000000-0000-4000-8000-000000003008")!, name: "Ремесло", characteristic: .intelligence, training: .veteran, specialisations: ["Химик"]),
                Skill(id: UUID(uuidString: "00000000-0000-4000-8000-000000003009")!, name: "Ремесло", characteristic: .intelligence, training: .known, specialisations: ["Оружейник"])
            ],
            notes: NotesState(
                talents: [
                    "Искусный Стук",
                    "Сопротивление (радиация) (+10 сопротивляемость)",
                    "Выучка с Оружием (твердотельное)",
                    "Использование Мехадендритов",
                    "Превосходный Хирургеон (+20 медика)",
                    "Мастер Брони",
                    "Крепкое телосложение (1)",
                    "Импланты Механикус",
                    "Медицинский Мехадендрит (+10 медицина и допрос)",
                    "Оптический Мехадендрит (+10 восприятие)",
                    "Баллистический мехадендрит",
                    "Бионическая дыхательная система (+20 сопротивляемость)",
                    "Монозадачный сервочереп (+10 технопользование)"
                ],
                specialAbilities: [
                    "Замена слабой плоти (кибернетика на 2 уровня ниже)",
                    "Преданный Целитель: можно потратить очко Судьбы для автоматического успеха на проваленной проверке Первой Помощи; степени успеха равны бонусу Интеллекта Хирургеона."
                ],
                notes: [
                    "Оружие из чарника: лазпистолет и лазган. Для обоих прочитана лазерная настройка: Ус: +1 урон, x2 БК; П: +2 урон, +2 пробивание, x4 БК.",
                    "Сверено пользователем: Искусный Стук - корректное название таланта; Преданный Целитель - базовый бонус роли Хирургеона; боезапас лазгана оставлен как 60x3."
                ].joined(separator: "\n")
            ),
            equipment: EquipmentState(
                weapons: [
                    Weapon(
                        id: laspistolID,
                        name: "Лазпистолет",
                        type: "Pistol",
                        range: "30m",
                        damage: "1d10+2 E",
                        penetration: "0",
                        clip: "30",
                        reload: "Free",
                        traits: "Лазерное; Ус: +1 урон, x2 БК; П: +2 урон, +2 пробивание, x4 БК"
                    ),
                    Weapon(
                        id: lasgunID,
                        name: "Лазган",
                        type: "Basic",
                        range: "100m",
                        damage: "1d10+3 E",
                        penetration: "0",
                        clip: "60x3",
                        reload: "Full",
                        traits: "Лазерное; Ус: +1 урон, x2 БК; П: +2 урон, +2 пробивание, x4 БК"
                    )
                ],
                armour: [
                    Armour(id: UUID(uuidString: "00000000-0000-4000-8000-000000002001")!, location: "Голова", armourPoints: 0),
                    Armour(id: UUID(uuidString: "00000000-0000-4000-8000-000000002002")!, location: "Корпус", armourPoints: 4),
                    Armour(id: UUID(uuidString: "00000000-0000-4000-8000-000000002003")!, location: "Правая рука", armourPoints: 7),
                    Armour(id: UUID(uuidString: "00000000-0000-4000-8000-000000002004")!, location: "Левая рука", armourPoints: 7),
                    Armour(id: UUID(uuidString: "00000000-0000-4000-8000-000000002005")!, location: "Правая нога", armourPoints: 3),
                    Armour(id: UUID(uuidString: "00000000-0000-4000-8000-000000002006")!, location: "Левая нога", armourPoints: 3)
                ],
                movement: MovementProfile(halfMove: 3, fullMove: 6, charge: 9, run: 18)
            ),
            session: SessionState(
                pinnedChecks: ["Медика", "Технопользование", "Бдительность", "Проницательность"],
                activeWeaponID: lasgunID
            ),
            history: [
                CharacterHistoryEntry(
                    id: UUID(uuidString: "00000000-0000-4000-8000-000000009001")!,
                    characterID: characterID,
                    createdAt: seedDate,
                    title: "Импортирован бумажный чарник",
                    type: .sessionNote,
                    body: "Персонаж внесен по двум фотографиям бумажного листа Dark Heresy II и уточнен по пользовательской сверке с рульником.",
                    tags: ["import", "paper-sheet"]
                )
            ],
            updatedAt: seedDate
        )
    }

    public static func matches(_ character: Character) -> Bool {
        let normalizedName = character.profile.name.trimmingCharacters(in: .whitespacesAndNewlines)
        return character.id == characterID
            || normalizedName == displayName
            || normalizedName.localizedCaseInsensitiveContains("Райбос")
    }
}

public struct RaibosCharacterSeedBootstrap {
    private let isSeeded: () -> Bool
    private let markSeeded: () -> Void

    public init(isSeeded: @escaping () -> Bool, markSeeded: @escaping () -> Void) {
        self.isSeeded = isSeeded
        self.markSeeded = markSeeded
    }

    public static func standard(userDefaults: UserDefaults = .standard) -> RaibosCharacterSeedBootstrap {
        let key = "dh.raibos.seeded.v1"
        return RaibosCharacterSeedBootstrap(
            isSeeded: { userDefaults.bool(forKey: key) },
            markSeeded: { userDefaults.set(true, forKey: key) }
        )
    }

    public func seedIfNeeded(useCases: CharacterUseCases) async throws {
        guard !isSeeded() else { return }

        let characters = try await useCases.listCharacters()
        if !characters.contains(where: RaibosCharacterSeed.matches) {
            try await useCases.upsertCharacter(RaibosCharacterSeed.character)
        }

        markSeeded()
    }
}
