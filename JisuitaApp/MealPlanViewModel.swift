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
        if slots.isEmpty {
            slots = Self.defaultSlots()
        }
    }

    func slot(for day: String, mealTime: String) -> MealSlot? {
        slots.first { $0.day == day && $0.mealTime == mealTime }
    }

    func update(_ slot: MealSlot) {
        guard let idx = slots.firstIndex(where: { $0.id == slot.id }) else { return }
        slots[idx] = slot
    }

    func upsert(_ slot: MealSlot) {
        if let idx = slots.firstIndex(where: { $0.day == slot.day && $0.mealTime == slot.mealTime }) {
            slots[idx] = slot
        } else {
            slots.append(slot)
        }
    }

    func generateWithAI(systemPrompt: String, userMessage: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let raw = try await apiClient.send(systemPrompt: systemPrompt, userMessage: userMessage)
            let parsed = try parseMealSlots(from: raw)
            for s in parsed { upsert(s) }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func parseMealSlots(from json: String) throws -> [MealSlot] {
        let trimmed = json
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let data = trimmed.data(using: .utf8) else { throw APIError.decodeError }
        return try JSONDecoder().decode([MealSlot].self, from: data)
    }

    private static func defaultSlots() -> [MealSlot] {
        let days = ["月", "火", "水", "木", "金", "土", "日"]
        let times = ["朝", "昼", "夜"]
        return days.flatMap { day in
            times.map { time in
                MealSlot(day: day, mealTime: time)
            }
        }
    }
}
