//
//  APIModels.swift
//  JisuitaApp
//
//  Created by 株式会社オフィス岳 on 2026/04/10.
//

import Foundation

struct ClaudeResponse: Codable {
    let content: [ContentBlock]?
    let type: String?
    let error: ClaudeErrorBody?

    var isError: Bool { type == "error" || error != nil }
    var errorMessage: String { error?.message ?? "不明なエラー" }
}

struct ContentBlock: Codable {
    let type: String
    let text: String?
}

struct ClaudeErrorBody: Codable {
    let type: String?
    let message: String
}

// JSONキー名はSwiftプロパティ名と同一（CodingKeys省略）
// id / day / mealTime / name / memo
struct Meal: Identifiable, Codable {
    let id: UUID
    var day: String
    var mealTime: String
    var name: String
    var memo: String

    init(
        id: UUID = UUID(),
        day: String,
        mealTime: String,
        name: String,
        memo: String = ""
    ) {
        self.id = id
        self.day = day
        self.mealTime = mealTime
        self.name = name
        self.memo = memo
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        day = try c.decode(String.self, forKey: .day)
        mealTime = try c.decode(String.self, forKey: .mealTime)
        name = try c.decodeIfPresent(String.self, forKey: .name) ?? ""
        memo = try c.decodeIfPresent(String.self, forKey: .memo) ?? ""
    }
}

// JSONキー名はSwiftプロパティ名と同一（CodingKeys省略）
// id / day / mealTime / name / isCooking / isFixed / memo
struct MealSlot: Identifiable, Codable {
    let id: UUID
    var day: String
    var mealTime: String
    var name: String
    var isCooking: Bool
    var isFixed: Bool
    var memo: String

    init(
        id: UUID = UUID(),
        day: String,
        mealTime: String,
        name: String = "未設定",
        isCooking: Bool = true,
        isFixed: Bool = false,
        memo: String = ""
    ) {
        self.id = id
        self.day = day
        self.mealTime = mealTime
        self.name = name
        self.isCooking = isCooking
        self.isFixed = isFixed
        self.memo = memo
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        day = try c.decode(String.self, forKey: .day)
        mealTime = try c.decode(String.self, forKey: .mealTime)
        name = try c.decodeIfPresent(String.self, forKey: .name) ?? "未設定"
        isCooking = try c.decodeIfPresent(Bool.self, forKey: .isCooking) ?? true
        isFixed = try c.decodeIfPresent(Bool.self, forKey: .isFixed) ?? false
        memo = try c.decodeIfPresent(String.self, forKey: .memo) ?? ""
    }
}
