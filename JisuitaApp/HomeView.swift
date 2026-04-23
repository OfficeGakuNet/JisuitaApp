import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 今日の食事カード
                    TodayMealCard()

                    // クイックアクション
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
    let meals = ["朝: ご飯・味噌汁", "昼: 未設定", "夜: 未設定"]

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

            ForEach(meals, id: \.self) { meal in
                Text(meal)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
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
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(12)
            }
        }
    }
}

#Preview {
    HomeView()
}
