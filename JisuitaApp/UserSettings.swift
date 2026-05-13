//
//  UserSettings.swift
//  JisuitaApp
//
//  Created by 株式会社オフィス岳 on 2026/04/10.
//

import Foundation
import Combine

final class UserSettings: ObservableObject {
    static let shared = UserSettings()

    @Published var name: String {
        didSet { UserDefaults.standard.set(name, forKey: "userName") }
    }
    @Published var age: Int {
        didSet { UserDefaults.standard.set(age, forKey: "userAge") }
    }
    @Published var height: Double {
        didSet { UserDefaults.standard.set(height, forKey: "userHeight") }
    }
    @Published var targetWeight: Double {
        didSet { UserDefaults.standard.set(targetWeight, forKey: "userTargetWeight") }
    }
    @Published var dietaryRestrictions: String {
        didSet { UserDefaults.standard.set(dietaryRestrictions, forKey: "dietaryRestrictions") }
    }
    @Published var favoriteGenres: [String] {
        didSet { UserDefaults.standard.set(favoriteGenres, forKey: "favoriteGenres") }
    }
    @Published var dislikedFoods: String {
        didSet { UserDefaults.standard.set(dislikedFoods, forKey: "dislikedFoods") }
    }
    @Published var monthlyFoodBudget: Int {
        didSet { UserDefaults.standard.set(monthlyFoodBudget, forKey: "monthlyFoodBudget") }
    }
    @Published var bringLunch: Bool {
        didSet { UserDefaults.standard.set(bringLunch, forKey: "bringLunch") }
    }
    @Published var shoppingDay: String {
        didSet { UserDefaults.standard.set(shoppingDay, forKey: "shoppingDay") }
    }

    init() {
        name = UserDefaults.standard.string(forKey: "userName") ?? ""
        age = UserDefaults.standard.integer(forKey: "userAge")
        height = UserDefaults.standard.double(forKey: "userHeight")
        targetWeight = UserDefaults.standard.double(forKey: "userTargetWeight")
        dietaryRestrictions = UserDefaults.standard.string(forKey: "dietaryRestrictions") ?? ""
        favoriteGenres = UserDefaults.standard.stringArray(forKey: "favoriteGenres") ?? []
        dislikedFoods = UserDefaults.standard.string(forKey: "dislikedFoods") ?? ""
        monthlyFoodBudget = UserDefaults.standard.integer(forKey: "monthlyFoodBudget")
        bringLunch = UserDefaults.standard.bool(forKey: "bringLunch")
        shoppingDay = UserDefaults.standard.string(forKey: "shoppingDay") ?? "土"
    }
}
