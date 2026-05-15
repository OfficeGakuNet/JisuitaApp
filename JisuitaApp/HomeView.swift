import SwiftUI

struct HomeView: View {
    @StateObject private var budgetViewModel = BudgetViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    budgetCard
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("ホーム")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var budgetCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("今月の食費")
                    .font(.headline)
                Spacer()
                NavigationLink {
                    BudgetSettingsView(viewModel: budgetViewModel)
                } label: {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                }
            }

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("¥\(budgetViewModel.spentAmount.formatted())")
                    .font(.title)
                    .fontWeight(.bold)
                Text("/ ¥\(budgetViewModel.monthlyBudget.formatted())")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(budgetViewModel.progressColor)
                        .frame(width: geo.size.width * budgetViewModel.budgetRatio, height: 8)
                }
            }
            .frame(height: 8)

            HStack {
                Text("残り")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text("¥\(budgetViewModel.remaining.formatted())")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(budgetViewModel.progressColor)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}
