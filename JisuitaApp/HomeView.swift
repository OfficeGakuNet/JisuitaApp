import SwiftUI

struct HomeView: View {
    @StateObject private var budgetViewModel = BudgetViewModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    BudgetSummaryCard(viewModel: budgetViewModel)
                    MealPlanSummaryCard()
                    ExpiryAlertCard()
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("ホーム")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            budgetViewModel.resetIfNeeded()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                budgetViewModel.resetIfNeeded()
            }
        }
    }
}

private struct BudgetSummaryCard: View {
    @ObservedObject var viewModel: BudgetViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("今月の食費")
                    .font(.headline)
                Spacer()
                NavigationLink(destination: BudgetView(viewModel: viewModel)) {
                    Text("詳細")
                        .font(.subheadline)
                        .foregroundColor(Color(hex: "1D9E75"))
                }
            }

            HStack(alignment: .bottom, spacing: 4) {
                Text("¥\(viewModel.spentAmount.formatted())")
                    .font(.title)
                    .fontWeight(.bold)
                Text("/ ¥\(viewModel.monthlyBudget.formatted())")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 2)
            }

            ProgressView(value: viewModel.budgetRatio)
                .tint(viewModel.progressColor)

            HStack {
                Text("残り ¥\(viewModel.remaining.formatted())")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text(String(format: "%.0f%%", viewModel.budgetRatio * 100))
                    .font(.subheadline)
                    .foregroundColor(viewModel.progressColor)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

private struct MealPlanSummaryCard: View {
    @EnvironmentObject private var mealPlanViewModel: MealPlanViewModel

    private var todaySlots: [MealSlot] {
        let weekdays = ["日", "月", "火", "水", "木", "金", "土"]
        let weekdayIndex = Calendar.current.component(.weekday, from: Date()) - 1
        let today = weekdays[weekdayIndex]
        return mealPlanViewModel.mealSlots.filter { $0.day == today }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("今日の献立")
                    .font(.headline)
                Spacer()
                NavigationLink(destination: MealPlanView()) {
                    Text("詳細")
                        .font(.subheadline)
                        .foregroundColor(Color(hex: "1D9E75"))
                }
            }

            if todaySlots.isEmpty {
                Text("献立が設定されていません")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                ForEach(todaySlots) { slot in
                    HStack {
                        Text(slot.mealTime)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(width: 32, alignment: .leading)
                        Text(slot.name)
                            .font(.subheadline)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

private struct ExpiryAlertCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("賞味期限アラート")
                    .font(.headline)
                Spacer()
                NavigationLink(destination: ExpiryAlertView()) {
                    Text("詳細")
                        .font(.subheadline)
                        .foregroundColor(Color(hex: "1D9E75"))
                }
            }

            Text("期限の近い食材を確認しましょう")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}
