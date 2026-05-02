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

        let systemPrompt = """
        あなたは家庭料理の献立プランナーです。
        ユーザーの家族構成・予算・食の制限などを考慮した週間献立を作成してください。
        以下のJSON形式のみで返答してください（他のテキスト不要）：
        {
          "slots": [
            {"day": "月", "mealTime": "朝", "name": "料理名"},
            ...
          ]
        }
        曜日は月火水木金土日、食事時間は朝昼夜の組み合わせで21件すべてを含めてください。
        """

        let userMessage = """
        以下の条件で週間献立を提案してください。

        \(personalizedContext)

        21件すべての献立をJSON形式で返してください。
        """

        do {
            let response = try await ClaudeAPIClient.shared.send(
                systemPrompt: systemPrompt,
                userMessage: userMessage
            )
            let newSlots = parseSlotsFromJSON(response)
            if !newSlots.isEmpty {
                slots = newSlots
                saveSlots()
            } else {
                errorMessage = "献立の解析に失敗しました。再試行してください。"
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func parseSlotsFromJSON(_ text: String) -> [MealSlot] {
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let slotsArray = json["slots"] as? [[String: Any]] else {
            return []
        }
        return slotsArray.compactMap { dict in
            guard let day = dict["day"] as? String,
                  let mealTime = dict["mealTime"] as? String,
                  let name = dict["name"] as? String else { return nil }
            return MealSlot(day: day, mealTime: mealTime, name: name, isCooking: true)
        }
    }

    private func defaultSlots() -> [MealSlot] {
        var result: [MealSlot] = []
        for day in days {
            for mealTime in mealTimes {
                result.append(MealSlot(day: day, mealTime: mealTime))
            }
        }
        return result
    }

    private func saveSlots() {
        if let data = try? JSONEncoder().encode(slots) {
            UserDefaults.standard.set(data, forKey: slotsKey)
        }
    }
}
