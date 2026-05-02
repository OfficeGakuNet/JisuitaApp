import SwiftUI

struct SettingsTabView: View {
    @EnvironmentObject private var userSettings: UserSettings

    var body: some View {
        NavigationStack {
            List {
                familySection
                budgetSection
                dietarySection
                menuSection
                appSection
            }
            .listStyle(.insetGrouped)
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var familySection: some View {
        Section {
            NavigationLink(destination: FamilySettingView()) {
                SettingsRow(
                    icon: "person.2.fill",
                    color: Color(hex: "1D9E75"),
                    title: "家族構成",
                    subtitle: userSettings.familySummary
                )
            }
        } header: {
            Text("家族・人数")
        }
    }

    private var budgetSection: some View {
        Section {
            NavigationLink(destination: BudgetSettingView()) {
                SettingsRow(
                    icon: "yensign.circle.fill",
                    color: .orange,
                    title: "月間食費予算",
                    subtitle: "¥\(userSettings.monthlyBudget.formatted())"
                )
            }
        } header: {
            Text("予算")
        }
    }

    private var dietarySection: some View {
        Section {
            NavigationLink(destination: DietarySettingView()) {
                SettingsRow(
                    icon: "leaf.fill",
                    color: .green,
                    title: "食の制限・アレルギー",
                    subtitle: userSettings.dietarySummary
                )
            }
            NavigationLink(destination: DislikedFoodsView()) {
                SettingsRow(
                    icon: "hand.thumbsdown.fill",
                    color: .red,
                    title: "苦手な食材",
                    subtitle: userSettings.dislikedFoodsSummary
                )
            }
            NavigationLink(destination: FavoriteCuisinesView()) {
                SettingsRow(
                    icon: "fork.knife",
                    color: .purple,
                    title: "好きな料理ジャンル",
                    subtitle: userSettings.favoriteCuisinesSummary
                )
            }
        } header: {
            Text("食の好み・制限")
        }
    }

    private var menuSection: some View {
        Section {
            NavigationLink(destination: FixedMenuSettingView()) {
                SettingsRow(
                    icon: "pin.fill",
                    color: .blue,
                    title: "固定メニュー",
                    subtitle: "毎日のルーティン食を登録"
                )
            }
        } header: {
            Text("献立")
        }
    }

    private var appSection: some View {
        Section {
            HStack {
                SettingsRow(
                    icon: "info.circle.fill",
                    color: .gray,
                    title: "バージョン",
                    subtitle: nil
                )
                Spacer()
                Text(appVersion)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        } header: {
            Text("アプリ情報")
        }
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}

private struct SettingsRow: View {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String?

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color)
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - FamilySettingView

struct FamilySettingView: View {
    @EnvironmentObject private var userSettings: UserSettings

    var body: some View {
        List {
            Section {
                Stepper(
                    value: $userSettings.adultCount,
                    in: 1...10
                ) {
                    HStack {
                        Text("大人")
                        Spacer()
                        Text("\(userSettings.adultCount)人")
                            .foregroundColor(.secondary)
                    }
                }
                Stepper(
                    value: $userSettings.childCount,
                    in: 0...10
                ) {
                    HStack {
                        Text("子ども")
                        Spacer()
                        Text("\(userSettings.childCount)人")
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text("人数")
            } footer: {
                Text("設定した人数はAIによる食材量・献立の提案に反映されます。")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("家族構成")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - BudgetSettingView

struct BudgetSettingView: View {
    @EnvironmentObject private var userSettings: UserSettings
    @State private var budgetText: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        List {
            Section {
                HStack {
                    Text("¥")
                        .foregroundColor(.secondary)
                    TextField("30000", text: $budgetText)
                        .keyboardType(.numberPad)
                        .focused($isFocused)
                }
            } header: {
                Text("月間予算")
            } footer: {
                Text("毎月1日に支出はリセットされます。")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("食費予算")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("保存") {
                    if let value = Int(budgetText), value > 0 {
                        userSettings.monthlyBudget = value
                        isFocused = false
                    }
                }
                .tint(Color(hex: "1D9E75"))
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("完了") { isFocused = false }
            }
        }
        .onAppear {
            budgetText = String(userSettings.monthlyBudget)
        }
    }
}

// MARK: - DietarySettingView

struct DietarySettingView: View {
    @EnvironmentObject private var userSettings: UserSettings

    private let options: [(String, String)] = [
        ("vegetarian", "ベジタリアン"),
        ("vegan", "ヴィーガン"),
        ("glutenFree", "グルテンフリー"),
        ("dairyFree", "乳製品なし"),
        ("halal", "ハラール"),
        ("lowSodium", "減塩")
    ]

    var body: some View {
        List {
            Section {
                ForEach(options, id: \.0) { key, label in
                    Toggle(label, isOn: Binding(
                        get: { userSettings.dietaryRestrictions.contains(key) },
                        set: { isOn in
                            if isOn {
                                userSettings.dietaryRestrictions.insert(key)
                            } else {
                                userSettings.dietaryRestrictions.remove(key)
                            }
                        }
                    ))
                    .tint(Color(hex: "1D9E75"))
                }
            } header: {
                Text("制限・スタイル")
            } footer: {
                Text("選択した制限はAIによる献立提案に反映されます。")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("食の制限")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - DislikedFoodsView

struct DislikedFoodsView: View {
    @EnvironmentObject private var userSettings: UserSettings
    @State private var newFood: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        List {
            Section {
                HStack {
                    TextField("例：レバー、セロリ", text: $newFood)
                        .focused($isFocused)
                    Button(action: addFood) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(Color(hex: "1D9E75"))
                    }
                    .disabled(newFood.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }

            if !userSettings.dislikedFoods.isEmpty {
                Section(header: Text("登録済み")) {
                    ForEach(userSettings.dislikedFoods, id: \.self) { food in
                        Text(food)
                    }
                    .onDelete { indices in
                        userSettings.dislikedFoods.remove(atOffsets: indices)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("苦手な食材")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("完了") { isFocused = false }
            }
        }
    }

    private func addFood() {
        let trimmed = newFood.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        userSettings.dislikedFoods.append(trimmed)
        newFood = ""
    }
}

// MARK: - FavoriteCuisinesView

struct FavoriteCuisinesView: View {
    @EnvironmentObject private var userSettings: UserSettings

    private let cuisines = [
        "和食", "洋食", "中華", "イタリアン", "フレンチ",
        "韓国料理", "タイ料理", "インド料理", "メキシコ料理", "その他"
    ]

    var body: some View {
        List {
            Section {
                ForEach(cuisines, id: \.self) { cuisine in
                    let isSelected = userSettings.favoriteCuisines.contains(cuisine)
                    Button(action: { toggle(cuisine) }) {
                        HStack {
                            Text(cuisine)
                                .foregroundColor(.primary)
                            Spacer()
                            if isSelected {
                                Image(systemName: "checkmark")
                                    .foregroundColor(Color(hex: "1D9E75"))
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                }
            } header: {
                Text("ジャンルを選択")
            } footer: {
                Text("選択したジャンルはAIによる献立提案の参考にされます。")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("好きな料理ジャンル")
        .navigationBarTitleDisplayMode(.large)
    }

    private func toggle(_ cuisine: String) {
        if userSettings.favoriteCuisines.contains(cuisine) {
            userSettings.favoriteCuisines.removeAll { $0 == cuisine }
        } else {
            userSettings.favoriteCuisines.append(cuisine)
        }
    }
}
