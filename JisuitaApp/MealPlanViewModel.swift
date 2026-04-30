//
//  MealPlanViewModel.swift
//  JisuitaApp
//

import Foundation
import Combine

final class MealPlanViewModel: ObservableObject {

    static let shared = MealPlanViewModel()

    @Published var slots: [MealSlot] = []

    private let storageKey = "mealSlots"
    private let days = ["月", "火", "水", "木", "金", "土", "日"]
    private let mealTimes = ["朝", "昼", "夜"]

    private init() {
        load()
        if slots.isEmpty {
            slots = defaultSlots()
            save()
        }
    }

    func slot(day: String, mealTime: String) -> MealSlot? {
        slots.first { $0.day == day && $0.mealTime == mealTime }
    }

    func todaySlots() -> [MealSlot] {
        let weekday = todayWeekdayString()
        return mealTimes.compactMap { time in
            slot(day: weekday, mealTime: time)
        }
    }

    func update(_ updated: MealSlot) {
        guard let index = slots.firstIndex(where: { $0.id == updated.id }) else { return }
        slots[index] = updated
        save()
    }

    func updateName(day: String, mealTime: String, name: String) {
        guard let index = slots.firstIndex(where: { $0.day == day && $0.mealTime == mealTime }) else { return }
        slots[index].name = name
        save()
    }

    func applyAISuggestions(_ suggestions: [(day: String, mealTime: String, name: String)]) {
        for suggestion in suggestions {
            if let index = slots.firstIndex(where: { $0.day == suggestion.day && $0.mealTime == suggestion.mealTime }) {
                slots[index].name = suggestion.name
            }
        }
        save()
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(slots) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    private func load() {
        guard
            let data = UserDefaults.standard.data(forKey: storageKey),
            let decoded = try? JSONDecoder().decode([MealSlot].self, from: data)
        else { return }
        slots = decoded
    }

    private func defaultSlots() -> [MealSlot] {
        days.flatMap { day in
            mealTimes.map { time in
                MealSlot(day: day, mealTime: time)
            }
        }
    }

    private func todayWeekdayString() -> String {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "ja_JP")
        fmt.dateFormat = "E"
        let raw = fmt.string(from: Date())
        let map = ["月": "月", "火": "火", "水": "水", "木": "木", "金": "金", "土": "土", "日": "日"]
        return map[raw] ?? raw
    }
}
