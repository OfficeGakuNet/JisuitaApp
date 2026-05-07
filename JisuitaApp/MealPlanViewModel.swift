//
//  MealPlanViewModel.swift
//  JisuitaApp
//
//  Created by 株式会社オフィス岳 on 2026/04/10.
//

import SwiftUI
import Combine

@MainActor
final class MealPlanViewModel: ObservableObject {

    static let shared = MealPlanViewModel()

    @Published var mealSlots: [MealSlot] = Self.defaultSlots()
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let apiClient: ClaudeAPIClientProtocol

    init(apiClient: ClaudeAPIClientProtocol = ClaudeAPIClient.shared) {
        self.apiClient = apiClient
    }

    private static let days = ["月", "火", "水", "木", "金", "土", "日"]
    private static let mealTimes = ["朝", "昼", "夜"]

    private static func defaultSlots() -> [MealSlot] {
        days.flatMap { day in
            mealTimes.map { time in
                MealSlot(day: day, mealTime: time)
            }
        }
    }

    func generateMealPlan() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let systemPrompt = """
        あなたは家庭料理の献立提案AIです。
        週間献立を提案してください。
        出力形式は「曜日,食事時間,料理名」を1行ずつ、余分な説明なしで返してください。
        例: 月,朝,トースト
        """

        let cookingSlots = mealSlots.filter { $0.isCooking }
        let slotDescriptions = cookingSlots.map { "\($0.day)\($0.mealTime)" }.joined(separator: ", ")
        let userMessage = "次のスロットの献立を提案してください: \(slotDescriptions)"

        do {
            let response = try await apiClient.send(systemPrompt: systemPrompt, userMessage: userMessage)
            applyResponse(response)
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = APIError.unknown.errorDescription
        }
    }

    private func applyResponse(_ response: String) {
        let lines = response.components(separatedBy: "\n").filter { !$0.isEmpty }
        for line in lines {
            let parts = line.components(separatedBy: ",")
            guard parts.count >= 3 else { continue }
            let day = parts[0].trimmingCharacters(in: .whitespaces)
            let mealTime = parts[1].trimmingCharacters(in: .whitespaces)
            let name = parts[2].trimmingCharacters(in: .whitespaces)
            if let index = mealSlots.firstIndex(where: { $0.day == day && $0.mealTime == mealTime && $0.isCooking }) {
                mealSlots[index].name = name
            }
        }
    }

    func toggleCooking(for slot: MealSlot) {
        if let index = mealSlots.firstIndex(where: { $0.id == slot.id }) {
            mealSlots[index].isCooking.toggle()
            if !mealSlots[index].isCooking {
                mealSlots[index].name = "未設定"
            }
        }
    }

    func updateMealName(for slot: MealSlot, name: String) {
        if let index = mealSlots.firstIndex(where: { $0.id == slot.id }) {
            mealSlots[index].name = name
        }
    }
}
