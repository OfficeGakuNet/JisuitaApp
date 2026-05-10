//
//  UserSettings.swift
//  JisuitaApp
//
//  Created by 株式会社オフィス岳 on 2026/04/10.
//

import SwiftUI
import Combine

final class UserSettings: ObservableObject {

    static let shared = UserSettings()

    @AppStorage("userName") var userName: String = ""
    @AppStorage("age") var age: Int = 0
    @AppStorage("height") var height: Double = 0
    @AppStorage("weight") var weight: Double = 0
    @AppStorage("targetWeight") var targetWeight: Double = 0
    @AppStorage("dietaryRestrictions") var dietaryRestrictions: String = ""
    @AppStorage("dislikedFoods") var dislikedFoods: String = ""
    @AppStorage("preferredCuisines") var preferredCuisines: String = ""
    @AppStorage("monthlyFoodBudget") var monthlyFoodBudget: Int = 30000
    @AppStorage("hasBento") var hasBento: Bool = false
    @AppStorage("shoppingDay") var shoppingDay: String = "土"
}
