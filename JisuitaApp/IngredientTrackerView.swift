import SwiftUI

// MARK: - データ型

struct UsagePlan: Identifiable, Codable {
    var id = UUID()
    var day: String
    var mealTime: String
    var dishName: String
    var amount: String
    var isDone: Bool
}

struct TrackerIngredient: Identifiable, Codable {
    var id = UUID()
    var name: String
    var category: String
    var purchasedAmount: String
    var remainingAmount: String
    var purchasedValue: Double
    var remainingValue: Double
    var usagePlans: [UsagePlan]

    var isFullyPlanned: Bool {
        !usagePlans.isEmpty
    }

    var hasNoPlan: Bool {
        usagePlans.isEmpty
    }

    var remainingRatio: Double {
        guard purchasedValue > 0 else { return 0 }
        return min(remainingValue / purchasedValue, 1.0)
    }
}

// MARK: - メインビュー

struct IngredientTrackerView: View {

    @State private var ingredients: [TrackerIngredient] = Self.loadSampleData()

    let categoryOrder = ["米・穀物", "野菜", "豆腐・納豆・卵・麺類", "魚", "肉", "その他"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                periodHeader

                LazyVStack(spacing: 12) {
                    ForEach(sortedIngredients) { ingredient in
                        IngredientTrackerCard(ingredient: ingredient) { updated in
                            updateIngredient(updated)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical, 12)
            }
        }
        .background(Color(.systemGroupedBackground))
    }

    private var periodHeader: some View {
        HStack {
            Image(systemName: "calendar")
                .foregroundColor(Color(hex: "1D9E75"))
            Text("今週の食材トラッカー")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(Color(.systemGroupedBackground))
    }

    private var sortedIngredients: [TrackerIngredient] {
        ingredients.sorted { lhs, rhs in
            let li = categoryOrder.firstIndex(of: lhs.category) ?? categoryOrder.count
            let ri = categoryOrder.firstIndex(of: rhs.category) ?? categoryOrder.count
            return li < ri
        }
    }

    private func updateIngredient(_ updated: TrackerIngredient) {
        if let idx = ingredients.firstIndex(where: { $0.id == updated.id }) {
            ingredients[idx] = updated
        }
    }

    static func loadSampleData() -> [TrackerIngredient] {
        [
            TrackerIngredient(
                name: "鶏むね肉",
                category: "肉",
                purchasedAmount: "300g",
                remainingAmount: "200g",
                purchasedValue: 300,
                remainingValue: 200,
                usagePlans: [
                    UsagePlan(day: "木", mealTime: "昼", dishName: "お弁当（照り焼き）", amount: "100g", isDone: false)
                ]
            ),
            TrackerIngredient(
                name: "ほうれん草",
                category: "野菜",
                purchasedAmount: "1束",
                remainingAmount: "1/2束",
                purchasedValue: 1,
                remainingValue: 0.5,
                usagePlans: [
                    UsagePlan(day: "水", mealTime: "夜", dishName: "ほうれん草の胡麻和え", amount: "1/2束", isDone: false)
                ]
            ),
            TrackerIngredient(
                name: "豆腐",
                category: "豆腐・納豆・卵・麺類",
                purchasedAmount: "1丁",
                remainingAmount: "1/2丁",
                purchasedValue: 1,
                remainingValue: 0.5,
                usagePlans: []
            )
        ]
    }
}

// MARK: - カードビュー

struct IngredientTrackerCard: View {
    let ingredient: TrackerIngredient
    let onUpdate: (TrackerIngredient) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(ingredient.name)
                        .font(.headline)
                    Text(ingredient.category)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(ingredient.remainingAmount)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(remainingColor)
                    Text("/ " + ingredient.purchasedAmount)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemFill))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(remainingColor)
                        .frame(width: geo.size.width * ingredient.remainingRatio, height: 6)
                }
            }
            .frame(height: 6)

            if ingredient.hasNoPlan {
                Label("使い道未定", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundColor(.orange)
            } else {
                ForEach(ingredient.usagePlans) { plan in
                    UsagePlanRow(plan: plan) { updated in
                        var copy = ingredient
                        if let idx = copy.usagePlans.firstIndex(where: { $0.id == updated.id }) {
                            copy.usagePlans[idx] = updated
                        }
                        onUpdate(copy)
                    }
                }
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    private var remainingColor: Color {
        if ingredient.remainingRatio > 0.5 {
            return Color(hex: "1D9E75")
        } else if ingredient.remainingRatio > 0.2 {
            return .orange
        } else {
            return .red
        }
    }
}

// MARK: - 使用予定行

private struct UsagePlanRow: View {
    let plan: UsagePlan
    let onToggle: (UsagePlan) -> Void

    var body: some View {
        HStack(spacing: 8) {
            Button {
                var updated = plan
                updated.isDone.toggle()
                onToggle(updated)
            } label: {
                Image(systemName: plan.isDone ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(plan.isDone ? Color(hex: "1D9E75") : .secondary)
            }
            .buttonStyle(.plain)

            Text("\(plan.day) \(plan.mealTime) · \(plan.dishName)")
                .font(.caption)
                .foregroundColor(plan.isDone ? .secondary : .primary)
                .strikethrough(plan.isDone)

            Spacer()

            Text(plan.amount)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}
