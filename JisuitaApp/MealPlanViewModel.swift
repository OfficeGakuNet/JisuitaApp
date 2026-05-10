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

    @Published var slots: [MealSlot] = [] {
        didSet { repository.save(slots) }
    }

    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    private let repository: MealSlotRepositoryProtocol
    private let apiClient: ClaudeAPIClientProtocol

    init(
        repository: MealSlotRepositoryProtocol = MealSlotRepository.shared,
        apiClient: ClaudeAPIClientProtocol = ClaudeAPIClient.shared
    ) {
        self.repository = repository
        self.apiClient = apiClient
        self.slots = repository.load()
        if slots.isEmpty { slots = Self.defaultSlots() }
    }

    var days: [String] { ["月", "火", "水", "木", "金", "土", "日"] }
    var mealTimes: [String] { ["朝", "昼", "夜"] }

    func slot(day: String, mealTime: String) -> MealSlot? {
        slots.first { $0.day == day && $0.mealTime == mealTime }
    }

    func update(_ slot: MealSlot) {
        guard let idx = slots.firstIndex(where: { $0.id == slot.id }) else { return }
        slots[idx] = slot
    }

    func regenerateWithAI(userSettings: UserSettings) async {
        await MainActor.run { isLoading = true; errorMessage = nil }
        do {
            let prompt = buildSystemPrompt(userSettings: userSettings)
            let user = buildUserMessage()
            let raw = try await apiClient.send(systemPrompt: prompt, userMessage: user)
            let parsed = try parseMealSlots(from: raw)
            await MainActor.run {
                let fixed = slots.filter { $0.isFixed }
                var merged = parsed
                for f in fixed {
                    if let idx = merged.firstIndex(where: { $0.day == f.day && $0.mealTime == f.mealTime }) {
                        merged[idx] = f
                    }
                }
                slots = merged
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }

    private func buildSystemPrompt(userSettings: UserSettings) -> String {
        """
        あなたはAI管理栄養士です。ユーザーの設定に合わせて1週間（月〜日）の朝・昼・夜の献立を提案してください。
        レスポンスは必ずJSON配列形式で返してください。
        形式: [{"day":"月","mealTime":"朝","name":"料理名","isCooking":true,"memo":"補足"},...]
        - isCooking が false の場合は外食・テイクアウト扱い
        - memo は任意（空文字可）
        - isFixed は含めなくてよい
        """
    }

    private func buildUserMessage() -> String {
        "今週の献立を提案してください。"
    }

    private func parseMealSlots(from raw: String) throws -> [MealSlot] {
        let jsonString: String
        if let start = raw.range(of: "["), let end = raw.range(of: "]", options: .backwards) {
            jsonString = String(raw[start.lowerBound...end.upperBound])
        } else {
            throw APIError.decodeError
        }
        guard let data = jsonString.data(using: .utf8) else { throw APIError.decodeError }

        struct RawSlot: Decodable {
            var day: String
            var mealTime: String
            var name: String
            var isCooking: Bool?
            var memo: String?
        }
        let raws = try JSONDecoder().decode([RawSlot].self, from: data)
        return raws.map {
            MealSlot(
                day: $0.day,
                mealTime: $0.mealTime,
                name: $0.name,
                isCooking: $0.isCooking ?? true,
                isFixed: false,
                memo: $0.memo ?? ""
            )
        }
    }

    private static func defaultSlots() -> [MealSlot] {
        let days = ["月", "火", "水", "木", "金", "土", "日"]
        let times = ["朝", "昼", "夜"]
        return days.flatMap { day in
            times.map { time in MealSlot(day: day, mealTime: time) }
        }
    }
}
