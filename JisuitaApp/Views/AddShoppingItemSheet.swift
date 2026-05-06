import SwiftUI

struct AddShoppingItemSheet: View {
    let onAdd: (ShoppingItem) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var amount = ""
    @State private var category: ShoppingCategory = .other

    private var canAdd: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section("食材情報") {
                    TextField("食材名", text: $name)
                    TextField("量（例: 1本、200g）", text: $amount)
                }

                Section("カテゴリ") {
                    Picker("カテゴリ", selection: $category) {
                        ForEach(ShoppingCategory.allCases, id: \.self) { cat in
                            Label(cat.rawValue, systemImage: cat.icon)
                                .tag(cat)
                        }
                    }
                    .pickerStyle(.wheel)
                }
            }
            .navigationTitle("食材を追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("追加") {
                        let item = ShoppingItem(
                            name: name.trimmingCharacters(in: .whitespaces),
                            amount: amount.isEmpty ? "適量" : amount,
                            category: category
                        )
                        onAdd(item)
                        dismiss()
                    }
                    .disabled(!canAdd)
                    .tint(Color(hex: "1D9E75"))
                }
            }
        }
    }
}
