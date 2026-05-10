//
//  MealSlotRepository.swift
//  JisuitaApp
//
//  Created by 株式会社オフィス岳 on 2026/04/10.
//

import Foundation

protocol MealSlotRepositoryProtocol {
    func load() -> [MealSlot]
    func save(_ slots: [MealSlot])
}

final class MealSlotRepository: MealSlotRepositoryProtocol {

    static let shared = MealSlotRepository()

    private let key = "mealSlots"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init() {}

    func load() -> [MealSlot] {
        guard let data = UserDefaults.standard.data(forKey: key) else { return [] }
        return (try? decoder.decode([MealSlot].self, from: data)) ?? []
    }

    func save(_ slots: [MealSlot]) {
        guard let data = try? encoder.encode(slots) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
