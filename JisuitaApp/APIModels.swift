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

struct Meal: Identifiable, Codable {
    var id = UUID()
    var day: String
    var mealTime: String
    var name: String
    var memo: String = ""
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

enum APIError: Error, LocalizedError {
    case network(URLError)
    case apiError(String)
    case decodeError
    case unknown

    var errorDescription: String? {
        switch self {
        case .network(let urlError):
            APILogger.log("[Network] \(urlError.localizedDescription) (code: \(urlError.code.rawValue))")
            switch urlError.code {
            case .notConnectedToInternet:
                return "インターネットに接続されていません。Wi-FiまたはモバイルデータをONにしてください。"
            case .timedOut:
                return "通信がタイムアウトしました。電波状況を確認して再試行してください。"
            case .cannotFindHost:
                return "サーバーが見つかりません。ネットワーク接続を確認してください。"
            case .cannotConnectToHost:
                return "サーバーに接続できませんでした。しばらく時間をおいて再試行してください。"
            case .serverCertificateUntrusted, .serverCertificateHasBadDate,
                 .serverCertificateNotYetValid, .serverCertificateHasUnknownRoot:
                return "SSL証明書に問題があります。安全な接続を確立できませんでした。"
            case .cancelled:
                return "通信がキャンセルされました。"
            case .networkConnectionLost:
                return "通信中にネットワーク接続が切れました。再試行してください。"
            case .dnsLookupFailed:
                return "DNS解決に失敗しました。ネットワーク接続を確認してください。"
            case .httpTooManyRedirects:
                return "リダイレクトが多すぎます。しばらく時間をおいて再試行してください。"
            case .internationalRoamingOff:
                return "国際ローミングがオフになっています。設定を確認してください。"
            case .callIsActive:
                return "通話中はデータ通信が制限されています。通話終了後に再試行してください。"
            default:
                return "ネットワークエラーが発生しました。(\(urlError.code.rawValue))"
            }
        case .apiError(let message):
            return message
        case .decodeError:
            return "データの読み込みに失敗しました。しばらく時間をおいて再試行してください。"
        case .unknown:
            return "予期しないエラーが発生しました。"
        }
    }
}

enum APILogger {
    static func log(_ message: String) {
#if DEBUG
        print(message)
#endif
    }
}
