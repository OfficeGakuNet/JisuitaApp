import SwiftUI

// MARK: - データ型

struct Seasoning: Identifiable, Codable {
    var id = UUID()
    var name: String        // 例："醤油"
    var brand: String       // 例："キッコーマン"
    var totalAmount: String // 例："500ml"
    var level: SeasoningLevel
    var category: String    // 例："液体調味料"
}

enum SeasoningLevel: String, Codable, CaseIterable {
    case full    = "満タン"
    case twoThird = "2/3"
    case half    = "1/2"
    case oneThird = "1/3"
    case low     = "残り少し"

    var ratio: Double {
        switch self {
        case .full:      return 1.0
        case .twoThird:  return 0.67
        case .half:      return 0.5
        case .oneThird:  return 0.33
        case .low:       return 0.1
        }
    }

    var color: String {
        switch self {
        case .full, .twoThird: return "1D9E75"
        case .half:            return "e8a020"
        case .oneThird, .low:  return "e07060"
        }
    }
}

// MARK: - プリセット調味料リスト

struct SeasoningPreset {
    let name: String
    let category: String
    let unit: String // 容量の単位ヒント
}

let seasoningPresets: [String: [SeasoningPreset]] = [
    "液体調味料": [
        SeasoningPreset(name: "醤油", category: "液体調味料", unit: "ml"),
        SeasoningPreset(name: "みりん", category: "液体調味料", unit: "ml"),
        SeasoningPreset(name: "料理酒", category: "液体調味料", unit: "ml"),
        SeasoningPreset(name: "酢", category: "液体調味料", unit: "ml"),
        SeasoningPreset(name: "ごま油", category: "液体調味料", unit: "ml"),
        SeasoningPreset(name: "オリーブオイル", category: "液体調味料", unit: "ml"),
        SeasoningPreset(name: "サラダ油", category: "液体調味料", unit: "ml"),
        SeasoningPreset(name: "めんつゆ", category: "液体調味料", unit: "ml"),
        SeasoningPreset(name: "ポン酢", category: "液体調味料", unit: "ml"),
        SeasoningPreset(name: "ウスターソース", category: "液体調味料", unit: "ml"),
    ],
    "粉・固形調味料": [
        SeasoningPreset(name: "塩", category: "粉・固形調味料", unit: "g"),
        SeasoningPreset(name: "砂糖", category: "粉・固形調味料", unit: "g"),
        SeasoningPreset(name: "こしょう", category: "粉・固形調味料", unit: "g"),
        SeasoningPreset(name: "片栗粉", category: "粉・固形調味料", unit: "g"),
        SeasoningPreset(name: "小麦粉", category: "粉・固形調味料", unit: "g"),
        SeasoningPreset(name: "すりごま", category: "粉・固形調味料", unit: "g"),
    ],
    "ペースト・味噌": [
        SeasoningPreset(name: "味噌", category: "ペースト・味噌", unit: "g"),
        SeasoningPreset(name: "鶏がらスープの素", category: "ペースト・味噌", unit: "g"),
        SeasoningPreset(name: "コンソメ", category: "ペースト・味噌", unit: "g"),
        SeasoningPreset(name: "味の素", category: "ペースト・味噌", unit: "g"),
        SeasoningPreset(name: "マヨネーズ", category: "ペースト・味噌", unit: "g"),
        SeasoningPreset(name: "ケチャップ", category: "ペースト・味噌", unit: "g"),
    ],
    "乾物・その他": [
        SeasoningPreset(name: "乾燥わかめ", category: "乾物・その他", unit: "g"),
        SeasoningPreset(name: "お米", category: "乾物・その他", unit: "kg"),
        SeasoningPreset(name: "だし昆布", category: "乾物・その他", unit: "g"),
        SeasoningPreset(name: "かつおぶし", category: "乾物・その他", unit: "g"),
    ]
]

let seasoningCategoryOrder = ["液体調味料", "粉・固形調味料", "ペースト・味噌", "乾物・その他"]

// MARK: - メイン画面

struct SeasoningView: View {
    @State private var seasonings: [Seasoning] = Self.load()
    @State private var showAddSheet = false

    var groupedSeasonings: [(String, [Seasoning])] {
        var dict: [String: [Seasoning]] = [:]
        for s in seasonings {
            dict[s.category, default: []].append(s)
        }
        return seasoningCategoryOrder.compactMap { cat in
            guard let list = dict[cat], !list.isEmpty else { return nil }
            return (cat, list)
        }
    }

    var lowStockCount: Int {
        seasonings.filter { $0.level == .low || $0.level == .oneThird }.count
    }

    var body: some View {
        VStack(spacing: 0) {

            // 残り少ない警告バナー
            if lowStockCount > 0 {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(Color(hex: "e07060"))
                    Text("残り少ない調味料が\(lowStockCount)件あります")
                        .font(.subheadline)
                        .foregroundColor(Color(hex: "e07060"))
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(hex: "e07060").opacity(0.08))
            }

            if seasonings.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "basket")
                        .font(.system(size: 48))
                        .foregroundColor(.gray.opacity(0.4))
                    Text("調味料が登録されていません")
                        .foregroundColor(.gray)
                    Button {
                        showAddSheet = true
                    } label: {
                        Text("追加する")
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                            .background(Color(hex: "1D9E75"))
                            .cornerRadius(20)
                    }
                }
                Spacer()
            } else {
                List {
                    ForEach(groupedSeasonings, id: \.0) { category, items in
                        Section(header: Text(category).font(.subheadline).bold()) {
                            ForEach(items) { seasoning in
                                SeasoningRow(seasoning: seasoning) { updated in
                                    updateSeasoning(updated)
                                } onDelete: {
                                    deleteSeasoning(seasoning)
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("調味料管理")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            SeasoningAddSheet { newSeasoning in
                seasonings.append(newSeasoning)
                save()
            }
        }
    }

    private func updateSeasoning(_ updated: Seasoning) {
        if let i = seasonings.firstIndex(where: { $0.id == updated.id }) {
            seasonings[i] = updated
            save()
        }
    }

    private func deleteSeasoning(_ seasoning: Seasoning) {
        seasonings.removeAll { $0.id == seasoning.id }
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(seasonings) {
            UserDefaults.standard.set(data, forKey: "savedSeasonings")
        }
    }

    static func load() -> [Seasoning] {
        guard let data = UserDefaults.standard.data(forKey: "savedSeasonings"),
              let list = try? JSONDecoder().decode([Seasoning].self, from: data) else {
            return []
        }
        return list
    }
}

// MARK: - 調味料1行

struct SeasoningRow: View {
    let seasoning: Seasoning
    let onUpdate: (Seasoning) -> Void
    let onDelete: () -> Void

    @State private var showLevelPicker = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(seasoning.name)
                        .font(.headline)
                    if !seasoning.brand.isEmpty || !seasoning.totalAmount.isEmpty {
                        Text([seasoning.brand, seasoning.totalAmount].filter { !$0.isEmpty }.joined(separator: " "))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // 残量バッジ（タップで変更）
                Button {
                    showLevelPicker = true
                } label: {
                    Text(seasoning.level.rawValue)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color(hex: seasoning.level.color).opacity(0.12))
                        .foregroundColor(Color(hex: seasoning.level.color))
                        .cornerRadius(6)
                }
            }

            // プログレスバー
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.gray.opacity(0.15))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(hex: seasoning.level.color))
                        .frame(width: geo.size.width * seasoning.level.ratio, height: 6)
                }
            }
            .frame(height: 6)
        }
        .padding(.vertical, 4)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("削除", systemImage: "trash")
            }

            Button {
                var updated = seasoning
                updated.level = .full
                onUpdate(updated)
            } label: {
                Label("買い足し", systemImage: "cart.badge.plus")
            }
            .tint(Color(hex: "1D9E75"))
        }
        .confirmationDialog("残量を選択", isPresented: $showLevelPicker, titleVisibility: .visible) {
            ForEach(SeasoningLevel.allCases, id: \.self) { level in
                Button(level.rawValue) {
                    var updated = seasoning
                    updated.level = level
                    onUpdate(updated)
                }
            }
            Button("キャンセル", role: .cancel) {}
        }
    }
}

// MARK: - 追加シート

struct SeasoningAddSheet: View {
    let onAdd: (Seasoning) -> Void
    @Environment(\.dismiss) var dismiss

    @State private var mode: AddMode = .preset
    @State private var selectedCategory = seasoningCategoryOrder[0]
    @State private var selectedPresetName = ""
    @State private var brand = ""
    @State private var totalAmount = ""
    @State private var level: SeasoningLevel = .full

    enum AddMode { case preset, barcode }

    var presetsInCategory: [SeasoningPreset] {
        seasoningPresets[selectedCategory] ?? []
    }

    var selectedPreset: SeasoningPreset? {
        presetsInCategory.first { $0.name == selectedPresetName }
    }

    var unitHint: String {
        selectedPreset?.unit ?? ""
    }

    var body: some View {
        NavigationStack {
            Form {

                // 登録方法
                Section {
                    Picker("登録方法", selection: $mode) {
                        Text("リストから選ぶ").tag(AddMode.preset)
                        Text("バーコード").tag(AddMode.barcode)
                    }
                    .pickerStyle(.segmented)
                }

                if mode == .barcode {
                    Section {
                        HStack {
                            Spacer()
                            VStack(spacing: 12) {
                                Image(systemName: "barcode.viewfinder")
                                    .font(.system(size: 48))
                                    .foregroundColor(.gray.opacity(0.4))
                                Text("バーコードスキャンは\n近日実装予定です")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.vertical, 20)
                            Spacer()
                        }
                    }
                } else {

                    // カテゴリ選択（NavigationLink）
                    Section(header: Text("調味料を選ぶ")) {
                        NavigationLink {
                            // カテゴリ選択画面
                            List(seasoningCategoryOrder, id: \.self) { cat in
                                HStack {
                                    Text(cat)
                                    Spacer()
                                    if selectedCategory == cat {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(Color(hex: "1D9E75"))
                                    }
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedCategory = cat
                                    selectedPresetName = ""
                                    totalAmount = ""
                                }
                            }
                            .navigationTitle("カテゴリ")
                        } label: {
                            HStack {
                                Text("カテゴリ")
                                Spacer()
                                Text(selectedCategory)
                                    .foregroundColor(.secondary)
                            }
                        }

                        NavigationLink {
                            // 調味料選択画面
                            List(presetsInCategory, id: \.name) { preset in
                                HStack {
                                    Text(preset.name)
                                    Spacer()
                                    if selectedPresetName == preset.name {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(Color(hex: "1D9E75"))
                                    }
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedPresetName = preset.name
                                    totalAmount = ""
                                }
                            }
                            .navigationTitle("調味料")
                        } label: {
                            HStack {
                                Text("調味料")
                                Spacer()
                                Text(selectedPresetName.isEmpty ? "選択してください" : selectedPresetName)
                                    .foregroundColor(selectedPresetName.isEmpty ? .secondary : .primary)
                            }
                        }
                    }

                    // 詳細入力
                    Section(header: Text("詳細（任意）")) {
                        TextField("ブランド名（例：キッコーマン）", text: $brand)
                        TextField(unitHint.isEmpty ? "容量" : "容量（例：500\(unitHint)）", text: $totalAmount)
                    }

                    // 現在の残量
                    Section(header: Text("現在の残量")) {
                        VStack(spacing: 10) {
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.gray.opacity(0.15))
                                        .frame(height: 10)
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color(hex: level.color))
                                        .frame(width: geo.size.width * level.ratio, height: 10)
                                        .animation(.easeInOut(duration: 0.2), value: level)
                                }
                            }
                            .frame(height: 10)

                            HStack(spacing: 6) {
                                ForEach(SeasoningLevel.allCases, id: \.self) { l in
                                    Text(l.rawValue)
                                        .font(.caption)
                                        .fontWeight(level == l ? .bold : .regular)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 6)
                                        .frame(maxWidth: .infinity)
                                        .background(level == l
                                            ? Color(hex: l.color).opacity(0.15)
                                            : Color.gray.opacity(0.08))
                                        .foregroundColor(level == l
                                            ? Color(hex: l.color)
                                            : .secondary)
                                        .cornerRadius(6)
                                        .onTapGesture {
                                            level = l
                                        }
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("調味料を追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("追加") {
                        guard let preset = selectedPreset else { return }
                        let newSeasoning = Seasoning(
                            name: preset.name,
                            brand: brand,
                            totalAmount: totalAmount,
                            level: level,
                            category: preset.category
                        )
                        onAdd(newSeasoning)
                        dismiss()
                    }
                    .disabled(selectedPresetName.isEmpty)
                    .fontWeight(.bold)
                }
            }
        }
    }
}

// MARK: - プレビュー

#Preview {
    NavigationStack {
        SeasoningView()
    }
}
