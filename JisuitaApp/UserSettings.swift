import Foundation
import SwiftUI
import Combine

final class UserSettings: ObservableObject {
    static let shared = UserSettings()

    private let dietaryRestrictionsKey = "dietaryRestrictions"
    private let allergiesKey = "allergies"
    private let cookingSkillKey = "cookingSkill"
    private let preferredCuisinesKey = "preferredCuisines"
    private let dislikedIngredientsKey = "dislikedIngredients"

    @Published var dietaryRestrictions: [String] = [] {
        didSet { save(dietaryRestrictions, forKey: dietaryRestrictionsKey) }
    }

    @Published var allergies: [String] = [] {
        didSet { save(allergies, forKey: allergiesKey) }
    }

    @Published var cookingSkill: String = "普通" {
        didSet { UserDefaults.standard.set(cookingSkill, forKey: cookingSkillKey) }
    }

    @Published var preferredCuisines: [String] = [] {
        didSet { save(preferredCuisines, forKey: preferredCuisinesKey) }
    }

    @Published var dislikedIngredients: [String] = [] {
        didSet { save(dislikedIngredients, forKey: dislikedIngredientsKey) }
    }

    @AppStorage(AppDefaults.monthlyBudgetKey) var monthlyBudget = AppDefaults.monthlyBudget

    private init() {
        dietaryRestrictions = load([String].self, forKey: dietaryRestrictionsKey) ?? []
        allergies = load([String].self, forKey: allergiesKey) ?? []
        cookingSkill = UserDefaults.standard.string(forKey: cookingSkillKey) ?? "普通"
        preferredCuisines = load([String].self, forKey: preferredCuisinesKey) ?? []
        dislikedIngredients = load([String].self, forKey: dislikedIngredientsKey) ?? []
    }

    private func save<T: Encodable>(_ value: T, forKey key: String) {
        if let data = try? JSONEncoder().encode(value) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func load<T: Decodable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    var restrictionsSummary: String {
        var parts: [String] = []
        if !allergies.isEmpty { parts.append("アレルギー: " + allergies.joined(separator: "・")) }
        if !dietaryRestrictions.isEmpty { parts.append(dietaryRestrictions.joined(separator: "・")) }
        if !dislikedIngredients.isEmpty { parts.append("苦手食材: " + dislikedIngredients.joined(separator: "・")) }
        return parts.isEmpty ? "なし" : parts.joined(separator: "、")
    }

    func buildPersonalizedPromptContext() -> String {
        var lines: [String] = []
        lines.append("【月間食費予算】¥\(monthlyBudget.formatted())")
        lines.append("【料理スキル】\(cookingSkill)")
        if !preferredCuisines.isEmpty {
            lines.append("【好みの料理ジャンル】" + preferredCuisines.joined(separator: "・"))
        }
        if !allergies.isEmpty {
            lines.append("【アレルギー（必ず除外）】" + allergies.joined(separator: "・"))
        }
        if !dietaryRestrictions.isEmpty {
            lines.append("【食の制限】" + dietaryRestrictions.joined(separator: "・"))
        }
        if !dislikedIngredients.isEmpty {
            lines.append("【苦手な食材（できるだけ避ける）】" + dislikedIngredients.joined(separator: "・"))
        }
        return lines.joined(separator: "\n")
    }
}
