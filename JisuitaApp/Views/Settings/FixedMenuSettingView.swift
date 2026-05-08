import SwiftUI

struct FixedMenuSettingView: View {
    @State private var menus: [FixedMenu] = FixedMenuStore.load()
    @State private var isAdding = false

    private let mealTimes = ["朝", "昼", "夜"]
    private let allDays = ["月", "火", "水", "木", "金", "土", "日"]

    var body: some View {
        List {
            Section {
                ForEach($menus) { $menu in
                    FixedMenuRow(menu: $menu, allDays: allDays, mealTimes: mealTimes)
                        .onChange(of: menu) { _ in
                            FixedMenuStore.save(menus)
                        }
                }
                .onDelete { indexSet in
                    menus.remove(atOffsets: indexSet)
                    FixedMenuStore.save(menus)
                }

                Button {
                    isAdding = true
                } label: {
                    Label("固定メニューを追加", systemImage: "plus.circle.fill")
                        .foregroundColor(Color(hex: "1D9E75"))
                }
            } footer: {
                Text("有効にしたメニューは献立画面の初期値として自動で反映され、AI提案の対象から除外されます。")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("固定メニューの登録")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $isAdding) {
            AddFixedMenuSheet(allDays: allDays, mealTimes: mealTimes) { newMenu in
                menus.append(newMenu)
                FixedMenuStore.save(menus)
            }
        }
    }
}

private struct FixedMenuRow: View {
    @Binding var menu: FixedMenu
    let allDays: [String]
    let mealTimes: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(menu.name.isEmpty ? "（名前未設定）" : menu.name)
                        .font(.body)
                        .foregroundColor(menu.name.isEmpty ? .secondary : .primary)
                    Text("\(menu.mealTime)食 ／ \(menu.days.joined(separator: "・"))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Toggle("", isOn: $menu.isEnabled)
                    .labelsHidden()
                    .tint(Color(hex: "1D9E75"))
            }
        }
        .padding(.vertical, 4)
    }
}

private struct AddFixedMenuSheet: View {
    let allDays: [String]
    let mealTimes: [String]
    let onAdd: (FixedMenu) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var selectedMealTime = "朝"
    @State private var selectedDays: Set<String> = []
    @State private var isEnabled = true

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && !selectedDays.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("メニュー名") {
                    TextField("例：ヨーグルト・バナナ", text: $name)
                }

                Section("食事のタイミング") {
                    Picker("食事", selection: $selectedMealTime) {
                        ForEach(mealTimes, id: \.self) { time in
                            Text(time).tag(time)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("曜日") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                        ForEach(allDays, id: \.self) { day in
                            let selected = selectedDays.contains(day)
                            Button {
                                if selected {
                                    selectedDays.remove(day)
                                } else {
                                    selectedDays.insert(day)
                                }
                            } label: {
                                Text(day)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(selected ? Color(hex: "1D9E75") : Color(.systemGray5))
                                    .foregroundColor(selected ? .white : .primary)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    Toggle("有効にする", isOn: $isEnabled)
                        .tint(Color(hex: "1D9E75"))
                }
            }
            .navigationTitle("固定メニューを追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("追加") {
                        let sorted = allDays.filter { selectedDays.contains($0) }
                        let menu = FixedMenu(
                            name: name.trimmingCharacters(in: .whitespaces),
                            mealTime: selectedMealTime,
                            days: sorted,
                            isEnabled: isEnabled
                        )
                        onAdd(menu)
                        dismiss()
                    }
                    .disabled(!isValid)
                    .tint(Color(hex: "1D9E75"))
                }
            }
        }
    }
}
