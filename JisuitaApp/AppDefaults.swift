import Foundation

enum AppDefaults {
    static let monthlyBudget = 30000
    static let spentAmount = 0
    static let monthlyBudgetKey = "monthlyBudget"
    static let spentAmountKey = "spentAmount"
    static let spentAmountResetMonthKey = "spentAmountResetMonth"

    enum BudgetThreshold {
        static let danger: Double = 0.9
        static let caution: Double = 0.7
    }
}
