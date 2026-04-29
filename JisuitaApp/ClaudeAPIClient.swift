//
//  ClaudeAPIClient.swift
//  JisuitaApp
//
//  Created by 株式会社オフィス岳 on 2026/04/10.
//

import Foundation

actor ClaudeAPIClient {

    static let shared = ClaudeAPIClient()

    private let apiKey: String = {
        Bundle.main.object(forInfoDictionaryKey: "CLAUDE_API_KEY") as? String ?? ""
    }()

    private let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!
    private let model = "claude-3-5-sonnet-20241022"
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
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

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

        let decoded: ClaudeResponse
        do {
            decoded = try JSONDecoder().decode(ClaudeResponse.self, from: data)
        } catch {
            throw APIError.decodeError
        }

        if decoded.isError {
            throw APIError.apiError(decoded.errorMessage)
        }

        guard httpResponse.statusCode == 200 else {
            throw APIError.apiError("HTTPエラー: \(httpResponse.statusCode)")
        }

        guard let text = decoded.content?.first(where: { $0.type == "text" })?.text else {
            throw APIError.decodeError
        }

        return text
    }
}
