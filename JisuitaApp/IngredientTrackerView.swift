import SwiftUI

// MARK: - データ型

/// 食材1品の使用予定1行分
struct UsagePlan: Identifiable, Codable {
    var id = UUID()
    var day: String        // 例："木"
    var mealTime: String   // 例："昼"
    var dishName: String   // 例："お弁当（照り焼き）"
    var amount: String     // 例："100g"
    var isDone: Bool       // 使用済みかどうか
}

/// 食材トラッカーの1品
struct TrackerIngredient: Identifiable, Codable {
    var id = UUID()
    var name: String           // 例："鶏むね肉"
    var category: String       // 例："肉"
    var purchasedAmount: String // 例："300g"
    var remainingAmount: String // 例："200g"
    var purchasedValue: Double  // 計算用（数値）
    var remainingValue: Double  // 計算用（数値）
    var usagePlans: [UsagePlan]

    /// 使い切り予定かどうか（全usagePlansの合計 ≒ remaining）
    var isFullyPlanned: Bool {
        // 使用予定が1件以上あり、未定がない場合を「使い切り予定」とする
        !usagePlans.isEmpty
    }

    /// 使い道が未定かどうか
    var hasNoPlan: Bool {
        usagePlans.isEmpty
    }

    /// 残量の割合（0.0〜1.0）
    var remainingRatio: Double {
        guard purchasedValue > 0 else { return 0 }
        return min(remainingValue / purchasedValue, 1.0)
    }
}

// MARK: - メインビュー

struct IngredientTrackerView: View {

    // UserDefaultsから献立データを読み込んで表示するサンプルデータ
    // 実際の運用では MealPlanView の savedIngredients と連動させる
    @State private var ingredients: [TrackerIngredient] = Self.loadSampleData()

    let categoryOrder = ["米・穀物", "野菜", "豆腐・納豆・卵・麺類", "魚", "肉", "その他"]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {

                    // 期間ヘッダー（仮。将来的に献立の期間から自動生成）
                    periodHeader

                    // 食材カード一覧
                    LazyVStack(spacing: 12) {
                        ForEach(sortedIngredients) { ingredient in
                            IngredientTrackerCard(ingredient: ingredient) { updated in
                                updateIngredient(updated)
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.top, 12)
                    .padding(.bottom, 32)
                }
            }
            .background(Color(hex: "f5f5f0"))
            .navigationTitle("食材トラッカー")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // 期間ヘッダー
    private var periodHeader: some View {
        let today = Date()
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M/d（E）"
        let start = formatter.string(from: today)
        let end = formatter.string(from: Calendar.current.date(byAdding: .day, value: 3, to: today) ?? today)

        return Text("\(start) 〜 \(end) の使い切り計画")
            .font(.subheadline)
            .foregroundColor(.secondary)
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 4)
    }

    // 警告（未定）の食材を末尾に、使用済みを先頭に並べる
    private var sortedIngredients: [TrackerIngredient] {
        ingredients.sorted { a, b in
            if a.hasNoPlan != b.hasNoPlan { return !a.hasNoPlan } // 未定を末尾
            return a.name < b.name
        }
    }

    private func updateIngredient(_ updated: TrackerIngredient) {
        if let index = ingredients.firstIndex(where: { $0.id == updated.id }) {
            ingredients[index] = updated
        }
    }

    // MARK: サンプルデータ（開発確認用）
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
                    UsagePlan(day: "木", mealTime: "昼", dishName: "お弁当（照り焼き）", amount: "100g", isDone: true),
                    UsagePlan(day: "金", mealTime: "夜", dishName: "鶏むね炒め", amount: "200g", isDone: false)
                ]
            ),
            TrackerIngredient(
                name: "木綿豆腐",
                category: "豆腐・納豆・卵・麺類",
                purchasedAmount: "2丁",
                remainingAmount: "1丁",
                purchasedValue: 2,
                remainingValue: 1,
                usagePlans: [
                    UsagePlan(day: "木", mealTime: "朝", dishName: "味噌汁", amount: "1丁", isDone: true),
                    UsagePlan(day: "土", mealTime: "夜", dishName: "豆腐ハンバーグ", amount: "1丁", isDone: false)
                ]
            ),
            TrackerIngredient(
                name: "ほうれん草",
                category: "野菜",
                purchasedAmount: "1袋",
                remainingAmount: "1袋",
                purchasedValue: 1,
                remainingValue: 1,
                usagePlans: [] // 使い道未定 → 警告表示
            ),
            TrackerIngredient(
                name: "鮭の切り身",
                category: "魚",
                purchasedAmount: "2切れ",
                remainingAmount: "2切れ",
                purchasedValue: 2,
                remainingValue: 2,
                usagePlans: [
                    UsagePlan(day: "木", mealTime: "夜", dishName: "鮭の塩焼き", amount: "1切れ", isDone: false),
                    UsagePlan(day: "土", mealTime: "夜", dishName: "鮭のムニエル", amount: "1切れ", isDone: false)
                ]
            ),
            TrackerIngredient(
                name: "ブロッコリー",
                category: "野菜",
                purchasedAmount: "1株",
                remainingAmount: "1株",
                purchasedValue: 1,
                remainingValue: 1,
                usagePlans: [
                    UsagePlan(day: "金", mealTime: "昼", dishName: "お弁当（副菜）", amount: "1/2株", isDone: false),
                    UsagePlan(day: "日", mealTime: "夜", dishName: "ブロッコリー炒め", amount: "1/2株", isDone: false)
                ]
            )
        ]
    }
}

// MARK: - 食材カード

struct IngredientTrackerCard: View {
    let ingredient: TrackerIngredient
    let onUpdate: (TrackerIngredient) -> Void

    @State private var isExpanded: Bool = true

    var statusBadgeText: String {
        if ingredient.hasNoPlan { return "使い道が未定" }
        if ingredient.isFullyPlanned { return "使い切り予定" }
        return "一部未定"
    }

    var statusBadgeColor: Color {
        if ingredient.hasNoPlan { return Color(hex: "e07060") }
        return Color(hex: "1D9E75")
    }

    var cardBorderColor: Color {
        ingredient.hasNoPlan ? Color(hex: "e07060").opacity(0.5) : Color.clear
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // ── ヘッダー行 ──
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(ingredient.name)
                            .font(.headline)
                            .foregroundColor(.primary)

                        Text("購入 \(ingredient.purchasedAmount)　残り \(ingredient.remainingAmount)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    // ステータスバッジ
                    Text(statusBadgeText)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(statusBadgeColor.opacity(0.12))
                        .foregroundColor(statusBadgeColor)
                        .cornerRadius(6)
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 10)
            }

            // ── プログレスバー ──
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.15))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(ingredient.hasNoPlan ? Color(hex: "e07060") : Color(hex: "1D9E75"))
                        .frame(width: geo.size.width * ingredient.remainingRatio, height: 8)
                }
            }
            .frame(height: 8)
            .padding(.horizontal, 16)
            .padding(.bottom, 10)

            // ── 使用予定リスト（展開時のみ） ──
            if isExpanded {
                if ingredient.hasNoPlan {
                    // 使い道が未定の場合
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.caption)
                            .foregroundColor(Color(hex: "e07060"))
                        Text("献立に割り当てられていません")
                            .font(.caption)
                            .foregroundColor(Color(hex: "e07060"))
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 14)
                } else {
                    Divider()
                        .padding(.horizontal, 16)

                    VStack(spacing: 0) {
                        ForEach(ingredient.usagePlans) { plan in
                            UsagePlanRow(plan: plan) { updatedPlan in
                                var newIngredient = ingredient
                                if let i = newIngredient.usagePlans.firstIndex(where: { $0.id == updatedPlan.id }) {
                                    newIngredient.usagePlans[i] = updatedPlan
                                    // 使用済みにしたら残量を更新（簡易処理）
                                    let doneCount = newIngredient.usagePlans.filter { $0.isDone }.count
                                    let totalCount = newIngredient.usagePlans.count
                                    if totalCount > 0 {
                                        newIngredient.remainingValue = newIngredient.purchasedValue * Double(totalCount - doneCount) / Double(totalCount)
                                        let ratio = newIngredient.remainingValue / newIngredient.purchasedValue
                                        // 表示用の文字列を更新（簡易）
                                        newIngredient.remainingAmount = formatRemaining(
                                            newIngredient.purchasedAmount,
                                            ratio: ratio
                                        )
                                    }
                                }
                                onUpdate(newIngredient)
                            }
                        }
                    }
                    .padding(.bottom, 8)
                }
            }
        }
        .background(Color.white)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(cardBorderColor, lineWidth: 1.5)
        )
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
    }

    /// 残量の表示文字列を簡易生成
    private func formatRemaining(_ original: String, ratio: Double) -> String {
        if ratio <= 0 { return "0" }
        if ratio >= 1 { return original }
        // 元の数値と単位を分離して割合で表示
        let digits = original.filter { $0.isNumber || $0 == "." }
        let unit = original.filter { !$0.isNumber && $0 != "." }
        if let value = Double(digits) {
            let remaining = value * ratio
            let formatted = remaining == remaining.rounded() ? "\(Int(remaining))" : String(format: "%.1f", remaining)
            return "\(formatted)\(unit)"
        }
        return original
    }
}

// MARK: - 使用予定の1行

struct UsagePlanRow: View {
    let plan: UsagePlan
    let onToggle: (UsagePlan) -> Void

    var body: some View {
        HStack(spacing: 12) {
            // 曜日・時間帯
            Text("\(plan.day)・\(plan.mealTime)")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 44, alignment: .leading)

            // 料理名
            Text(plan.dishName)
                .font(.subheadline)
                .foregroundColor(plan.isDone ? .secondary : .primary)

            Spacer()

            // 使用量 ＋ ステータス
            if plan.isDone {
                Text("\(plan.amount) 使用済")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(Color(hex: "1D9E75"))
            } else {
                Button {
                    var updated = plan
                    updated.isDone = true
                    onToggle(updated)
                } label: {
                    Text("\(plan.amount) 予定")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(5)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(plan.isDone ? Color(hex: "f8f8f8") : Color.white)
    }
}

// MARK: - プレビュー

#Preview {
    IngredientTrackerView()
}
