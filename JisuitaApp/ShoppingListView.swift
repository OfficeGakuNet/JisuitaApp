import SwiftUI

// MARK: - データ型

struct ShoppingItem: Identifiable {
    let id = UUID()
    let name: String
    let category: String
    var totalAmount: String
    var usages: [UsageInfo]
    var isChecked: Bool = false
}

struct UsageInfo {
    let day: String
    let mealTime: String
    let mealName: String
    let amount: String
}

// MARK: - カテゴリの順番定義

let categoryOrder = ["米・穀物", "野菜", "豆腐・納豆・卵・麺類", "魚", "肉", "その他"]

// MARK: - メイン画面

struct ShoppingListView: View {
    @State private var meals: [Meal] = []
    @State private var shoppingItems: [ShoppingItem] = []

    var body: some View {
        NavigationView {
            Group {
                if shoppingItems.isEmpty {
                    emptyView
                } else {
                    itemListView
                }
            }
            .navigationTitle("買い出しリスト")
            .onAppear {
                buildShoppingList()
            }
        }
    }

    // MARK: - カテゴリ別セクション表示

    private var itemListView: some View {
        List {
            ForEach(categoryOrder, id: \.self) { category in
                let items = shoppingItems.filter { $0.category == category }
                if !items.isEmpty {
                    Section(header: Text(category).font(.subheadline).fontWeight(.bold)) {
                        ForEach(items.indices, id: \.self) { index in
                            if let realIndex = shoppingItems.firstIndex(where: { $0.id == items[index].id }) {
                                ShoppingItemRow(item: $shoppingItems[realIndex])
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - 空の状態

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "cart")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.4))
            Text("献立を生成すると\n買い出しリストが自動で作られます")
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
        }
    }

    // MARK: - 献立から食材リストを組み立てる

    private func buildShoppingList() {
        if let data = UserDefaults.standard.data(forKey: "savedMealPlan"),
           let saved = try? JSONDecoder().decode([Meal].self, from: data) {
            meals = saved
        }

        guard let ingredientsData = UserDefaults.standard.data(forKey: "savedIngredients"),
              let ingredientsMap = try? JSONSerialization.jsonObject(with: ingredientsData) as? [String: [[String: String]]]
        else {
            shoppingItems = []
            return
        }

        var itemDict: [String: ShoppingItem] = [:]

        for meal in meals {
            guard let ingredients = ingredientsMap[meal.name] else { continue }

            for ingredient in ingredients {
                guard let name = ingredient["name"],
                      let amount = ingredient["amount"] else { continue }

                let category = ingredient["category"] ?? "その他"

                let usage = UsageInfo(
                    day: meal.day,
                    mealTime: meal.mealTime,
                    mealName: meal.name,
                    amount: amount
                )

                if var existing = itemDict[name] {
                    existing.usages.append(usage)
                    existing.totalAmount = mergedAmount(usages: existing.usages)
                    itemDict[name] = existing
                } else {
                    itemDict[name] = ShoppingItem(
                        name: name,
                        category: category,
                        totalAmount: amount,
                        usages: [usage]
                    )
                }
            }
        }

        shoppingItems = itemDict.values.sorted { $0.name < $1.name }
    }

    private func mergedAmount(usages: [UsageInfo]) -> String {
        // 単位を抽出して同じ単位なら合計する
        var total: Double = 0
        var unit: String = ""
        var canSum = true

        for usage in usages {
            let (value, u) = parseAmount(usage.amount)
            if let v = value {
                if unit.isEmpty { unit = u }
                if unit == u {
                    total += v
                } else {
                    canSum = false
                    break
                }
            } else {
                canSum = false
                break
            }
        }

        if canSum && !unit.isEmpty {
            // 小数点以下が不要なら整数で表示
            if total == total.rounded() {
                return "\(Int(total))\(unit)"
            } else {
                return "\(total)\(unit)"
            }
        }

        // 計算できない場合はそのまま並べる
        return usages.map { $0.amount }.joined(separator: " + ")
    }

    // 量の文字列から数値と単位を分離する
    private func parseAmount(_ amount: String) -> (Double?, String) {
        // ご飯の「膳」は200gとして換算
        if amount.hasSuffix("膳") {
            let numStr = amount.replacingOccurrences(of: "膳", with: "")
            if let value = Double(numStr) {
                let grams = value * 200
                return (grams, "g")
            }
        }
        let units = ["ml", "g", "個", "本", "枚", "袋", "丁", "玉", "切れ", "缶"]
        for unit in units {
            if amount.hasSuffix(unit) {
                let numStr = amount.replacingOccurrences(of: unit, with: "")
                if let value = Double(numStr) {
                    return (value, unit)
                }
            }
        }
        return (nil, "")
    }
}

// MARK: - 食材1行分

struct ShoppingItemRow: View {
    @Binding var item: ShoppingItem
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Button(action: { item.isChecked.toggle() }) {
                    Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 24))
                        .foregroundColor(item.isChecked ? .green : .gray)
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(.body)
                        .foregroundColor(item.isChecked ? .gray : .primary)
                    Text("合計：\(item.totalAmount)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Spacer()

                if item.usages.count > 1 {
                    Button(action: { withAnimation { isExpanded.toggle() } }) {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .foregroundColor(.gray)
                    }
                    .buttonStyle(.plain)
                } else if let usage = item.usages.first {
                    Text("\(usage.day)曜\(usage.mealTime)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)

            if isExpanded {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(item.usages, id: \.mealName) { usage in
                        HStack {
                            Text("・\(usage.day)曜 \(usage.mealTime)：\(usage.mealName)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(usage.amount)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.leading, 36)
                .padding(.bottom, 6)
                .transition(.opacity)
            }
        }
    }
}

#Preview {
    ShoppingListView()
}
