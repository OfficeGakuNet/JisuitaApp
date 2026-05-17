import SwiftUI

struct ReceiptItem: Identifiable {
    let id = UUID()
    var name: String
    var price: Int
    var isFoodExpense: Bool
}

struct ReceiptReviewView: View {
    @ObservedObject var budgetViewModel: BudgetViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var items: [ReceiptItem] = [
        ReceiptItem(name: "鶏もも肉", price: 398, isFoodExpense: true),
        ReceiptItem(name: "牛乳", price: 198, isFoodExpense: true),
        ReceiptItem(name: "卵", price: 248, isFoodExpense: true),
        ReceiptItem(name: "洗剤", price: 158, isFoodExpense: false),
        ReceiptItem(name: "ほうれん草", price: 148, isFoodExpense: true)
    ]

    @State private var navigateToComplete = false

    private var foodTotal: Int {
        items.filter(\.isFoodExpense).reduce(0) { $0 + $1.price }
    }

    private var foodItems: [ReceiptItem] {
        items.filter(\.isFoodExpense)
    }

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("読み取り結果")) {
                    ForEach($items) { $item in
                        HStack {
                            Toggle(isOn: $item.isFoodExpense) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.name)
                                        .font(.body)
                                    Text(item.isFoodExpense ? "食費に含める" : "食費に含めない")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .tint(Color(hex: "1D9E75"))
                            Spacer()
                            Text("¥\(item.price.formatted())")
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Section(header: Text("食費合計")) {
                    HStack {
                        Text("合計")
                            .fontWeight(.semibold)
                        Spacer()
                        Text("¥\(foodTotal.formatted())")
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
                    Button("反映する") {
                        budgetViewModel.addSpending(foodTotal)
                        navigateToComplete = true
                    }
                    .tint(Color(hex: "1D9E75"))
                }
            }
            .navigationDestination(isPresented: $navigateToComplete) {
                BudgetUpdateCompleteView(
                    addedAmount: foodTotal,
                    viewModel: budgetViewModel
                )
            }
        }
    }
}
