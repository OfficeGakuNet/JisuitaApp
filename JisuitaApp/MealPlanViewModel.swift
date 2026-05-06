import SwiftUI
import Combine

@MainActor
final class MealPlanViewModel: ObservableObject {
    static let shared = MealPlanViewModel()

    @Published var slots: [MealSlot] = []
    @AppStorage("fixedMenus") private var fixedMenusData: Data = Data()

    private let days = ["月", "火", "水", "木", "金", "土", "日"]
    private let mealTimes = ["朝", "昼", "夜"]

    private init() {
        slots = defaultSlots()
    }

    func reloadWithFixedMenus() {
        slots = defaultSlots()
    }

    private func fixedMenus() -> [FixedMenu] {
        (try? JSONDecoder().decode([FixedMenu].self, from: fixedMenusData)) ?? []
    }

    func defaultSlots() -> [MealSlot] {
        let menus = fixedMenus()
        var result: [MealSlot] = []
        for day in days {
            for mealTime in mealTimes {
                let matched = menus.first(where: { $0.isEnabled && $0.mealTime == mealTime && $0.days.contains(day) })
                let name = matched?.name ?? "未設定"
                result.append(MealSlot(day: day, mealTime: mealTime, name: name))
            }
        }
        return result
    }

    func isFixedSlot(day: String, mealTime: String) -> Bool {
        let menus = fixedMenus()
        return menus.contains(where: { $0.isEnabled && $0.mealTime == mealTime && $0.days.contains(day) })
    }

    func slotsForAISuggestion() -> [MealSlot] {
        slots.filter { !isFixedSlot(day: $0.day, mealTime: $0.mealTime) }
    }

    func applyAIResult(_ updatedSlots: [MealSlot]) {
        for updated in updatedSlots {
            if let index = slots.firstIndex(where: { $0.day == updated.day && $0.mealTime == updated.mealTime }) {
                if !isFixedSlot(day: updated.day, mealTime: updated.mealTime) {
                    slots[index] = updated
                }
            }
        }
    }

    func updateSlot(_ slot: MealSlot) {
        if let index = slots.firstIndex(where: { $0.id == slot.id }) {
            slots[index] = slot
        }
    }
}
