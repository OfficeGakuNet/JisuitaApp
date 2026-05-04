//
//  MealSlotRepository.swift
//  JisuitaApp
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
        guard let data = UserDefaults.standard.data(forKey: key),
              let slots = try? decoder.decode([MealSlot].self, from: data) else {
            return []
        }
        return slots
    }

    func save(_ slots: [MealSlot]) {
        guard let data = try? encoder.encode(slots) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
