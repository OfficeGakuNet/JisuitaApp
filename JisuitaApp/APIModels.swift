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

/// 献立スロットの Single Source of Truth
/// - MealPlanView / HomeView など全画面がこのモデルを参照する
/// - `isCooking`: 自炊するか（false の場合は外食・テイクアウト扱い）
/// - `memo`: AI提案時の補足や手動メモ
struct MealSlot: Identifiable, Codable {
    let id: UUID
    var day: String
    var mealTime: String
    var name: String
    var isCooking: Bool
    var memo: String

    init(
        id: UUID = UUID(),
        day: String,
        mealTime: String,
        name: String = "未設定",
        isCooking: Bool = true,
        memo: String = ""
    ) {
        self.id = id
        self.day = day
        self.mealTime = mealTime
        self.name = name
        self.isCooking = isCooking
        self.memo = memo
    }
}

enum APIError: LocalizedError {
    case network(URLError)
    case apiError(String)
    case decodeError
    case unknown

    var errorDescription: String? {
        switch self {
        case .network(let urlError):
            switch urlError.code {
            case .notConnectedToInternet:
                return "インターネットに接続されていません"
            case .timedOut:
                return "通信がタイムアウトしました"
            default:
                return "ネットワークエラーが発生しました"
            }
        case .apiError(let message):
            return message
        case .decodeError:
            return "レスポンスの解析に失敗しました"
        case .unknown:
            return "不明なエラーが発生しました"
        }
    }
}
