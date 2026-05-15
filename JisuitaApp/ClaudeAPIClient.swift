//
//  ClaudeAPIClient.swift
//  JisuitaApp
//
//  Created by 株式会社オフィス岳 on 2026/04/10.
//

import Foundation

class ClaudeAPIClient: ClaudeAPIClientProtocol {

    static let shared = ClaudeAPIClient()

    private let apiKey: String = Secrets.claudeAPIKey

    private let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!
    private let model = "claude-sonnet-4-6"
    private let maxTokens = 4096

    func send(systemPrompt: String, userMessage: String) async throws -> String {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        let body: [String: Any] = [
            "model": model,
            "max_tokens": maxTokens,
            "system": systemPrompt,
            "messages": [
                ["role": "user", "content": userMessage]
            ]
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            throw APIError.decodeError
        }

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch let urlError as URLError {
            throw APIError.network(urlError)
        } catch {
            throw APIError.unknown
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.unknown
        }

        APILogger.log("[HTTP] status=\(httpResponse.statusCode)")

        switch httpResponse.statusCode {
        case 200:
            break
        case 401:
            APILogger.log("[HTTP] 401 Unauthorized - APIキーを確認してください")
            throw APIError.apiError("認証に失敗しました。APIキーが無効です。")
        case 403:
            APILogger.log("[HTTP] 403 Forbidden")
            throw APIError.apiError("アクセスが拒否されました。")
        case 429:
            APILogger.log("[HTTP] 429 Rate Limit Exceeded")
            throw APIError.apiError("リクエストが多すぎます。しばらく時間をおいて再試行してください。")
        case 500, 502, 503, 504:
            APILogger.log("[HTTP] \(httpResponse.statusCode) Server Error")
            throw APIError.apiError("サーバーエラーが発生しました。しばらく時間をおいて再試行してください。")
        default:
            APILogger.log("[HTTP] Unexpected status=\(httpResponse.statusCode)")
            throw APIError.apiError("予期しないレスポンスが返されました。(\(httpResponse.statusCode))")
        }

        let decoded: ClaudeResponse
        do {
            decoded = try JSONDecoder().decode(ClaudeResponse.self, from: data)
        } catch {
            APILogger.log("[Decode] \(error.localizedDescription)")
            throw APIError.decodeError
        }

        if decoded.isError {
            APILogger.log("[API] error=\(decoded.errorMessage)")
            throw APIError.apiError(decoded.errorMessage)
        }

        guard let text = decoded.content?.first(where: { $0.type == "text" })?.text else {
            throw APIError.decodeError
        }

        return text
    }
}
