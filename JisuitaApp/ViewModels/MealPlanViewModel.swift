import SwiftUI
import Combine

@MainActor
final class MealPlanViewModel: ObservableObject {
    static let shared = MealPlanViewModel()

    private let days = ["月", "火", "水", "木", "金", "土", "日"]
    private let mealTimes = ["朝", "昼", "夜"]
    private let storageKey = "mealPlanSlots"

    @Published var slots: [MealSlot] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private init() {
        load()
        if slots.isEmpty { initializeSlots() }
    }

    private func initializeSlots() {
        slots = days.flatMap { day in
            mealTimes.map { time in
                MealSlot(day: day, mealTime: time)
            }
        }
        save()
    }

    func slot(for day: String, mealTime: String) -> MealSlot? {
        slots.first { $0.day == day && $0.mealTime == mealTime }
    }

    func updateSlot(_ updated: MealSlot) {
        if let idx = slots.firstIndex(where: { $0.id == updated.id }) {
            slots[idx] = updated
            save()
        }
    }

    func suggestMeals(userPreferences: String) async {
        isLoading = true
        errorMessage = nil

        let systemPrompt = """
        あなたは家庭料理の献立提案AIです。
        ユーザーの好みや条件に合わせて、1週間分の昼・夜の献立を提案してください。
        朝食は固定メニューがあるため提案不要です。
        返答は以下のJSON形式のみで返してください（説明文不要）:
        [
          {"day": "月", "mealTime": "昼", "name": "料理名"},
          {"day": "月", "mealTime": "夜", "name": "料理名"},
          ...
        ]
        """

        let userMessage = userPreferences.isEmpty
            ? "バランスの良い1週間の献立を提案してください"
            : userPreferences

        do {
            let response = try await ClaudeAPIClient.shared.send(
                systemPrompt: systemPrompt,
                userMessage: userMessage
            )
            applyAISuggestions(from: response)
            save()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func applyAISuggestions(from json: String) {
        let cleaned = extractJSON(from: json)
        guard let data = cleaned.data(using: .utf8) else { return }

        struct SuggestedMeal: Codable {
            let day: String
            let mealTime: String
            let name: String
        }

        guard let suggestions = try? JSONDecoder().decode([SuggestedMeal].self, from: data) else { return }

        for suggestion in suggestions {
            if let idx = slots.firstIndex(where: { $0.day == suggestion.day && $0.mealTime == suggestion.mealTime }) {
                slots[idx].name = suggestion.name
                slots[idx].isCooking = true
            }
        }
    }

    private func extractJSON(from text: String) -> String {
        if let start = text.range(of: "["),
           let end = text.range(of: "]", options: .backwards) {
            return String(text[start.lowerBound...end.upperBound])
        }
        return text
    }

    private func save() {
        if let data = try? JSONEncoder().encode(slots) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let saved = try? JSONDecoder().decode([MealSlot].self, from: data) {
            slots = saved
        }
    }
}
