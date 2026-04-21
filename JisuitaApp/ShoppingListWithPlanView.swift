import SwiftUI

struct ShoppingListWithPlanView: View {
    @State private var items: [ShoppingItem] = ShoppingListWithPlanView.sampleItems()
    let shoppingCategoryOrder = ["米・穀物", "野菜", "豆腐・納豆・卵・麺類", "魚", "肉", "その他"]

    var groupedItems: [(String, [ShoppingItem])] {
        let dict = Dictionary(grouping: items, by: \.category)
        return shoppingCategoryOrder.compactMap { cat in
            guard let group = dict[cat], !group.isEmpty else { return nil }
            return (cat, group)
        }
    }

    var body: some View {
        List {
            ForEach(groupedItems, id: \.0) { category, group in
                Section(header: Text(category).font(.subheadline).fontWeight(.semibold)) {
                    ForEach(group) { item in
                        ShoppingPlanRow(item: item, onToggle: { toggle(item) })
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("買い出しリスト（使い切り計画）")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func toggle(_ item: ShoppingItem) {
        guard let idx = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[idx].isChecked.toggle()
    }

    static func sampleItems() -> [ShoppingItem] {
        [
            ShoppingItem(name: "鶏むね肉", category: "肉", totalAmount: "300g", usages: [
                UsageInfo(day: "月", mealTime: "夜", mealName: "鶏の照り焼き", amount: "150g"),
                UsageInfo(day: "水", mealTime: "昼", mealName: "お弁当（蒸し鶏）", amount: "150g")
            ]),
            ShoppingItem(name: "ほうれん草", category: "野菜", totalAmount: "1束", usages: [
                UsageInfo(day: "火", mealTime: "夜", mealName: "ほうれん草の胡麻和え", amount: "1/2束"),
                UsageInfo(day: "木", mealTime: "夜", mealName: "味噌汁", amount: "1/2束")
            ]),
            ShoppingItem(name: "豆腐", category: "豆腐・納豆・卵・麺類", totalAmount: "1丁", usages: [
                UsageInfo(day: "月", mealTime: "夜", mealName: "麻婆豆腐", amount: "1丁")
            ]),
            ShoppingItem(name: "白米", category: "米・穀物", totalAmount: "1kg", usages: [
                UsageInfo(day: "月", mealTime: "朝", mealName: "ご飯", amount: "150g"),
                UsageInfo(day: "火", mealTime: "朝", mealName: "ご飯", amount: "150g"),
                UsageInfo(day: "水", mealTime: "朝", mealName: "ご飯", amount: "150g")
            ])
        ]
    }
}

private struct ShoppingPlanRow: View {
    let item: ShoppingItem
    let onToggle: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Button(action: onToggle) {
                    Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(item.isChecked ? Color(hex: "1D9E75") : .secondary)
                        .font(.title3)
                }
                .buttonStyle(.plain)

                Text(item.name)
                    .fontWeight(.medium)
                    .strikethrough(item.isChecked, color: .secondary)
                    .foregroundColor(item.isChecked ? .secondary : .primary)

                Spacer()

                Text(item.totalAmount)
                    .foregroundColor(.secondary)
                    .font(.subheadline)
            }

            ForEach(item.usages, id: \.mealName) { usage in
                HStack(spacing: 4) {
                    Image(systemName: "arrow.right")
                        .font(.caption2)
                        .foregroundColor(Color(hex: "1D9E75"))
                    Text("\(usage.day)曜 \(usage.mealTime) · \(usage.mealName)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(usage.amount)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.leading, 32)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        ShoppingListWithPlanView()
    }
}
