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

    private let timeoutInterval: TimeInterval = 30
    private let maxRetryCount = 3
    private let baseRetryDelay: TimeInterval = 1.0

    func send(systemPrompt: String, userMessage: String) async throws -> String {
        let requestBody = try buildRequestBody(systemPrompt: systemPrompt, userMessage: userMessage)

        var lastError: APIError = .unknown
        for attempt in 0..<maxRetryCount {
            do {
                return try await performRequest(body: requestBody)
            } catch let error as APIError {
                lastError = error
                guard error.isRetryable else { throw error }
                if attempt < maxRetryCount - 1 {
                    let delay = baseRetryDelay * pow(2.0, Double(attempt))
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }

        if case .network(let urlError) = lastError {
            throw APIError.retryExhausted(urlError)
        }
        throw lastError
    }

    private func buildRequestBody(systemPrompt: String, userMessage: String) throws -> Data {
        let body: [String: Any] = [
            "model": model,
            "max_tokens": maxTokens,
            "system": systemPrompt,
            "messages": [
                ["role": "user", "content": userMessage]
            ]
        ]
        do {
            return try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            throw APIError.decodeError
        }
    }

    private func performRequest(body: Data) async throws -> String {
        var request = URLRequest(url: endpoint, timeoutInterval: timeoutInterval)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.httpBody = body

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
            throw APIError.apiError("HTTPステータス: \(httpResponse.statusCode)")
        }

        guard let text = decoded.content?.first(where: { $0.type == "text" })?.text else {
            throw APIError.decodeError
        }

        return text
    }
}
