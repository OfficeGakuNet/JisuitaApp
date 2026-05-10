//
//  MealPlanViewModel.swift
//  JisuitaApp
//
//  Created by 株式会社オフィス岳 on 2026/04/10.
//

import SwiftUI
import Combine

enum MealPlanError: LocalizedError {
    case parseError
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .parseError: return "AIの応答を解析できませんでした"
        case .apiError(let msg): return msg
        }
    }
}

final class MealPlanViewModel: ObservableObject {

    static let shared = MealPlanViewModel()

    @Published var slots: [MealSlot] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    private let client: ClaudeAPIClientProtocol
    private let storageKey = "mealPlanSlots"

    private let days = ["月", "火", "水", "木", "金", "土", "日"]
    private let mealTimes = ["朝", "昼", "夜"]

    init(client: ClaudeAPIClientProtocol = ClaudeAPIClient.shared) {
        self.client = client
        loadSlots()
    }

    var todaySlots: [MealSlot] {
        let weekday = Calendar.current.component(.weekday, from: Date())
        let dayIndex = (weekday + 5) % 7
        guard dayIndex < days.count else { return [] }
        let today = days[dayIndex]
        return slots.filter { $0.day == today }
    }

    func fetchAISuggestion(userSettings: UserSettings) async {
        await MainActor.run { isLoading = true; errorMessage = nil }

        let systemPrompt = buildSystemPrompt(userSettings: userSettings)
        let userMessage = buildUserMessage()

        do {
            let response = try await client.send(systemPrompt: systemPrompt, userMessage: userMessage)
            let parsed = parseResponse(response)
            await MainActor.run {
                applyParsedMeals(parsed)
                isLoading = false
                saveSlots()
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }

    private func buildSystemPrompt(userSettings: UserSettings) -> String {
        var lines: [String] = []
        lines.append("あなたはプロの管理栄養士です。ユーザーの情報をもとに1週間の献立を提案してください。")
        lines.append("")
        lines.append("【ユーザー情報】")
        if !userSettings.userName.isEmpty {
            lines.append("名前: \(userSettings.userName)")
        }
        if userSettings.age > 0 {
            lines.append("年齢: \(userSettings.age)歳")
        }
        if userSettings.height > 0 {
            lines.append("身長: \(Int(userSettings.height))cm")
        }
        if userSettings.weight > 0 {
            lines.append("体重: \(Int(userSettings.weight))kg")
        }
        if userSettings.targetWeight > 0 {
            lines.append("目標体重: \(Int(userSettings.targetWeight))kg")
        }
        if !userSettings.dietaryRestrictions.isEmpty {
            lines.append("食の制限・アレルギー: \(userSettings.dietaryRestrictions)")
        }
        if !userSettings.dislikedFoods.isEmpty {
            lines.append("苦手な食材: \(userSettings.dislikedFoods)")
        }
        if !userSettings.preferredCuisines.isEmpty {
            lines.append("好きな料理ジャンル: \(userSettings.preferredCuisines)")
        }
        if userSettings.monthlyFoodBudget > 0 {
            lines.append("月の食費予算: \(userSettings.monthlyFoodBudget)円")
        }
        if userSettings.hasBento {
            lines.append("お弁当: あり")
        }
        lines.append("")
        lines.append("【出力形式】")
        lines.append("必ず以下のJSON形式のみで返答してください。説明文は一切不要です。")
        lines.append("{")
        lines.append("  \"meals\": [")
        lines.append("    {\"day\": \"月\", \"mealTime\": \"朝\", \"name\": \"料理名\"},")
        lines.append("    ...")
        lines.append("  ]")
        lines.append("}")
        lines.append("")
        lines.append("dayは月火水木金土日、mealTimeは朝昼夜のいずれかです。")
        lines.append("固定メニューが設定されているスロットは変更しないでください。")
        lines.append("栄養バランスを考慮し、食材の使い回しができる献立にしてください。")
        return lines.joined(separator: "\n")
    }

    private func buildUserMessage() -> String {
        var lines: [String] = []
        lines.append("今週の献立を提案してください。")
        let fixedSlots = slots.filter { $0.isFixed && $0.name != "未設定" }
        if !fixedSlots.isEmpty {
            lines.append("")
            lines.append("以下は固定メニューです（変更不可）:")
            for slot in fixedSlots {
                lines.append("\(slot.day)曜日 \(slot.mealTime)食: \(slot.name)")
            }
        }
        return lines.joined(separator: "\n")
    }

    private func parseResponse(_ text: String) -> [(day: String, mealTime: String, name: String)] {
        let jsonString: String
        if let start = text.range(of: "{"),
           let end = text.range(of: "}", options: .backwards) {
            let range = start.lowerBound...end.upperBound
            jsonString = String(text[range])
        } else {
            jsonString = text
        }

        guard let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let meals = json["meals"] as? [[String: String]] else {
            return []
        }

        return meals.compactMap { dict in
            guard let day = dict["day"],
                  let mealTime = dict["mealTime"],
                  let name = dict["name"],
                  !name.isEmpty else { return nil }
            return (day: day, mealTime: mealTime, name: name)
        }
    }

    private func applyParsedMeals(_ parsed: [(day: String, mealTime: String, name: String)]) {
        for meal in parsed {
            guard let idx = slots.firstIndex(where: {
                $0.day == meal.day && $0.mealTime == meal.mealTime && !$0.isFixed
            }) else { continue }
            slots[idx].name = meal.name
        }
    }

    func initializeSlotsIfNeeded() {
        guard slots.isEmpty else { return }
        var initial: [MealSlot] = []
        for day in days {
            for time in mealTimes {
                initial.append(MealSlot(day: day, mealTime: time))
            }
        }
        slots = initial
        saveSlots()
    }

    func updateSlot(_ slot: MealSlot) {
        guard let idx = slots.firstIndex(where: { $0.id == slot.id }) else { return }
        slots[idx] = slot
        saveSlots()
    }

    private func saveSlots() {
        guard let data = try? JSONEncoder().encode(slots) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    private func loadSlots() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([MealSlot].self, from: data) else {
            initializeSlotsIfNeeded()
            return
        }
        slots = decoded
        if slots.isEmpty { initializeSlotsIfNeeded() }
    }
}
