//
//  MealPlanViewModel.swift
//  JisuitaApp
//
//  Created by 株式会社オフィス岳 on 2026/04/10.
//

import Foundation
import Combine

enum MealPlanError: LocalizedError {
    case network(Error)
    case api(String)
    case parse
    case unknown

    var errorDescription: String? {
        switch self {
        case .network(let e): return "通信エラー: \(e.localizedDescription)"
        case .api(let msg): return "APIエラー: \(msg)"
        case .parse: return "献立の解析に失敗しました"
        case .unknown: return "不明なエラーが発生しました"
        }
    }
}

@MainActor
final class MealPlanViewModel: ObservableObject {

    static let shared = MealPlanViewModel()

    @Published var slots: [MealSlot] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    private let client: ClaudeAPIClientProtocol
    private let saveKey = "mealPlanSlots"

    private let days = ["月", "火", "水", "木", "金", "土", "日"]
    private let mealTimes = ["朝", "昼", "夜"]

    init(client: ClaudeAPIClientProtocol = ClaudeAPIClient.shared) {
        self.client = client
        load()
    }

    // MARK: - Persistence

    private func load() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([MealSlot].self, from: data) {
            slots = decoded
        } else {
            slots = defaultSlots()
        }
    }

    func save() {
        if let data = try? JSONEncoder().encode(slots) {
            UserDefaults.standard.set(data, forKey: saveKey)
        }
    }

    private func defaultSlots() -> [MealSlot] {
        days.flatMap { day in
            mealTimes.map { time in
                MealSlot(day: day, mealTime: time)
            }
        }
    }

    // MARK: - Slot Access

    func slot(day: String, mealTime: String) -> MealSlot? {
        slots.first { $0.day == day && $0.mealTime == mealTime }
    }

    func updateSlot(_ updated: MealSlot) {
        if let idx = slots.firstIndex(where: { $0.id == updated.id }) {
            slots[idx] = updated
            save()
        }
    }

    // MARK: - AI提案

    func fetchAISuggestion(userSettings: UserSettings) async {
        isLoading = true
        errorMessage = nil

        let systemPrompt = buildSystemPrompt(userSettings: userSettings)
        let userMessage = buildUserMessage()

        do {
            let responseText = try await client.send(systemPrompt: systemPrompt, userMessage: userMessage)
            applyParsedMeals(from: responseText)
            save()
        } catch let e as APIError {
            switch e {
            case .network(let underlying):
                errorMessage = MealPlanError.network(underlying).errorDescription
            case .apiError(let msg):
                errorMessage = MealPlanError.api(msg).errorDescription
            case .decodeError:
                errorMessage = MealPlanError.parse.errorDescription
            default:
                errorMessage = MealPlanError.unknown.errorDescription
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Prompt Building

    private func buildSystemPrompt(userSettings: UserSettings) -> String {
        var lines: [String] = [
            "あなたはプロの管理栄養士です。ユーザーの情報に基づいて、1週間分の献立を提案してください。",
            "",
            "【ユーザー情報】"
        ]

        if !userSettings.name.isEmpty {
            lines.append("名前: \(userSettings.name)")
        }
        if userSettings.age > 0 {
            lines.append("年齢: \(userSettings.age)歳")
        }
        if userSettings.height > 0 {
            lines.append("身長: \(Int(userSettings.height))cm")
        }
        if userSettings.targetWeight > 0 {
            lines.append("目標体重: \(String(format: "%.1f", userSettings.targetWeight))kg")
        }
        if !userSettings.dietaryRestrictions.isEmpty {
            lines.append("食の制限・アレルギー: \(userSettings.dietaryRestrictions)")
        }
        if !userSettings.favoriteGenres.isEmpty {
            lines.append("好きな料理ジャンル: \(userSettings.favoriteGenres.joined(separator: "、"))")
        }
        if !userSettings.dislikedFoods.isEmpty {
            lines.append("苦手な食材: \(userSettings.dislikedFoods)")
        }
        if userSettings.monthlyFoodBudget > 0 {
            lines.append("月の食費予算: \(userSettings.monthlyFoodBudget)円")
        }
        if userSettings.bringLunch {
            lines.append("お弁当持参: あり（平日昼はお弁当向けメニューを提案）")
        }

        lines.append("")
        lines.append("【出力形式】")
        lines.append("以下のフォーマットで厳密に出力してください。余分な説明は不要です。")
        lines.append("月曜日の朝食: 料理名")
        lines.append("月曜日の昼食: 料理名")
        lines.append("月曜日の夕食: 料理名")
        lines.append("（以下同様に火〜日まで）")
        lines.append("")
        lines.append("料理名は日本語で、シンプルな名前にしてください。例：「鮭の塩焼き定食」「豚肉の生姜焼き」")
        lines.append("固定メニューとしてマークされているスロットはそのままにしてください。")

        return lines.joined(separator: "\n")
    }

    private func buildUserMessage() -> String {
        let fixedSlots = slots.filter { $0.isFixed }
        var message = "今週の献立を提案してください。"

        if !fixedSlots.isEmpty {
            message += "\n\n固定メニュー（変更不可）:\n"
            for slot in fixedSlots {
                message += "\(slot.day)曜日の\(slot.mealTime)食: \(slot.name)\n"
            }
        }

        message += "\n月曜〜日曜の朝食・昼食・夕食、合計21食分を提案してください。"
        return message
    }

    // MARK: - Parse

    private func applyParsedMeals(from text: String) {
        let dayMap: [String: String] = [
            "月曜日": "月", "火曜日": "火", "水曜日": "水", "木曜日": "木",
            "金曜日": "金", "土曜日": "土", "日曜日": "日",
            "月": "月", "火": "火", "水": "水", "木": "木",
            "金": "金", "土": "土", "日": "日"
        ]
        let mealTimeMap: [String: String] = [
            "朝食": "朝", "昼食": "昼", "夕食": "夜", "夜食": "夜",
            "朝": "朝", "昼": "昼", "夜": "夜"
        ]

        let lines = text.components(separatedBy: .newlines)

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard trimmed.contains(":") || trimmed.contains("：") else { continue }

            let parts = trimmed
                .replacingOccurrences(of: "：", with: ":")
                .components(separatedBy: ":")
            guard parts.count >= 2 else { continue }

            let key = parts[0].trimmingCharacters(in: .whitespaces)
            let mealName = parts[1...].joined(separator: ":").trimmingCharacters(in: .whitespaces)
            guard !mealName.isEmpty else { continue }

            var matchedDay: String? = nil
            var matchedTime: String? = nil

            for (pattern, dayVal) in dayMap {
                if key.contains(pattern) {
                    matchedDay = dayVal
                    break
                }
            }
            for (pattern, timeVal) in mealTimeMap {
                if key.contains(pattern) {
                    matchedTime = timeVal
                    break
                }
            }

            guard let day = matchedDay, let time = matchedTime else { continue }

            if let idx = slots.firstIndex(where: { $0.day == day && $0.mealTime == time && !$0.isFixed }) {
                slots[idx].name = mealName
            }
        }
    }

    func resetSlots() {
        let fixedSlots = slots.filter { $0.isFixed }
        slots = defaultSlots()
        for fixed in fixedSlots {
            if let idx = slots.firstIndex(where: { $0.day == fixed.day && $0.mealTime == fixed.mealTime }) {
                slots[idx] = fixed
            }
        }
        save()
    }
}
