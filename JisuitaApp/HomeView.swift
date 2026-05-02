import SwiftUI

struct HomeView: View {
    @AppStorage("monthlyBudget") private var monthlyBudget: Int = 30000
    @AppStorage("spentAmount") private var spentAmount: Int = 0
    @State private var todayMeals: [String] = []
    @State private var isLoadingMeals = false
    @State private var showExpiryAlert = false

    private var remaining: Int { max(monthlyBudget - spentAmount, 0) }
    private var budgetRatio: Double {
        guard monthlyBudget > 0 else { return 0 }
        return min(Double(spentAmount) / Double(monthlyBudget), 1.0)
    }
    private var progressColor: Color {
        budgetRatio > 0.9 ? .red : budgetRatio > 0.7 ? .orange : Color(hex: "1D9E75")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    budgetCard
                    todayMealCard
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("ホーム")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showExpiryAlert = true
                    } label: {
                        Image(systemName: "bell.badge")
                            .tint(Color(hex: "1D9E75"))
                    }
                }
            }
            .sheet(isPresented: $showExpiryAlert) {
                NavigationStack { ExpiryAlertView() }
            }
            .task { await loadTodayMeals() }
        }
    }

    private var budgetCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("今月の食費")
                    .font(.headline)
                Spacer()
            }

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("¥\(remaining.formatted())")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(progressColor)
                Text("残り")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemFill))
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(progressColor)
                        .frame(width: geo.size.width * budgetRatio, height: 8)
                }
            }
            .frame(height: 8)

            HStack {
                Text("支出: ¥\(spentAmount.formatted())")
                    .font(.caption).foregroundColor(.secondary)
                Spacer()
                Text("予算: ¥\(monthlyBudget.formatted())")
                    .font(.caption).foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    private var todayMealCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("今日のおすすめ献立")
                    .font(.headline)
                Spacer()
                if isLoadingMeals {
                    ProgressView().scaleEffect(0.8)
                } else {
                    Button {
                        Task { await loadTodayMeals() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .tint(Color(hex: "1D9E75"))
                    }
                }
            }

            if isLoadingMeals {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        ProgressView()
                        Text("AIが考えています…")
                            .font(.caption).foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding()
            } else {
                let labels = ["朝", "昼", "夜"]
                ForEach(Array(todayMeals.enumerated()), id: \.offset) { i, meal in
                    HStack(spacing: 12) {
                        Text(i < labels.count ? labels[i] : "")
                            .font(.caption).fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(width: 24).padding(.vertical, 2)
                            .background(Color(hex: "1D9E75")).cornerRadius(4)
                        Text(meal).font(.subheadline)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    private func loadTodayMeals() async {
        isLoadingMeals = true
        defer { isLoadingMeals = false }
        let avoidFoods = UserDefaults.standard.string(forKey: "avoidFoods") ?? "なし"
        do {
            let response = try await ClaudeAPIClient.shared.send(
                systemPrompt: "あなたは家庭料理の献立アドバイザーです。JSONのみ返してください。",
                userMessage: """
                一人暮らしの今日の朝・昼・夜の献立を提案してください。
                苦手食材：\(avoidFoods)
                JSON形式のみで返答：{"meals": ["朝食名", "昼食名", "夕食名"]}
                """
            )
            let clean = response
                .replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if let data = clean.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let meals = json["meals"] as? [String] {
                todayMeals = meals
            } else {
                todayMeals = ["ご飯・味噌汁", "うどん", "焼き魚定食"]
            }
        } catch {
            todayMeals = ["ご飯・味噌汁", "うどん", "焼き魚定食"]
        }
    }
}

#Preview {
    HomeView()
}
