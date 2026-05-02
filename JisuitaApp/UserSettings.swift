import SwiftUI
import Combine

final class UserSettings: ObservableObject {
    static let shared = UserSettings()

    @AppStorage("userSettings.adultCount") var adultCount: Int = 2 {
        willSet { objectWillChange.send() }
    }
    @AppStorage("userSettings.childCount") var childCount: Int = 0 {
        willSet { objectWillChange.send() }
    }
    @AppStorage(AppDefaults.monthlyBudgetKey) var monthlyBudget: Int = AppDefaults.monthlyBudget {
        willSet { objectWillChange.send() }
    }

    @Published var dietaryRestrictions: Set<String> = [] {
        didSet { saveDietaryRestrictions() }
    }
    @Published var dislikedFoods: [String] = [] {
        didSet { saveDislikedFoods() }
    }
    @Published var favoriteCuisines: [String] = [] {
        didSet { saveFavoriteCuisines() }
    }

    private init() {
        loadDietaryRestrictions()
        loadDislikedFoods()
        loadFavoriteCuisines()
    }

    var totalPeople: Int { adultCount + childCount }

    var familySummary: String {
        var parts: [String] = ["大人\(adultCount)人"]
        if childCount > 0 { parts.append("子ども\(childCount)人") }
        return parts.joined(separator: "・")
    }

    var dietarySummary: String {
        dietaryRestrictions.isEmpty ? "なし" : dietaryRestrictions.count == 1
            ? dietaryRestrictions.first!
            : "\(dietaryRestrictions.count)件設定中"
    }

    var dislikedFoodsSummary: String {
        dislikedFoods.isEmpty ? "なし" : dislikedFoods.count == 1
            ? dislikedFoods.first!
            : "\(dislikedFoods.count)件登録済み"
    }

    var favoriteCuisinesSummary: String {
        favoriteCuisines.isEmpty ? "未設定" : favoriteCuisines.prefix(2).joined(separator: "・")
            + (favoriteCuisines.count > 2 ? "他" : "")
    }

    var promptSupplement: String {
        var lines: [String] = []
        lines.append("家族構成: 大人\(adultCount)人、子ども\(childCount)人")
        if !dietaryRestrictions.isEmpty {
            lines.append("食の制限: \(dietaryRestrictions.joined(separator: ", "))")
        }
        if !dislikedFoods.isEmpty {
            lines.append("苦手食材: \(dislikedFoods.joined(separator: ", "))")
        }
        if !favoriteCuisines.isEmpty {
            lines.append("好きなジャンル: \(favoriteCuisines.joined(separator: ", "))")
        }
        return lines.joined(separator: "\n")
    }

    private func saveDietaryRestrictions() {
        let data = (try? JSONEncoder().encode(Array(dietaryRestrictions))) ?? Data()
        UserDefaults.standard.set(data, forKey: "userSettings.dietaryRestrictions")
    }

    private func loadDietaryRestrictions() {
        guard let data = UserDefaults.standard.data(forKey: "userSettings.dietaryRestrictions"),
              let array = try? JSONDecoder().decode([String].self, from: data) else { return }
        dietaryRestrictions = Set(array)
    }

    private func saveDislikedFoods() {
        let data = (try? JSONEncoder().encode(dislikedFoods)) ?? Data()
        UserDefaults.standard.set(data, forKey: "userSettings.dislikedFoods")
    }

    private func loadDislikedFoods() {
        guard let data = UserDefaults.standard.data(forKey: "userSettings.dislikedFoods"),
              let array = try? JSONDecoder().decode([String].self, from: data) else { return }
        dislikedFoods = array
    }

    private func saveFavoriteCuisines() {
        let data = (try? JSONEncoder().encode(favoriteCuisines)) ?? Data()
        UserDefaults.standard.set(data, forKey: "userSettings.favoriteCuisines")
    }

    private func loadFavoriteCuisines() {
        guard let data = UserDefaults.standard.data(forKey: "userSettings.favoriteCuisines"),
              let array = try? JSONDecoder().decode([String].self, from: data) else { return }
        favoriteCuisines = array
    }
}
