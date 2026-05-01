import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var settings: UserSettings
    @StateObject private var budgetViewModel = BudgetViewModel()
    @State private var todayMeals: [String] = []
    @State private var isLoadingMeals = false
    @State private var mealError: String? = nil
    @State private var showBudgetInput = false
    @State private var showExpiryAlert = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    budgetCard
                    familySummaryCard
                    todayMealCard
                    restrictionCard
                }
                .padding()
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
            .sheet(isPresented: $showBudgetInput) {
                BudgetInputView(viewModel: budgetViewModel)
            }
            .sheet(isPresented: $showExpiryAlert) {
                NavigationStack {
                    ExpiryAlertView()
                }
            }
            .task(id: settings.buildPersonalizedPromptContext()) {
                await loadTodayMeals()
            }
        }
    }

    private var budgetCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("今月の食費")
                    .font(.headline)
                Spacer()
                Button("記録する") {
                    showBudgetInput = true
                }
                .font(.subheadline)
                .tint(Color(hex: "1D9E75"))
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

    private var familySummaryCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.3.fill")
                .foregroundColor(Color(hex: "1D9E75"))
                .font(.title2)
            VStack(alignment: .leading, spacing: 2) {
                Text("家族構成")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(settings.familySummary)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            Spacer()
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
                    ProgressView()
                        .scaleEffect(0.8)
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
                    .foregroundColor(.red)
            } else if isLoadingMeals {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        ProgressView()
                        Text("AIが献立を考えています...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding()
            } else {
                ForEach(Array(todayMeals.enumerated()), id: \.offset) { index, meal in
                    let labels = ["朝", "昼", "夜"]
                    HStack(spacing: 12) {
                        Text(index < labels.count ? labels[index] : "")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .frame(width: 24)
                            .foregroundColor(.white)
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

    private var restrictionCard: some View {
        Group {
            let summary = settings.restrictionsSummary
            if summary != "なし" {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.shield.fill")
                        .foregroundColor(.orange)
                        .font(.title2)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("食の制限・アレルギー")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(summary)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    Spacer()
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(12)
            }
        }
    }

    private func loadTodayMeals() async {
        isLoadingMeals = true
        mealError = nil
        defer { isLoadingMeals = false }

        let context = settings.buildPersonalizedPromptContext()
        let systemPrompt = """
        あなたは家庭料理の献立アドバイザーです。
        ユーザーの設定情報に基づいて、今日1日の朝・昼・夜の献立を提案してください。
        必ず以下のJSON形式のみで返答してください：
        {"meals": ["朝食名", "昼食名", "夕食名"]}
        """
        let userMessage = """
        以下の条件で今日の献立を提案してください。

        \(context)

        料理名のみ簡潔に、3食分をJSON形式で返してください。
        """

        do {
            let response = try await ClaudeAPIClient.shared.send(
                systemPrompt: systemPrompt,
                userMessage: userMessage
            )
            let meals = parseMealsFromJSON(response)
            todayMeals = meals.isEmpty ? ["ご飯・味噌汁", "うどん", "焼き魚定食"] : meals
        } catch {
            mealError = error.localizedDescription
        }
    }

    private func parseMealsFromJSON(_ text: String) -> [String] {
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let meals = json["meals"] as? [String] else {
            return []
        }
        return meals
    }
}
