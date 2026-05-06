import SwiftUI
import Combine

@MainActor
final class ShoppingListViewModel: ObservableObject {
    static let shared = ShoppingListViewModel()

    @Published var items: [ShoppingItem] = []
    @Published var isGenerating = false
    @Published var errorMessage: String?
    @Published var lastGeneratedAt: Date?

    private let storageKey = "shoppingItems"
    private let lastGeneratedKey = "shoppingLastGenerated"

    private init() {
        load()
    }

    var groupedItems: [(category: ShoppingCategory, items: [ShoppingItem])] {
        let order = ShoppingCategory.allCases
        return order.compactMap { category in
            let filtered = items.filter { $0.category == category }
            guard !filtered.isEmpty else { return nil }
            return (category: category, items: filtered)
        }
    }

    var uncheckedCount: Int {
        items.filter { !$0.isChecked }.count
    }

    func generateFromMealPlan(slots: [MealSlot], fixedMenus: [FixedMenu]) async {
        isGenerating = true
        errorMessage = nil

        let cookingMeals = slots.filter { $0.isCooking && $0.name != "未設定" }.map { $0.name }
        let enabledFixed = fixedMenus.filter { $0.isEnabled }.map { $0.name }
        let allMeals = Array(Set(cookingMeals + enabledFixed))

        guard !allMeals.isEmpty else {
            isGenerating = false
            errorMessage = "献立に料理が設定されていません"
            return
        }

        let systemPrompt = """
        あなたは料理の食材リスト作成の専門家です。
        料理名のリストを受け取り、必要な食材をJSON形式で返してください。
        同じ食材は合算してください。
        カテゴリは以下から選んでください：野菜、肉類、魚介類、乳製品・卵、調味料、穀物・米、その他

        必ず以下のJSON形式のみで返答してください（説明文不要）:
        [
          {"name": "食材名", "amount": "量", "category": "カテゴリ名"},
          ...
        ]
        """

        let userMessage = "以下の料理に必要な食材リストを作成してください：\n" + allMeals.joined(separator: "、")

        do {
            let response = try await ClaudeAPIClient.shared.send(
                systemPrompt: systemPrompt,
                userMessage: userMessage
            )
            let parsed = try parseIngredients(from: response, sourceMeals: allMeals)
            mergeItems(parsed)
            lastGeneratedAt = Date()
            saveLastGenerated()
            save()
        } catch {
            errorMessage = error.localizedDescription
        }

        isGenerating = false
    }

    private func parseIngredients(from json: String, sourceMeals: [String]) throws -> [ShoppingItem] {
        let cleaned = extractJSON(from: json)
        guard let data = cleaned.data(using: .utf8) else { throw APIError.decodeError }

        struct RawIngredient: Codable {
            let name: String
            let amount: String
            let category: String
        }

        let raw = try JSONDecoder().decode([RawIngredient].self, from: data)
        return raw.map { ingredient in
            ShoppingItem(
                name: ingredient.name,
                amount: ingredient.amount,
                category: categoryFrom(string: ingredient.category),
                isChecked: false,
                sourceMeals: sourceMeals
            )
        }
    }

    private func extractJSON(from text: String) -> String {
        if let start = text.range(of: "["),
           let end = text.range(of: "]", options: .backwards) {
            return String(text[start.lowerBound...end.upperBound])
        }
        return text
    }

    private func categoryFrom(string: String) -> ShoppingCategory {
        ShoppingCategory.allCases.first { $0.rawValue == string } ?? .other
    }

    private func mergeItems(_ newItems: [ShoppingItem]) {
        var merged: [ShoppingItem] = items.filter { $0.isChecked }

        for newItem in newItems {
            if let idx = merged.firstIndex(where: { $0.name == newItem.name && !$0.isChecked }) {
                merged[idx].sourceMeals = Array(Set(merged[idx].sourceMeals + newItem.sourceMeals))
            } else {
                merged.append(newItem)
            }
        }

        items = merged
    }

    func toggleChecked(item: ShoppingItem) {
        if let idx = items.firstIndex(where: { $0.id == item.id }) {
            items[idx].isChecked.toggle()
            save()
        }
    }

    func addManualItem(_ item: ShoppingItem) {
        items.append(item)
        save()
    }

    func deleteItems(at offsets: IndexSet, in category: ShoppingCategory) {
        let categoryItems = items.enumerated().filter { $0.element.category == category }
        let toDelete = offsets.map { categoryItems[$0].offset }
        items.remove(atOffsets: IndexSet(toDelete))
        save()
    }

    func clearChecked() {
        items.removeAll { $0.isChecked }
        save()
    }

    func clearAll() {
        items.removeAll()
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let saved = try? JSONDecoder().decode([ShoppingItem].self, from: data) {
            items = saved
        }
        if let ts = UserDefaults.standard.object(forKey: lastGeneratedKey) as? Double {
            lastGeneratedAt = Date(timeIntervalSince1970: ts)
        }
    }

    private func saveLastGenerated() {
        if let date = lastGeneratedAt {
            UserDefaults.standard.set(date.timeIntervalSince1970, forKey: lastGeneratedKey)
        }
    }
}
