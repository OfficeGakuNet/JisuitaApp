import SwiftUI
import Combine

@MainActor
final class MealPlanViewModel: ObservableObject {
    static let shared = MealPlanViewModel()

    @Published var slots: [MealSlot] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    private let days = ["月", "火", "水", "木", "金", "土", "日"]
    private let mealTimes = ["朝", "昼", "夜"]
    private let slotsKey = "mealPlanSlots"

    private init() {
        if let data = UserDefaults.standard.data(forKey: slotsKey),
           let saved = try? JSONDecoder().decode([MealSlot].self, from: data) {
            slots = saved
        } else {
            slots = defaultSlots()
        }
        applyFixedMenus()
    }

    func reloadFixedMenus() {
        applyFixedMenus()
    }

    private func applyFixedMenus() {
        let fixedMenus: [FixedMenu]
        if let data = UserDefaults.standard.data(forKey: "fixedMenus"),
           let decoded = try? JSONDecoder().decode([FixedMenu].self, from: data), !decoded.isEmpty {
            fixedMenus = decoded
        } else {
            fixedMenus = [FixedMenu(name: "ヨーグルト・バナナ", mealTime: "朝",
                                    days: ["月", "火", "水", "木", "金"], isEnabled: true)]
        }
        for i in slots.indices {
            let match = fixedMenus.first {
                $0.isEnabled && $0.mealTime == slots[i].mealTime && $0.days.contains(slots[i].day)
            }
            if let fixed = match {
                slots[i].name = fixed.name
                slots[i].isFixed = true
                slots[i].isCooking = true
            } else if slots[i].isFixed {
                slots[i].name = "未設定"
                slots[i].isFixed = false
            }
        }
        saveSlots()
    }

    func resetMealPlan() {
        for i in slots.indices where !slots[i].isFixed {
            slots[i].name = "未設定"
            slots[i].isCooking = true
        }
        applyFixedMenus()
    }

    func slot(for day: String, mealTime: String) -> MealSlot? {
        slots.first { $0.day == day && $0.mealTime == mealTime }
    }

    func toggleCooking(for day: String, mealTime: String) {
        guard let index = slots.firstIndex(where: { $0.day == day && $0.mealTime == mealTime }) else { return }
        slots[index].isCooking.toggle()
        saveSlots()
    }

    func generateMealPlan(personalizedContext: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let targetSlots = slots.filter { $0.isCooking && !$0.isFixed }
        guard !targetSlots.isEmpty else { isLoading = false; return }
        let slotList = targetSlots.map { "\($0.day)\($0.mealTime)" }.joined(separator: "、")

        let systemPrompt = """
        あなたは家庭料理の献立プランナーです。
        以下のJSON形式のみで返答してください（他のテキスト不要）：
        {"slots": [{"day": "月", "mealTime": "朝", "name": "料理名"}, ...]}
        """

        let userMessage = """
        以下の条件で、指定されたスロットのみ献立を提案してください。

        \(personalizedContext)

        提案対象スロット：\(slotList)
        対象スロット数：\(targetSlots.count)件のみJSON形式で返してください。
        """

        do {
            let response = try await ClaudeAPIClient.shared.send(
                systemPrompt: systemPrompt,
                userMessage: userMessage
            )
            let newSlots = parseSlotsFromJSON(response)
            if !newSlots.isEmpty {
                for new in newSlots {
                    if let index = slots.firstIndex(where: { $0.day == new.day && $0.mealTime == new.mealTime && !$0.isFixed }) {
                        slots[index].name = new.name
                    }
                }
                saveSlots()
            } else {
                errorMessage = "献立の解析に失敗しました。再試行してください。"
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func parseSlotsFromJSON(_ text: String) -> [MealSlot] {
        let clean = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let data = clean.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let slotsArray = json["slots"] as? [[String: Any]] else { return [] }
        return slotsArray.compactMap { dict in
            guard let day = dict["day"] as? String,
                  let mealTime = dict["mealTime"] as? String,
                  let name = dict["name"] as? String else { return nil }
            return MealSlot(day: day, mealTime: mealTime, name: name, isCooking: true)
        }
    }

    private func defaultSlots() -> [MealSlot] {
        days.flatMap { day in mealTimes.map { MealSlot(day: day, mealTime: $0) } }
    }

    private func saveSlots() {
        if let data = try? JSONEncoder().encode(slots) {
            UserDefaults.standard.set(data, forKey: slotsKey)
        }
    }
}
