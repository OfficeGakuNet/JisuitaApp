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

struct MealSlot: Identifiable, Codable {
    let id: UUID
    var day: String
    var meal: String
    var isCooking: Bool

    init(id: UUID = UUID(), day: String, meal: String, isCooking: Bool) {
        self.id = id
        self.day = day
        self.meal = meal
        self.isCooking = isCooking
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
