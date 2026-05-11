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

enum APIError: LocalizedError {
    case decodeError
    case network(URLError)
    case apiError(String)
    case unknown
    case retryExhausted(URLError)

    var errorDescription: String? {
        switch self {
        case .decodeError:
            return "データの読み込みに失敗しました。"
        case .network(let urlError):
            return networkErrorMessage(urlError)
        case .apiError(let message):
            return "APIエラー: \(message)"
        case .unknown:
            return "予期しないエラーが発生しました。"
        case .retryExhausted(let urlError):
            return "通信に失敗しました（\(networkErrorMessage(urlError))）。時間をおいて再試行してください。"
        }
    }

    private func networkErrorMessage(_ urlError: URLError) -> String {
        switch urlError.code {
        case .timedOut:
            return "通信がタイムアウトしました。"
        case .notConnectedToInternet:
            return "インターネットに接続されていません。"
        case .networkConnectionLost:
            return "通信が途切れました。"
        default:
            return "通信エラーが発生しました。"
        }
    }

    var isRetryable: Bool {
        switch self {
        case .network(let urlError):
            return [.timedOut, .networkConnectionLost, .cannotConnectToHost].contains(urlError.code)
        default:
            return false
        }
    }
}

struct Meal: Identifiable, Codable {
    var id = UUID()
    var day: String
    var mealTime: String
    var name: String
    var memo: String = ""
}

/// 献立スロットの Single Source of Truth
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
