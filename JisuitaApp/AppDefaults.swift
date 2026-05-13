import Foundation

enum AppDefaults {
    static let monthlyBudget = 30000
    static let spentAmount = 0
    static let monthlyBudgetKey = "monthlyBudget"
    static let spentAmountKey = "spentAmount"
    static let spentAmountResetMonthKey = "spentAmountResetMonth"

    static func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            monthlyBudgetKey: monthlyBudget,
            spentAmountKey: spentAmount,
            spentAmountResetMonthKey: ""
        ])
    }

    static func migrateIfNeeded() {
        let migrationKey = "appDefaults_migrationVersion"
        let currentVersion = 1
        let storedVersion = UserDefaults.standard.integer(forKey: migrationKey)

        guard storedVersion < currentVersion else { return }

        // v1: 初回マイグレーション（将来のキー名変更時はここに追記）
        if storedVersion < 1 {
            // 例: 旧キー "budget" → 新キー "monthlyBudget" への移行
            let legacy = UserDefaults.standard.object(forKey: "budget")
            if let legacyValue = legacy as? Int,
               UserDefaults.standard.object(forKey: monthlyBudgetKey) == nil {
                UserDefaults.standard.set(legacyValue, forKey: monthlyBudgetKey)
            }
        }

        UserDefaults.standard.set(currentVersion, forKey: migrationKey)
    }
}
