import SwiftUI

struct ReceiptItem: Identifiable {
    let id = UUID()
    var name: String
    var price: Int
    var isFoodExpense: Bool
}

struct ReceiptReviewView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var budgetViewModel = BudgetViewModel()

    @State private var items: [ReceiptItem] = [
        ReceiptItem(name: "鶏もも肉", price: 398, isFoodExpense: true),
        ReceiptItem(name: "ほうれん草", price: 148, isFoodExpense: true),
        ReceiptItem(name: "豆腐", price: 88, isFoodExpense: true),
        ReceiptItem(name: "醤油", price: 258, isFoodExpense: true),
        ReceiptItem(name: "洗剤", price: 198, isFoodExpense: false),
        ReceiptItem(name: "ティッシュ", price: 298, isFoodExpense: false)
    ]

    @State private var showComplete = false

    private var totalFoodCost: Int {
        items.filter(\.isFoodExpense).reduce(0) { $0 + $1.price }
    }

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("食費に含める")) {
                    ForEach($items.filter { $0.isFoodExpense.wrappedValue }) { $item in
                        ReceiptItemRow(item: $item)
                    }
                }

                Section(header: Text("日用品など（食費に含めない）")) {
                    ForEach($items.filter { !$0.isFoodExpense.wrappedValue }) { $item in
                        ReceiptItemRow(item: $item)
                    }
                }

                Section {
                    HStack {
                        Text("食費合計")
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
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("反映する") {
                        budgetViewModel.addSpending(totalFoodCost)
                        showComplete = true
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(Color(hex: "1D9E75"))
                }
            }
            .navigationDestination(isPresented: $showComplete) {
                BudgetUpdateCompleteView(addedAmount: totalFoodCost, viewModel: budgetViewModel)
            }
        }
    }
}

private struct ReceiptItemRow: View {
    @Binding var item: ReceiptItem

    var body: some View {
        HStack {
            Toggle(isOn: $item.isFoodExpense) {
                HStack {
                    Text(item.name)
                    Spacer()
                    Text("¥\(item.price.formatted())")
                        .foregroundColor(.secondary)
                }
            }
            .tint(Color(hex: "1D9E75"))
        }
    }
}
