//
//  MealPlanViewModel.swift
//  JisuitaApp
//

import Foundation
import SwiftUI

@MainActor
final class MealPlanViewModel: ObservableObject {

    static let shared = MealPlanViewModel()

    @Published var slots: [MealSlot] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let slotsKey = "mealPlanSlots"
    private let apiClient: ClaudeAPIClientProtocol

    private let days = ["月", "火", "水", "木", "金", "土", "日"]
    private let mealTimes = ["朝", "昼", "夜"]

    init(apiClient: ClaudeAPIClientProtocol = ClaudeAPIClient.shared) {
        self.apiClient = apiClient
        self.slots = Self.loadSlots(key: slotsKey) ?? Self.buildDefaultSlots()
    }

    // MARK: - Public

    func applyFixedMenus() {
        let fixedMenus = FixedMenuStore.load().filter { $0.isEnabled }
        for menu in fixedMenus {
            for day in menu.days {
                if let idx = slots.firstIndex(where: { $0.day == day && $0.mealTime == menu.mealTime }) {
                    slots[idx].name = menu.name
                    slots[idx].isFixed = true
                }
            }
        }
        // 固定メニューが外れたスロットを「未設定」に戻す
        let fixedPairs = Set(
            fixedMenus.flatMap { menu in
                menu.days.map { day in "\(day)_\(menu.mealTime)" }
            }
        )
        for idx in slots.indices {
            let key = "\(slots[idx].day)_\(slots[idx].mealTime)"
            if slots[idx].isFixed && !fixedPairs.contains(key) {
                slots[idx].name = "未設定"
                slots[idx].isFixed = false
            }
        }
        saveSlots()
    }

    func generateAIPlan(userSettings: UserSettings) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let targetSlots = slots.filter { !$0.isFixed }
        guard !targetSlots.isEmpty else { return }

        let slotDescriptions = targetSlots.map { "\($0.day)曜日の\($0.mealTime)食" }.joined(separator: "、")
        let systemPrompt = buildSystemPrompt(userSettings: userSettings)
        let userMessage = "以下のスロットに献立を提案してください：\(slotDescriptions)"

        do {
            let response = try await apiClient.send(systemPrompt: systemPrompt, userMessage: userMessage)
            applyAIResponse(response)
            saveSlots()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateSlot(_ slot: MealSlot) {
        guard let idx = slots.firstIndex(where: { $0.id == slot.id }) else { return }
        slots[idx] = slot
        saveSlots()
    }

    func resetSlots() {
        slots = Self.buildDefaultSlots()
        applyFixedMenus()
    }

    // MARK: - Private

    private static func buildDefaultSlots() -> [MealSlot] {
        let days = ["月", "火", "水", "木", "金", "土", "日"]
        let mealTimes = ["朝", "昼", "夜"]
        return days.flatMap { day in
            mealTimes.map { mealTime in
                MealSlot(day: day, mealTime: mealTime)
            }
        }
    }

    private static func loadSlots(key: String) -> [MealSlot]? {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([MealSlot].self, from: data)
        else { return nil }
        return decoded
    }

    private func saveSlots() {
        guard let data = try? JSONEncoder().encode(slots) else { return }
        UserDefaults.standard.set(data, forKey: slotsKey)
    }

    private func applyAIResponse(_ response: String) {
        let lines = response.components(separatedBy: "\n").filter { !$0.isEmpty }
        for line in lines {
            // 「月曜日の朝食：納豆ご飯」のような形式を想定
            let parts = line.components(separatedBy: "：")
            guard parts.count >= 2 else { continue }
            let label = parts[0]
            let mealName = parts[1...].joined(separator: "：")
                .trimmingCharacters(in: .whitespaces)

            for idx in slots.indices where !slots[idx].isFixed {
                let slotLabel = "\(slots[idx].day)曜日の\(slots[idx].mealTime)食"
                if label.contains(slotLabel) || label.contains(slots[idx].day) && label.contains(slots[idx].mealTime) {
                    slots[idx].name = mealName
                }
            }
        }
    }

    private func buildSystemPrompt(userSettings: UserSettings) -> String {
        """
        あなたはプロの管理栄養士です。ユーザーの1週間の献立を提案してください。
        以下の点を考慮してください：
        - 栄養バランスを考慮する
        - 食材の使い回しを意識する
        - 回答は「月曜日の朝食：料理名」の形式で1行ずつ出力する
        - 余計な説明は不要
        """
    }
}
