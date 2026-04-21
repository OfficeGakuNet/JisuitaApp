import SwiftUI

struct ReceiptItem: Identifiable {
    let id = UUID()
    let name: String
    let price: Int
    let category: ReceiptCategory
    var includedInFoodCost: Bool
}

enum ReceiptCategory {
    case food, household
}

struct ReceiptReviewView: View {
    @State private var items: [ReceiptItem] = [
        ReceiptItem(name: "鶏むね肉", price: 298, category: .food, includedInFoodCost: true),
        ReceiptItem(name: "ほうれん草", price: 148, category: .food, includedInFoodCost: true),
        ReceiptItem(name: "豆腐", price: 88, category: .food, includedInFoodCost: true),
        ReceiptItem(name: "醤油", price: 198, category: .food, includedInFoodCost: true),
        ReceiptItem(name: "ラップ", price: 198, category: .household, includedInFoodCost: false),
        ReceiptItem(name: "洗剤", price: 298, category: .household, includedInFoodCost: false)
    ]
    @State private var showComplete = false

    var foodItems: [ReceiptItem] { items.filter { $0.category == .food } }
    var householdItems: [ReceiptItem] { items.filter { $0.category == .household } }
    var totalFoodCost: Int { items.filter { $0.includedInFoodCost }.reduce(0) { $0 + $1.price } }

    var body: some View {
        List {
            Section(header: Text("食材")) {
                ForEach($items.filter { $0.wrappedValue.category == .food }) { $item in
                    ReceiptItemRow(item: $item)
                }
            }

            Section(header: Text("日用品")) {
                ForEach($items.filter { $0.wrappedValue.category == .household }) { $item in
                    ReceiptItemRow(item: $item)
                }
            }

            Section {
                HStack {
                    Text("食費として計上")
                        .fontWeight(.semibold)
                    Spacer()
                    Text("¥\(totalFoodCost.formatted())")
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: "1D9E75"))
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("読み取り結果の確認")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("反映する") { showComplete = true }
                    .fontWeight(.semibold)
                    .tint(Color(hex: "1D9E75"))
            }
        }
        .navigationDestination(isPresented: $showComplete) {
            BudgetUpdateCompleteView(addedAmount: totalFoodCost)
        }
    }
}

private struct ReceiptItemRow: View {
    @Binding var item: ReceiptItem

    var body: some View {
        HStack {
            Toggle(isOn: $item.includedInFoodCost) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(.subheadline)
                    Text("¥\(item.price.formatted())")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .tint(Color(hex: "1D9E75"))
        }
    }
}

#Preview {
    NavigationStack {
        ReceiptReviewView()
    }
}
