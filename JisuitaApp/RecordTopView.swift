import SwiftUI

struct TodayMealRecord: Identifiable {
    let id = UUID()
    let mealTime: String
    let mealName: String
    let calories: Int
    var status: MealStatus
}

enum MealStatus {
    case pending, eaten, skipped
}

struct RecordTopView: View {
    @State private var weight: Double = 62.4
    @State private var steps: Int = 7832
    @State private var calorieGoal: Int = 2000
    @State private var calorieConsumed: Int = 1340

    @State private var meals: [TodayMealRecord] = [
        TodayMealRecord(mealTime: "朝", mealName: "ヨーグルト・バナナ", calories: 280, status: .eaten),
        TodayMealRecord(mealTime: "昼", mealName: "お弁当（鶏の照り焼き）", calories: 620, status: .eaten),
        TodayMealRecord(mealTime: "夜", mealName: "豆腐とほうれん草の味噌汁定食", calories: 440, status: .pending)
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                weightCard
                calorieCard
                stepsCard
                mealListCard
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("記録")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: WeightGraphView()) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                }
            }
        }
    }

    private var weightCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Label("今日の体重", systemImage: "scalemass.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text(String(format: "%.1f", weight))
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("kg")
                        .foregroundColor(.secondary)
                }
                Text("HealthKit から自動取得")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "heart.fill")
                .font(.system(size: 36))
                .foregroundColor(Color(hex: "1D9E75").opacity(0.3))
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    private var calorieCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("カロリー進捗", systemImage: "flame.fill")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text("\(calorieConsumed)")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("/ \(calorieGoal) kcal")
                    .foregroundColor(.secondary)
            }

            ProgressView(value: Double(calorieConsumed), total: Double(calorieGoal))
                .tint(Color(hex: "1D9E75"))
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    private var stepsCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Label("歩数", systemImage: "figure.walk")
                    .font(.caption)
                    .foregroundColor(.secondary)
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text("\(steps.formatted())")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("歩")
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            Image(systemName: "figure.walk")
                .font(.system(size: 36))
                .foregroundColor(Color(hex: "1D9E75").opacity(0.3))
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    private var mealListCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("今日の食事")
                .font(.headline)

            ForEach($meals) { $meal in
                HStack {
                    Text(meal.mealTime)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
                        .background(Color(hex: "1D9E75"))
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        Text(meal.mealName)
                            .font(.subheadline)
                        Text("\(meal.calories) kcal")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    if meal.status == .pending {
                        Button("食べた") {
                            meal.status = .eaten
                            calorieConsumed += meal.calories
                        }
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color(hex: "1D9E75"))
                        .foregroundColor(.white)
                        .cornerRadius(8)

                        Button("スキップ") {
                            meal.status = .skipped
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    } else {
                        Text(meal.status == .eaten ? "食べた" : "スキップ")
                            .font(.caption)
                            .foregroundColor(meal.status == .eaten ? Color(hex: "1D9E75") : .secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

#Preview {
    NavigationStack {
        RecordTopView()
    }
}
