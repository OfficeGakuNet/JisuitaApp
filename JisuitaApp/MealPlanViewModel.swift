//
//  MealPlanViewModel.swift
//  JisuitaApp
//
//  Created by 株式会社オフィス岳 on 2026/04/10.
//

import SwiftUI
import Combine

final class MealPlanViewModel: ObservableObject {

    static let shared = MealPlanViewModel()

    @Published var slots: [MealSlot] = []
    @Published var isLoadingAI = false
    @Published var aiError: String? = nil

    private let apiClient: ClaudeAPIClientProtocol
    private let slotsKey = "mealPlanSlots"

    let days = ["月", "火", "水", "木", "金", "土", "日"]
    let mealTimes = ["朝", "昼", "夜"]

    init(apiClient: ClaudeAPIClientProtocol = ClaudeAPIClient.shared) {
        self.apiClient = apiClient
        loadSlots()
    }

    // MARK: - Persistence

    private func loadSlots() {
        if let data = UserDefaults.standard.data(forKey: slotsKey),
           let decoded = try? JSONDecoder().decode([MealSlot].self, from: data) {
            slots = decoded
        } else {
            slots = generateDefaultSlots()
        }
    }

    func saveSlots() {
        if let data = try? JSONEncoder().encode(slots) {
            UserDefaults.standard.set(data, forKey: slotsKey)
        }
    }

    private func generateDefaultSlots() -> [MealSlot] {
        days.flatMap { day in
            mealTimes.map { time in
                MealSlot(day: day, mealTime: time)
            }
        }
    }

    func slot(for day: String, mealTime: String) -> MealSlot? {
        slots.first { $0.day == day && $0.mealTime == mealTime }
    }

    func updateSlot(_ updated: MealSlot) {
        if let idx = slots.firstIndex(where: { $0.id == updated.id }) {
            slots[idx] = updated
            saveSlots()
        }
    }

    // MARK: - AI提案

    func requestAISuggestion(
        refrigeratorItems: [String],
        budgetRemaining: Int,
        mealHistory: [String]
    ) async {
        await MainActor.run {
            isLoadingAI = true
            aiError = nil
        }

        let systemPrompt = buildSystemPrompt()
        let userMessage = buildUserMessage(
            refrigeratorItems: refrigeratorItems,
            budgetRemaining: budgetRemaining,
            mealHistory: mealHistory
        )

        do {
            let responseText = try await apiClient.send(
                systemPrompt: systemPrompt,
                userMessage: userMessage
            )
            let parsed = parseAIResponse(responseText)
            await MainActor.run {
                applyParsedMeals(parsed)
                isLoadingAI = false
            }
        } catch let error as APIError {
            await MainActor.run {
                aiError = error.localizedDescription
                isLoadingAI = false
            }
        } catch {
            await MainActor.run {
                aiError = "AI提案の取得に失敗しました"
                isLoadingAI = false
            }
        }
    }

    private func buildSystemPrompt() -> String {
        """
        あなたはプロの管理栄養士AIです。
        ユーザーの冷蔵庫の在庫・食費予算・過去の献立履歴をもとに、
        1週間分（月〜日）の朝・昼・夜の献立を提案してください。

        【出力形式】
        以下のフォーマットで出力してください。他の文章は不要です。
        月_朝:料理名
        月_昼:料理名
        月_夜:料理名
        火_朝:料理名
        火_昼:料理名
        火_夜:料理名
        水_朝:料理名
        水_昼:料理名
        水_夜:料理名
        木_朝:料理名
        木_昼:料理名
        木_夜:料理名
        金_朝:料理名
        金_昼:料理名
        金_夜:料理名
        土_朝:料理名
        土_昼:料理名
        土_夜:料理名
        日_朝:料理名
        日_昼:料理名
        日_夜:料理名

        【制約】
        - 在庫食材を優先的に使い切る献立にする
        - 予算内に収まる食材コストを意識する
        - 同じ料理が連続しないようにする
        - 栄養バランスを考慮する
        - 料理名のみ出力し、説明文は不要
        """
    }

    private func buildUserMessage(
        refrigeratorItems: [String],
        budgetRemaining: Int,
        mealHistory: [String]
    ) -> String {
        let itemsText = refrigeratorItems.isEmpty ? "なし" : refrigeratorItems.joined(separator: "、")
        let historyText = mealHistory.isEmpty ? "なし" : mealHistory.prefix(10).joined(separator: "、")

        return """
        【冷蔵庫の在庫】
        \(itemsText)

        【今月の食費予算残高】
        ¥\(budgetRemaining.formatted())

        【最近食べた献立（重複を避けてください）】
        \(historyText)

        上記の情報をもとに今週1週間の献立を提案してください。
        """
    }

    private func parseAIResponse(_ text: String) -> [String: String] {
        var result: [String: String] = [:]
        let lines = text.components(separatedBy: .newlines)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }
            let parts = trimmed.components(separatedBy: ":")
            guard parts.count >= 2 else { continue }
            let key = parts[0].trimmingCharacters(in: .whitespaces)
            let value = parts[1...].joined(separator: ":").trimmingCharacters(in: .whitespaces)
            if !key.isEmpty && !value.isEmpty {
                result[key] = value
            }
        }
        return result
    }

    private func applyParsedMeals(_ parsed: [String: String]) {
        for (key, mealName) in parsed {
            let components = key.components(separatedBy: "_")
            guard components.count == 2 else { continue }
            let day = components[0]
            let mealTime = components[1]
            if let idx = slots.firstIndex(where: { $0.day == day && $0.mealTime == mealTime && !$0.isFixed }) {
                slots[idx].name = mealName
            }
        }
        saveSlots()
    }
}
