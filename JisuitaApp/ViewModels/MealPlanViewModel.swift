//
//  MealPlanViewModel.swift
//  JisuitaApp
//
//  Created by 株式会社オフィス岳 on 2026/04/10.
//

import Foundation
import Combine

final class MealPlanViewModel: ObservableObject {
    static let shared = MealPlanViewModel()

    @Published var slots: [MealSlot] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    private let slotsKey = "mealSlots"
    private let apiClient: ClaudeAPIClientProtocol

    private let days = ["月", "火", "水", "木", "金", "土", "日"]
    private let mealTimes = ["朝", "昼", "夜"]

    init(apiClient: ClaudeAPIClientProtocol = ClaudeAPIClient.shared) {
        self.apiClient = apiClient
        loadSlots()
    }

    // MARK: - Slot Initialization

    func defaultSlots() -> [MealSlot] {
        let fixedMenus = FixedMenuStore.load().filter { $0.isEnabled }
        var result: [MealSlot] = []

        for day in days {
            for mealTime in mealTimes {
                let fixedMenu = fixedMenus.first { menu in
                    menu.mealTime == mealTime && menu.days.contains(day)
                }

                if let menu = fixedMenu {
                    result.append(MealSlot(
                        day: day,
                        mealTime: mealTime,
                        name: menu.name,
                        isCooking: true,
                        isFixed: true,
                        memo: ""
                    ))
                } else {
                    result.append(MealSlot(
                        day: day,
                        mealTime: mealTime,
                        name: "未設定",
                        isCooking: true,
                        isFixed: false,
                        memo: ""
                    ))
                }
            }
        }

        return result
    }

    func applyFixedMenus() {
        let fixedMenus = FixedMenuStore.load().filter { $0.isEnabled }
        for index in slots.indices {
            let slot = slots[index]
            if slot.isFixed { continue }
            let fixedMenu = fixedMenus.first { menu in
                menu.mealTime == slot.mealTime && menu.days.contains(slot.day)
            }
            if let menu = fixedMenu {
                slots[index].name = menu.name
                slots[index].isFixed = true
            }
        }
        saveSlots()
    }

    // MARK: - Persistence

    func loadSlots() {
        if let data = UserDefaults.standard.data(forKey: slotsKey),
           let saved = try? JSONDecoder().decode([MealSlot].self, from: data) {
            slots = saved
            applyFixedMenus()
        } else {
            slots = defaultSlots()
            saveSlots()
        }
    }

    func saveSlots() {
        if let data = try? JSONEncoder().encode(slots) {
            UserDefaults.standard.set(data, forKey: slotsKey)
        }
    }

    func resetSlots() {
        slots = defaultSlots()
        saveSlots()
    }

    // MARK: - Slot Access

    func slot(for day: String, mealTime: String) -> MealSlot? {
        slots.first { $0.day == day && $0.mealTime == mealTime }
    }

    func updateSlot(_ updated: MealSlot) {
        if let index = slots.firstIndex(where: { $0.id == updated.id }) {
            slots[index] = updated
            saveSlots()
        }
    }

    // MARK: - AI Proposal

    var slotsForAIProposal: [MealSlot] {
        slots.filter { !$0.isFixed }
    }

    @MainActor
    func generateMealPlan(userSettings: UserSettings) async {
        isLoading = true
        errorMessage = nil

        let targets = slotsForAIProposal
        guard !targets.isEmpty else {
            isLoading = false
            return
        }

        let slotDescriptions = targets.map { "\($0.day)・\($0.mealTime)" }.joined(separator: "、")

        let systemPrompt = """
        あなたはプロの管理栄養士です。
        ユーザーの情報に基づいて、指定されたスロットの献立を提案してください。
        レスポンスはJSON配列で、各要素は {"day": "月", "mealTime": "朝", "name": "料理名", "memo": "補足"} の形式にしてください。
        JSON以外のテキストは含めないでください。
        """

        let userMessage = """
        以下のスロットに献立を提案してください：
        \(slotDescriptions)

        ユーザー情報：
        - 身長: \(userSettings.height)cm
        - 体重: \(userSettings.weight)kg
        - 目標体重: \(userSettings.targetWeight)kg
        - 年齢: \(userSettings.age)歳
        - 予算: 月\(userSettings.monthlyBudget)円
        """

        do {
            let response = try await apiClient.send(systemPrompt: systemPrompt, userMessage: userMessage)
            let jsonData = response.data(using: .utf8) ?? Data()
            let meals = try JSONDecoder().decode([MealProposal].self, from: jsonData)

            for meal in meals {
                if let index = slots.firstIndex(where: {
                    $0.day == meal.day && $0.mealTime == meal.mealTime && !$0.isFixed
                }) {
                    slots[index].name = meal.name
                    slots[index].memo = meal.memo ?? ""
                }
            }
            saveSlots()
        } catch {
            errorMessage = "献立の生成に失敗しました。もう一度お試しください。"
        }

        isLoading = false
    }
}

private struct MealProposal: Codable {
    let day: String
    let mealTime: String
    let name: String
    let memo: String?
}
