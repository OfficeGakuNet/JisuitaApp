//
//  ClaudeAPIClientProtocol.swift
//  JisuitaApp
//
//  Created by 株式会社オフィス岳 on 2026/04/10.
//

import Foundation

protocol ClaudeAPIClientProtocol {
    func send(systemPrompt: String, userMessage: String) async throws -> String
}
