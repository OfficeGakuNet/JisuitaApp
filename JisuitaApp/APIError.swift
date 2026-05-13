//
//  APIError.swift
//  JisuitaApp
//
//  Created by 株式会社オフィス岳 on 2026/04/10.
//

import Foundation

enum APIError: Error, LocalizedError {
    case network(URLError)
    case apiError(String)
    case decodeError
    case unknown

    var errorDescription: String? {
        switch self {
        case .network(let e): return "通信エラー: \(e.localizedDescription)"
        case .apiError(let msg): return "APIエラー: \(msg)"
        case .decodeError: return "レスポンスの解析に失敗しました"
        case .unknown: return "不明なエラーが発生しました"
        }
    }
}
