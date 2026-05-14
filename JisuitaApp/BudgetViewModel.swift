import SwiftUI
import Combine

final class BudgetViewModel: ObservableObject {
    @AppStorage(AppDefaults.monthlyBudgetKey) var monthlyBudget: Int = AppDefaults.monthlyBudget
    @AppStorage(AppDefaults.spentAmountKey) var spentAmount: Int = AppDefaults.spentAmount
    @AppStorage(AppDefaults.spentAmountResetMonthKey) private var resetMonth: String = ""

    private let calendar = Calendar.current

    init() {
        resetIfNeeded()
    }

    var budgetRatio: Double {
        guard monthlyBudget > 0 else { return 0 }
        return min(Double(spentAmount) / Double(monthlyBudget), 1.0)
    }

    var remaining: Int {
        max(monthlyBudget - spentAmount, 0)
    }

    var budgetStatus: BudgetStatus {
        BudgetStatus(ratio: budgetRatio)
    }

    var progressColor: Color {
        budgetStatus.color
    }

    func addSpending(_ amount: Int) {
        resetIfNeeded()
        spentAmount += amount
    }

    func resetIfNeeded() {
        let currentMonth = monthKey(for: Date())
        if resetMonth != currentMonth {
            spentAmount = AppDefaults.spentAmount
            resetMonth = currentMonth
        }
    }

    private func monthKey(for date: Date) -> String {
        let comps = calendar.dateComponents([.year, .month], from: date)
        return String(format: "%04d-%02d", comps.year ?? 0, comps.month ?? 0)
    }
}
