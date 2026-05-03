import SwiftUI

struct ShoppingItem: Identifiable, Codable {
    var id = UUID()
    var name: String
    var amount: String
    var isChecked: Bool = false
    var category: String = "その他"
}

struct ShoppingListView: View {
    @AppStorage("shoppingItems") private var shoppingItemsData: Data = Data()
    @State private var items: [ShoppingItem] = []
    @State private var showAddSheet = false
    @State private var showCheckedItems = true

    private var uncheckedItems: [ShoppingItem] { items.filter { !$0.isChecked } }
    private var checkedItems: [ShoppingItem] { items.filter { $0.isChecked } }

    var body: some View {
        Group {
            if items.isEmpty {
                emptyView
            } else {
                listView
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showAddSheet = true }) {
                    Image(systemName: "plus")
                }
                .tint(Color(hex: "1D9E75"))
            }
            ToolbarItem(placement: .navigationBarLeading) {
                if !checkedItems.isEmpty {
                    Button("完了済みを削除") { removeChecked() }
                        .font(.caption)
                        .tint(.red)
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddShoppingItemSheet { newItem in
                items.append(newItem)
                save()
            }
        }
        .onAppear { load() }
    }

    private var emptyView: some View {
        ContentUnavailableView(
            "買い出しリストが空です",
            systemImage: "cart",
            description: Text("+ボタンでアイテムを追加してください")
        )
    }

    private var listView: some View {
        List {
            if !uncheckedItems.isEmpty {
                Section("未購入 (\(uncheckedItems.count))") {
                    ForEach(uncheckedItems) { item in
                        ShoppingItemRow(item: item) { updated in
                            updateItem(updated)
                        }
                    }
                    .onDelete { indices in
                        deleteItems(from: uncheckedItems, at: indices)
                    }
                }
            }

            if !checkedItems.isEmpty {
                Section {
                    ForEach(checkedItems) { item in
                        ShoppingItemRow(item: item) { updated in
                            updateItem(updated)
                        }
                    }
                    .onDelete { indices in
                        deleteItems(from: checkedItems, at: indices)
                    }
                } header: {
                    HStack {
                        Text("購入済み (\(checkedItems.count))")
                        Spacer()
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func updateItem(_ updated: ShoppingItem) {
        if let idx = items.firstIndex(where: { $0.id == updated.id }) {
            items[idx] = updated
            save()
        }
    }

    private func deleteItems(from source: [ShoppingItem], at offsets: IndexSet) {
        let idsToDelete = offsets.map { source[$0].id }
        items.removeAll { idsToDelete.contains($0.id) }
        save()
    }

    private func removeChecked() {
        items.removeAll { $0.isChecked }
        save()
    }

    private func save() {
        shoppingItemsData = (try? JSONEncoder().encode(items)) ?? Data()
    }

    private func load() {
        items = (try? JSONDecoder().decode([ShoppingItem].self, from: shoppingItemsData)) ?? []
    }
}

private struct ShoppingItemRow: View {
    let item: ShoppingItem
    let onUpdate: (ShoppingItem) -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button {
                var updated = item
                updated.isChecked.toggle()
                onUpdate(updated)
            } label: {
                Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(item.isChecked ? Color(hex: "1D9E75") : .secondary)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.body)
                    .strikethrough(item.isChecked)
                    .foregroundColor(item.isChecked ? .secondary : .primary)
                if !item.amount.isEmpty {
                    Text(item.amount)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            if !item.category.isEmpty && item.category != "その他" {
                Text(item.category)
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(hex: "1D9E75").opacity(0.12))
                    .foregroundColor(Color(hex: "1D9E75"))
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 4)
    }
}

private struct AddShoppingItemSheet: View {
    let onAdd: (ShoppingItem) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var amount = ""
    @State private var category = "その他"

    private let categories = ["その他", "野菜", "肉・魚", "乳製品", "調味料", "冷凍食品", "飲み物", "お菓子"]

    var body: some View {
        NavigationStack {
            Form {
                Section("アイテム名") {
                    TextField("例: 鶏むね肉", text: $name)
                }
                Section("数量・単位") {
                    TextField("例: 300g", text: $amount)
                }
                Section("カテゴリ") {
                    Picker("カテゴリ", selection: $category) {
                        ForEach(categories, id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(.menu)
                }
            }
            .navigationTitle("アイテムを追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("追加") {
                        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                        let newItem = ShoppingItem(name: name.trimmingCharacters(in: .whitespaces), amount: amount, category: category)
                        onAdd(newItem)
                        dismiss()
                    }
                    .tint(Color(hex: "1D9E75"))
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
