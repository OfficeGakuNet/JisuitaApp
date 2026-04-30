import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    TodayMealCard()
                    QuickActionsGrid()
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("ホーム")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

private struct TodayMealCard: View {

    @ObservedObject private var viewModel = MealPlanViewModel.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("今日の献立")
                    .font(.headline)
                Spacer()
                Text(formattedDate())
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            let todaySlots = viewModel.todaySlots()
            if todaySlots.isEmpty {
                Text("献立が登録されていません")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                ForEach(todaySlots) { slot in
                    HStack(spacing: 6) {
                        Text(slot.mealTime + ":")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(Color(hex: "1D9E75"))
                            .frame(width: 28, alignment: .leading)
                        Text(slot.name)
                            .font(.subheadline)
                            .foregroundColor(slot.name == "未設定" ? .secondary : .primary)
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    private func formattedDate() -> String {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "ja_JP")
        fmt.dateFormat = "M月d日(E)"
        return fmt.string(from: Date())
    }
}

private struct QuickActionsGrid: View {
    let actions: [(String, String, String)] = [
        ("fork.knife", "献立を作る", "MealPlan"),
        ("cart.fill", "買い出しリスト", "Shopping"),
        ("chart.line.uptrend.xyaxis", "体重を記録", "Record"),
        ("person.fill", "プロフィール設定", "Profile"),
    ]

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(actions, id: \.0) { icon, label, _ in
                VStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(Color(hex: "1D9E75"))
                    Text(label)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(12)
            }
        }
    }
}
