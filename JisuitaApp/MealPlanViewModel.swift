//
//  MealPlanViewModel.swift
//  JisuitaApp
//

import Foundation
import Combine

private let mealSlotsKey = "mealSlots"

final class MealPlanViewModel: ObservableObject {

    static let days = ["月", "火", "水", "木", "金", "土", "日"]
    static let mealTimes = ["朝", "昼", "夜"]

    @Published var slots: [MealSlot] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    init() {
        load()
        if slots.isEmpty { resetToDefault() }
    }

    func slot(day: String, mealTime: String) -> MealSlot? {
        slots.first { $0.day == day && $0.mealTime == mealTime }
    }

    func update(_ slot: MealSlot) {
        if let idx = slots.firstIndex(where: { $0.id == slot.id }) {
            slots[idx] = slot
        } else {
            slots.append(slot)
        }
        save()
    }

    func generateWithClaude(userProfile: String) async {
        await MainActor.run { isLoading = true; errorMessage = nil }

        let systemPrompt = """
        あなたは栄養バランスを考慮した献立作成アシスタントです。
        以下のJSON形式のみで1週間分（月〜日）×3食（朝・昼・夜）の献立を返してください。
        他のテキストは一切含めないでください。
        フォーマット例:
        [
          {"day":"月","mealTime":"朝","name":"料理名","isCooking":true},
          ...
        ]
        """
        let userMessage = "ユーザー情報: \(userProfile)\n1週間分の献立を提案してください。"

        do {
            let raw = try await ClaudeAPIClient.shared.send(systemPrompt: systemPrompt, userMessage: userMessage)
            let parsed = try parseMealSlots(from: raw)
            await MainActor.run {
                self.mergeSlots(parsed)
                self.save()
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }

    private func parseMealSlots(from text: String) throws -> [MealSlot] {
        let jsonString: String
        if let start = text.range(of: "["), let end = text.range(of: "]", options: .backwards) {
            jsonString = String(text[start.lowerBound...end.upperBound])
        } else {
            jsonString = text
        }
        guard let data = jsonString.data(using: .utf8) else { throw APIError.decodeError }
        let decoded = try JSONDecoder().decode([MealSlotDTO].self, from: data)
        return decoded.map { MealSlot(day: $0.day, mealTime: $0.mealTime, name: $0.name, isCooking: $0.isCooking) }
    }

    private func mergeSlots(_ newSlots: [MealSlot]) {
        for new in newSlots {
            if let idx = slots.firstIndex(where: { $0.day == new.day && $0.mealTime == new.mealTime }) {
                slots[idx] = new
            } else {
                slots.append(new)
            }
        }
    }

    func resetToDefault() {
        var result: [MealSlot] = []
        for day in Self.days {
            for mealTime in Self.mealTimes {
                result.append(MealSlot(day: day, mealTime: mealTime, name: "未設定", isCooking: true))
            }
        }
        slots = result
        save()
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(slots) else { return }
        UserDefaults.standard.set(data, forKey: mealSlotsKey)
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: mealSlotsKey),
              let decoded = try? JSONDecoder().decode([MealSlot].self, from: data) else { return }
        slots = decoded
    }
}

private struct MealSlotDTO: Codable {
    let day: String
    let mealTime: String
    let name: String
    let isCooking: Bool
}
