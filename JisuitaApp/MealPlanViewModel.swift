//
//  MealPlanViewModel.swift
//  JisuitaApp
//
//  Created by 株式会社オフィス岳 on 2026/04/10.
//

import Foundation
import Combine

final class MealPlanViewModel: ObservableObject {

    static let shared = MealPlanViewModel()

    private let persistenceKey = "mealSlots_v1"
    private let calendar = Calendar.current

    @Published var slots: [MealSlot] = [] {
        didSet { save() }
    }

    let days = ["月", "火", "水", "木", "金", "土", "日"]
    let mealTimes = ["朝", "昼", "夜"]

    private init() {
        load()
        if slots.isEmpty {
            slots = buildDefaultSlots()
        }
    }

    // MARK: - Public

    func slot(for day: String, mealTime: String) -> MealSlot {
        slots.first { $0.day == day && $0.mealTime == mealTime }
            ?? MealSlot(day: day, mealTime: mealTime)
    }

    func update(_ updated: MealSlot) {
        guard let idx = slots.firstIndex(where: { $0.id == updated.id }) else { return }
        slots[idx] = updated
    }

    func todaySlots() -> [MealSlot] {
        let day = todayDayString()
        return mealTimes.map { slot(for: day, mealTime: $0) }
    }

    func todayDayString() -> String {
        let weekday = calendar.component(.weekday, from: Date())
        // weekday: 1=日, 2=月, ..., 7=土
        let map = [1: "日", 2: "月", 3: "火", 4: "水", 5: "木", 6: "金", 7: "土"]
        return map[weekday] ?? "月"
    }

    func weekSummary() -> [(day: String, slots: [MealSlot])] {
        days.map { day in
            (day: day, slots: mealTimes.map { slot(for: day, mealTime: $0) })
        }
    }

    // MARK: - Persistence

    private func save() {
        guard let data = try? JSONEncoder().encode(slots) else { return }
        UserDefaults.standard.set(data, forKey: persistenceKey)
    }

    private func load() {
        guard
            let data = UserDefaults.standard.data(forKey: persistenceKey),
            let decoded = try? JSONDecoder().decode([MealSlot].self, from: data)
        else { return }
        slots = decoded
    }

    // MARK: - Default

    private func buildDefaultSlots() -> [MealSlot] {
        var result: [MealSlot] = []
        for day in days {
            for time in mealTimes {
                result.append(MealSlot(day: day, mealTime: time))
            }
        }
        return result
    }
}
