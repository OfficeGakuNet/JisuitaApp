import Foundation

enum AppDefaults {
    static let monthlyBudget = 30000
    static let spentAmount = 0
    static let monthlyBudgetKey = "monthlyBudget"
    static let spentAmountKey = "spentAmount"
    static let spentAmountResetMonthKey = "spentAmountResetMonth"
}

enum APIConfig {
    #if DEBUG
    static let claudeModel = "claude-haiku-4-5"
    #else
    static let claudeModel = "claude-sonnet-4-5"
    #endif

    static let maxTokens = 4096
    static let anthropicVersion = "2023-06-01"
    static let endpoint = "https://api.anthropic.com/v1/messages"
}
