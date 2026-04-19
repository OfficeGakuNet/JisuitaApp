//
//  APIModels.swift
//  JisuitaApp
//
//  Created by 株式会社オフィス岳 on 2026/04/10.
//

import Foundation

struct ClaudeResponse: Codable {
    let content: [ContentBlock]
}

struct ContentBlock: Codable {
    let type: String
    let text: String?
}

struct MealSlot: Identifiable, Codable {
    var id = UUID()
    var day: String      // 曜日（例："月"）
    var meal: String     // 食事（"朝" / "昼" / "夜"）
    var isCooking: Bool  // 自炊するか
}
