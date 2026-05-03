import SwiftUI

struct TrackedIngredient: Identifiable, Codable {
    var id = UUID()
    var name: String
    var quantity: String
    var unit: String
    var status: StockStatus
    var expiryDate: Date?
    var category: String = "その他"

    enum StockStatus: String, Codable, CaseIterable {
        case sufficient = "十分"
        case low = "少ない"
        case outOfStock = "在庫なし"

        var color: Color {
            switch self {
            case .sufficient: return Color(hex: "1D9E75")
            case .low: return .orange
            case .outOfStock: return .red
            }
        }

        var icon: String {
            switch self {
            case .sufficient: return "checkmark.circle.fill"
            case .low: return "exclamationmark.circle.fill"
            case .outOfStock: return "xmark.circle.fill"
            }
        }
    }
}

struct IngredientTrackerView: View {
    @AppStorage("trackedIngredients") private var ingredientsData: Data = Data()
    @State private var ingredients: [TrackedIngredient] = []
    @State private var showAddSheet = false
    @State private var selectedFilter: TrackedIngredient.StockStatus? = nil
    @State private var editingIngredient: TrackedIngredient? = nil

    private var filteredIngredients: [TrackedIngredient] {
        guard let filter = selectedFilter else { return ingredients }
        return ingredients.filter { $0.status == filter }
    }

    var body: some View {
        Group {
            if ingredients.isEmpty {
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
        }
        .sheet(isPresented: $showAddSheet) {
            AddIngredientSheet { newIngredient in
                ingredients.append(newIngredient)
                save()
            }
        }
        .sheet(item: $editingIngredient) { ingredient in
            EditIngredientSheet(ingredient: ingredient) { updated in
                if let idx = ingredients.firstIndex(where: { $0.id == updated.id }) {
                    ingredients[idx] = updated
                    save()
                }
            }
        }
        .onAppear { load() }
    }

    private var emptyView: some View {
        ContentUnavailableView(
            "食材が登録されていません",
            systemImage: "leaf",
            description: Text("+ボタンで食材を追加し\n在庫状況を管理しましょう")
        )
    }

    private var listView: some View {
        VStack(spacing: 0) {
            filterBar
            List {
                summarySection
                ForEach(filteredIngredients) { ingredient in
                    IngredientRow(ingredient: ingredient) {
                        editingIngredient = ingredient
                    } onStatusChange: { newStatus in
                        updateStatus(for: ingredient, to: newStatus)
                    }
                }
                .onDelete { indices in
                    deleteIngredients(from: filteredIngredients, at: indices)
                }
            }
            .listStyle(.insetGrouped)
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(label: "すべて", isSelected: selectedFilter == nil) {
                    selectedFilter = nil
                }
                ForEach(TrackedIngredient.StockStatus.allCases, id: \.self) { status in
                    FilterChip(label: status.rawValue, isSelected: selectedFilter == status) {
                        selectedFilter = selectedFilter == status ? nil : status
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(Color(.systemGroupedBackground))
    }

    private var summarySection: some View {
        Section {
            HStack(spacing: 0) {
                ForEach(TrackedIngredient.StockStatus.allCases, id: \.self) { status in
                    let count = ingredients.filter { $0.status == status }.count
                    VStack(spacing: 4) {
                        Text("\(count)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(status.color)
                        Text(status.rawValue)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, 8)
        }
    }

    private func updateStatus(for ingredient: TrackedIngredient, to status: TrackedIngredient.StockStatus) {
        if let idx = ingredients.firstIndex(where: { $0.id == ingredient.id }) {
            ingredients[idx].status = status
            save()
        }
    }

    private func deleteIngredients(from source: [TrackedIngredient], at offsets: IndexSet) {
        let idsToDelete = offsets.map { source[$0].id }
        ingredients.removeAll { idsToDelete.contains($0.id) }
        save()
    }

    private func save() {
        ingredientsData = (try? JSONEncoder().encode(ingredients)) ?? Data()
    }

    private func load() {
        ingredients = (try? JSONDecoder().decode([TrackedIngredient].self, from: ingredientsData)) ?? []
    }
}

private struct FilterChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color(hex: "1D9E75") : Color(.systemBackground))
                .foregroundColor(isSelected ? .white : .primary)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.clear : Color(.systemGray4), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

private struct IngredientRow: View {
    let ingredient: TrackedIngredient
    let onEdit: () -> Void
    let onStatusChange: (TrackedIngredient.StockStatus) -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: ingredient.status.icon)
                .font(.title3)
                .foregroundColor(ingredient.status.color)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(ingredient.name)
                    .font(.body)
                HStack(spacing: 4) {
                    if !ingredient.quantity.isEmpty {
                        Text("\(ingredient.quantity)\(ingredient.unit)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    if let expiry = ingredient.expiryDate {
                        Text("期限: \(expiry, style: .date)")
                            .font(.caption)
                            .foregroundColor(expiryColor(for: expiry))
                    }
                }
            }

            Spacer()

            Menu {
                ForEach(TrackedIngredient.StockStatus.allCases, id: \.self) { status in
                    Button {
                        onStatusChange(status)
                    } label: {
                        Label(status.rawValue, systemImage: status.icon)
                    }
                }
                Divider()
                Button(action: onEdit) {
                    Label("編集", systemImage: "pencil")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private func expiryColor(for date: Date) -> Color {
        let days = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
        if days <= 1 { return .red }
        if days <= 3 { return .orange }
        return .secondary
    }
}

private struct AddIngredientSheet: View {
    let onAdd: (TrackedIngredient) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var quantity = ""
    @State private var unit = "g"
    @State private var status: TrackedIngredient.StockStatus = .sufficient
    @State private var hasExpiry = false
    @State private var expiryDate = Date()
    @State private var category = "その他"

    private let units = ["g", "kg", "ml", "L", "個", "本", "袋", "枚", "缶", "パック"]
    private let categories = ["その他", "野菜", "肉・魚", "乳製品", "調味料", "冷凍食品", "飲み物"]

    var body: some View {
        NavigationStack {
            Form {
                Section("食材名") {
                    TextField("例: 鶏むね肉", text: $name)
                }
                Section("数量") {
                    HStack {
                        TextField("例: 300", text: $quantity)
                            .keyboardType(.decimalPad)
                        Picker("単位", selection: $unit) {
                            ForEach(units, id: \.self) { Text($0).tag($0) }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                    }
                }
                Section("在庫状況") {
                    Picker("状況", selection: $status) {
                        ForEach(TrackedIngredient.StockStatus.allCases, id: \.self) {
                            Text($0.rawValue).tag($0)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                Section("賞味期限") {
                    Toggle("設定する", isOn: $hasExpiry)
                        .tint(Color(hex: "1D9E75"))
                    if hasExpiry {
                        DatePicker("期限日", selection: $expiryDate, displayedComponents: .date)
                    }
                }
                Section("カテゴリ") {
                    Picker("カテゴリ", selection: $category) {
                        ForEach(categories, id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(.menu)
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
                        let newIngredient = TrackedIngredient(
                            name: name.trimmingCharacters(in: .whitespaces),
                            quantity: quantity,
                            unit: unit,
                            status: status,
                            expiryDate: hasExpiry ? expiryDate : nil,
                            category: category
                        )
                        onAdd(newIngredient)
                        dismiss()
                    }
                    .tint(Color(hex: "1D9E75"))
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

private struct EditIngredientSheet: View {
    let ingredient: TrackedIngredient
    let onSave: (TrackedIngredient) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var quantity: String
    @State private var unit: String
    @State private var status: TrackedIngredient.StockStatus
    @State private var hasExpiry: Bool
    @State private var expiryDate: Date
    @State private var category: String

    private let units = ["g", "kg", "ml", "L", "個", "本", "袋", "枚", "缶", "パック"]
    private let categories = ["その他", "野菜", "肉・魚", "乳製品", "調味料", "冷凍食品", "飲み物"]

    init(ingredient: TrackedIngredient, onSave: @escaping (TrackedIngredient) -> Void) {
        self.ingredient = ingredient
        self.onSave = onSave
        _name = State(initialValue: ingredient.name)
        _quantity = State(initialValue: ingredient.quantity)
        _unit = State(initialValue: ingredient.unit)
        _status = State(initialValue: ingredient.status)
        _hasExpiry = State(initialValue: ingredient.expiryDate != nil)
        _expiryDate = State(initialValue: ingredient.expiryDate ?? Date())
        _category = State(initialValue: ingredient.category)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("食材名") {
                    TextField("例: 鶏むね肉", text: $name)
                }
                Section("数量") {
                    HStack {
                        TextField("例: 300", text: $quantity)
                            .keyboardType(.decimalPad)
                        Picker("単位", selection: $unit) {
                            ForEach(units, id: \.self) { Text($0).tag($0) }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                    }
                }
                Section("在庫状況") {
                    Picker("状況", selection: $status) {
                        ForEach(TrackedIngredient.StockStatus.allCases, id: \.self) {
                            Text($0.rawValue).tag($0)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                Section("賞味期限") {
                    Toggle("設定する", isOn: $hasExpiry)
                        .tint(Color(hex: "1D9E75"))
                    if hasExpiry {
                        DatePicker("期限日", selection: $expiryDate, displayedComponents: .date)
                    }
                }
                Section("カテゴリ") {
                    Picker("カテゴリ", selection: $category) {
                        ForEach(categories, id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(.menu)
                }
            }
            .navigationTitle("食材を編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        var updated = ingredient
                        updated.name = name.trimmingCharacters(in: .whitespaces)
                        updated.quantity = quantity
                        updated.unit = unit
                        updated.status = status
                        updated.expiryDate = hasExpiry ? expiryDate : nil
                        updated.category = category
                        onSave(updated)
                        dismiss()
                    }
                    .tint(Color(hex: "1D9E75"))
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
