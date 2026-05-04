//
//  MealPlanViewModel.swift
//  JisuitaApp
//

import SwiftUI
import Combine

@MainActor
final class MealPlanViewModel: ObservableObject {
    static let shared = MealPlanViewModel()

    @Published var slots: [MealSlot] = [] {
        didSet {
            repository.save(slots)
        }
    }

    private let repository: MealSlotRepositoryProtocol

    private let days = ["月", "火", "水", "木", "金", "土", "日"]
    private let mealTimes = ["朝", "昼", "夜"]

    init(repository: MealSlotRepositoryProtocol = MealSlotRepository.shared) {
        self.repository = repository
        let saved = repository.load()
        if saved.isEmpty {
            self.slots = Self.defaultSlots()
        } else {
            self.slots = saved
        }
    }

    private static func defaultSlots() -> [MealSlot] {
        let days = ["月", "火", "水", "木", "金", "土", "日"]
        let mealTimes = ["朝", "昼", "夜"]
        return days.flatMap { day in
            mealTimes.map { time in
                MealSlot(day: day, mealTime: time)
            }
        }
    }

    func slot(day: String, mealTime: String) -> MealSlot? {
        slots.first { $0.day == day && $0.mealTime == mealTime }
    }

    func updateSlot(_ slot: MealSlot) {
        guard let index = slots.firstIndex(where: { $0.id == slot.id }) else { return }
        slots[index] = slot
    }

    func applyAISuggestions(_ suggestions: [String: String]) {
        for (key, name) in suggestions {
            let parts = key.split(separator: "_").map(String.init)
            guard parts.count == 2,
                  let index = slots.firstIndex(where: { $0.day == parts[0] && $0.mealTime == parts[1] }) else { continue }
            slots[index].name = name
        }
    }

    func resetAll() {
        slots = Self.defaultSlots()
    }
}
