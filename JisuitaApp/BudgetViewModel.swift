import SwiftUI
import Combine

@MainActor
final class BudgetViewModel: ObservableObject {
    @AppStorage(AppDefaults.monthlyBudgetKey) var monthlyBudget = AppDefaults.monthlyBudget
    @AppStorage(AppDefaults.spentAmountKey) var spentAmount = AppDefaults.spentAmount
    @AppStorage(AppDefaults.spentAmountResetMonthKey) private var resetMonth = ""

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

    var progressColor: Color {
        budgetRatio > 0.9 ? .red : budgetRatio > 0.7 ? .orange : Color(hex: "1D9E75")
    }

    func addSpending(_ amount: Int) {
        resetIfNeeded()
        spentAmount += amount
    }

    private func resetIfNeeded() {
        let now = Date()
        let currentMonth = monthKey(for: now)
        if resetMonth != currentMonth {
            spentAmount = AppDefaults.spentAmount
            resetMonth = currentMonth
        }
    }

    private func monthKey(for date: Date) -> String {
        let comps = calendar.dateComponents([.year, .month], from: date)
        return "\(comps.year ?? 0)-\(comps.month ?? 0)"
    }
}
