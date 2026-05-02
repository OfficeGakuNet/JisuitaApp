import SwiftUI

struct HomeView: View {
    @StateObject private var budgetViewModel = BudgetViewModel()
    @State private var todayMeals: [String] = []
    @State private var isLoadingMeals = false
    @State private var mealError: String? = nil
    @State private var showExpiryAlert = false

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
                NavigationStack {
                    ExpiryAlertView()
                }
            }
            .task {
                await loadTodayMeals()
            }
        }
    }

    // MARK: - 今月の食費カード

    private var budgetCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("今月の食費")
                    .font(.headline)
                Spacer()
                NavigationLink(destination: BudgetSettingView()) {
                    Text("予算設定")
                        .font(.subheadline)
                        .tint(Color(hex: "1D9E75"))
                }
            }

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("¥\(budgetViewModel.remaining.formatted())")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(budgetViewModel.progressColor)
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
                        .fill(budgetViewModel.progressColor)
                        .frame(width: geo.size.width * budgetViewModel.budgetRatio, height: 8)
                }
            }
            .frame(height: 8)

            HStack {
                Text("支出: ¥\(budgetViewModel.spentAmount.formatted())")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("予算: ¥\(budgetViewModel.monthlyBudget.formatted())")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    // MARK: - 今日のおすすめ献立カード

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

            if let error = mealError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else if isLoadingMeals {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        ProgressView()
                        Text("AIが献立を考えています…")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding()
            } else {
                let labels = ["朝", "昼", "夜"]
                ForEach(Array(todayMeals.enumerated()), id: \.offset) { index, meal in
                    HStack(spacing: 12) {
                        Text(index < labels.count ? labels[index] : "")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(width: 24)
                            .padding(.vertical, 2)
                            .background(Color(hex: "1D9E75"))
                            .cornerRadius(4)
                        Text(meal)
                            .font(.subheadline)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    // MARK: - AI献立取得

    private func loadTodayMeals() async {
        isLoadingMeals = true
        mealError = nil
        defer { isLoadingMeals = false }

        let avoidFoods = UserDefaults.standard.string(forKey: "avoidFoods") ?? "なし"
        let userMessage = """
        一人暮らしの今日の朝・昼・夜の献立を提案してください。
        苦手食材・アレルギー：\(avoidFoods)（使わないでください）
        必ず以下のJSON形式のみで返してください：
        {"meals": ["朝食名", "昼食名", "夕食名"]}
        """

        do {
            let response = try await ClaudeAPIClient.shared.send(
                systemPrompt: "あなたは家庭料理の献立アドバイザーです。JSONのみ返してください。",
                userMessage: userMessage
            )
            let meals = parseMeals(from: response)
            todayMeals = meals.isEmpty ? ["ご飯・味噌汁", "うどん", "焼き魚定食"] : meals
        } catch {
            mealError = "献立の取得に失敗しました"
            todayMeals = ["ご飯・味噌汁", "うどん", "焼き魚定食"]
        }
    }

    private func parseMeals(from text: String) -> [String] {
        let clean = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let data = clean.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let meals = json["meals"] as? [String] else { return [] }
        return meals
    }
}

#Preview {
    HomeView()
}
