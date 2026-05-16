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
    @AppStorage("userHeight") var height: Double = 0
    @AppStorage("userWeight") var weight: Double = 0
    @AppStorage("userTargetWeight") var targetWeight: Double = 0
    @AppStorage("userAge") var age: Int = 0
    @AppStorage("shoppingDay") var shoppingDay: String = "土"
    @AppStorage("hasBento") var hasBento: Bool = false

    /// 冷蔵庫の在庫食材一覧（AI提案プロンプトに使用）
    @Published var refrigeratorItems: [String] = []

    private let refrigeratorKey = "refrigeratorItems"

    init() {
        loadRefrigeratorItems()
    }

    func addRefrigeratorItem(_ item: String) {
        let trimmed = item.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !refrigeratorItems.contains(trimmed) else { return }
        refrigeratorItems.append(trimmed)
        saveRefrigeratorItems()
    }

    func removeRefrigeratorItem(_ item: String) {
        refrigeratorItems.removeAll { $0 == item }
        saveRefrigeratorItems()
    }

    private func saveRefrigeratorItems() {
        if let data = try? JSONEncoder().encode(refrigeratorItems) {
            UserDefaults.standard.set(data, forKey: refrigeratorKey)
        }
    }

    private func loadRefrigeratorItems() {
        if let data = UserDefaults.standard.data(forKey: refrigeratorKey),
           let decoded = try? JSONDecoder().decode([String].self, from: data) {
            refrigeratorItems = decoded
        }
    }
}
