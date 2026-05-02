import SwiftUI

struct SettingsTabView: View {
    @EnvironmentObject private var settings: UserSettings

    @State private var showBudgetEditor = false
    @State private var showDietaryEditor = false
    @State private var showAllergyEditor = false
    @State private var showDislikedEditor = false
    @State private var showCuisineEditor = false

    var body: some View {
        NavigationStack {
            List {
                Section("食費予算") {
                    Button {
                        showBudgetEditor = true
                    } label: {
                        HStack {
                            Label("月間予算", systemImage: "yensign.circle.fill")
                                .foregroundColor(.primary)
                            Spacer()
                            Text("¥\(settings.monthlyBudget.formatted())")
                                .foregroundColor(.secondary)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Section("食の制限・好み") {
                    Button {
                        showAllergyEditor = true
                    } label: {
                        HStack {
                            Label("アレルギー", systemImage: "exclamationmark.shield.fill")
                                .foregroundColor(.primary)
                            Spacer()
                            Text(settings.allergies.isEmpty ? "なし" : settings.allergies.joined(separator: "・"))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Button {
                        showDietaryEditor = true
                    } label: {
                        HStack {
                            Label("食の制限", systemImage: "leaf.fill")
                                .foregroundColor(.primary)
                            Spacer()
                            Text(settings.dietaryRestrictions.isEmpty ? "なし" : settings.dietaryRestrictions.joined(separator: "・"))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Button {
                        showDislikedEditor = true
                    } label: {
                        HStack {
                            Label("苦手な食材", systemImage: "hand.thumbsdown.fill")
                                .foregroundColor(.primary)
                            Spacer()
                            Text(settings.dislikedIngredients.isEmpty ? "なし" : settings.dislikedIngredients.joined(separator: "・"))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Button {
                        showCuisineEditor = true
                    } label: {
                        HStack {
                            Label("好みの料理ジャンル", systemImage: "fork.knife.circle.fill")
                                .foregroundColor(.primary)
                            Spacer()
                            Text(settings.preferredCuisines.isEmpty ? "なし" : settings.preferredCuisines.joined(separator: "・"))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Section("料理スキル") {
                    Picker(selection: $settings.cookingSkill) {
                        Text("初心者").tag("初心者")
                        Text("普通").tag("普通")
                        Text("上級者").tag("上級者")
                    } label: {
                        Label("スキルレベル", systemImage: "star.fill")
                    }
                }

                Section("固定メニュー") {
                    NavigationLink {
                        FixedMenuSettingView()
                    } label: {
                        Label("固定メニューを管理", systemImage: "pin.fill")
                    }
                }

                Section("通知") {
                    NavigationLink {
                        ExpiryAlertView()
                    } label: {
                        Label("食材の期限アラート", systemImage: "bell.badge.fill")
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showBudgetEditor) {
                BudgetEditorView()
                    .environmentObject(settings)
            }
            .sheet(isPresented: $showAllergyEditor) {
                TagEditorView(
                    title: "アレルギー",
                    subtitle: "アレルギーのある食材を追加してください",
                    suggestions: ["卵", "乳", "小麦", "そば", "落花生", "えび", "かに", "くるみ"],
                    tags: $settings.allergies
                )
            }
            .sheet(isPresented: $showDietaryEditor) {
                TagEditorView(
                    title: "食の制限",
                    subtitle: "該当する食の制限を追加してください",
                    suggestions: ["ベジタリアン", "ヴィーガン", "グルテンフリー", "ハラール", "糖質制限", "塩分制限", "低カロリー"],
                    tags: $settings.dietaryRestrictions
                )
            }
            .sheet(isPresented: $showDislikedEditor) {
                TagEditorView(
                    title: "苦手な食材",
                    subtitle: "苦手・避けたい食材を追加してください",
                    suggestions: ["レバー", "パクチー", "納豆", "セロリ", "ピーマン", "にんにく", "しょうが"],
                    tags: $settings.dislikedIngredients
                )
            }
            .sheet(isPresented: $showCuisineEditor) {
                TagEditorView(
                    title: "好みの料理ジャンル",
                    subtitle: "好きな料理のジャンルを追加してください",
                    suggestions: ["和食", "洋食", "中華", "イタリアン", "アジアン", "メキシカン", "丼もの", "麺類"],
                    tags: $settings.preferredCuisines
                )
            }
        }
    }
}

struct BudgetEditorView: View {
    @EnvironmentObject private var settings: UserSettings
    @Environment(\.dismiss) private var dismiss
    @State private var inputText = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("月間食費予算") {
                    HStack {
                        Text("¥")
                            .foregroundColor(.secondary)
                        TextField("30000", text: $inputText)
                            .keyboardType(.numberPad)
                    }
                }
                Section {
                    Text("月初めに自動的にリセットされます。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("予算設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        if let value = Int(inputText), value > 0 {
                            settings.monthlyBudget = value
                        }
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .tint(Color(hex: "1D9E75"))
                }
            }
            .onAppear {
                inputText = "\(settings.monthlyBudget)"
            }
        }
    }
}

struct TagEditorView: View {
    let title: String
    let subtitle: String
    let suggestions: [String]
    @Binding var tags: [String]
    @Environment(\.dismiss) private var dismiss
    @State private var inputText = ""
    @State private var localTags: [String] = []

    var body: some View {
        NavigationStack {
            List {
                Section(subtitle) {
                    HStack {
                        TextField("追加する項目を入力", text: $inputText)
                        Button {
                            let trimmed = inputText.trimmingCharacters(in: .whitespaces)
                            guard !trimmed.isEmpty, !localTags.contains(trimmed) else { return }
                            localTags.append(trimmed)
                            inputText = ""
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(Color(hex: "1D9E75"))
                        }
                    }
                }

                if !localTags.isEmpty {
                    Section("設定済み") {
                        ForEach(localTags, id: \.self) { tag in
                            HStack {
                                Text(tag)
                                Spacer()
                                Button {
                                    localTags.removeAll { $0 == tag }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                Section("よく使われる項目") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
                        ForEach(suggestions, id: \.self) { suggestion in
                            let isSelected = localTags.contains(suggestion)
                            Button {
                                if isSelected {
                                    localTags.removeAll { $0 == suggestion }
                                } else {
                                    localTags.append(suggestion)
                                }
                            } label: {
                                Text(suggestion)
                                    .font(.subheadline)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(isSelected ? Color(hex: "1D9E75") : Color(.secondarySystemGroupedBackground))
                                    .foregroundColor(isSelected ? .white : .primary)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        tags = localTags
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .tint(Color(hex: "1D9E75"))
                }
            }
            .onAppear { localTags = tags }
        }
    }
}
