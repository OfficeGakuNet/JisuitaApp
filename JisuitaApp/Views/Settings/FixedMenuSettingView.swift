import SwiftUI

struct FixedMenuSettingView: View {
    @State private var menus: [FixedMenu] = FixedMenuStore.load()
    @State private var showingAddSheet = false

    private let allDays = ["月", "火", "水", "木", "金", "土", "日"]
    private let mealTimes = ["朝", "昼", "夜"]

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
            } header: {
                Text("登録済みの固定メニュー")
            } footer: {
                Text("有効にした固定メニューは献立の初期値として自動反映されます。")
            }

            Section {
                Button {
                    showingAddSheet = true
                } label: {
                    Label("固定メニューを追加", systemImage: "plus.circle.fill")
                        .foregroundColor(Color(hex: "1D9E75"))
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("固定メニューの登録")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            EditButton()
                .tint(Color(hex: "1D9E75"))
        }
        .sheet(isPresented: $showingAddSheet) {
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
                VStack(alignment: .leading, spacing: 4) {
                    Text(menu.name.isEmpty ? "（名前未設定）" : menu.name)
                        .font(.headline)
                        .foregroundColor(menu.name.isEmpty ? .secondary : .primary)
                    Text("\(menu.mealTime)食 · \(menu.days.joined(separator: "・"))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Toggle("", isOn: $menu.isEnabled)
                    .tint(Color(hex: "1D9E75"))
                    .labelsHidden()
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

                Section("適用する曜日") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                        ForEach(allDays, id: \.self) { day in
                            DayToggleButton(
                                day: day,
                                isSelected: selectedDays.contains(day)
                            ) {
                                if selectedDays.contains(day) {
                                    selectedDays.remove(day)
                                } else {
                                    selectedDays.insert(day)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    Button {
                        let menu = FixedMenu(
                            name: name,
                            mealTime: selectedMealTime,
                            days: allDays.filter { selectedDays.contains($0) },
                            isEnabled: true
                        )
                        onAdd(menu)
                        dismiss()
                    } label: {
                        HStack {
                            Spacer()
                            Text("追加する")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(canAdd ? Color(hex: "1D9E75") : Color.gray.opacity(0.4))
                        )
                    }
                    .disabled(!canAdd)
                }
            }
            .navigationTitle("固定メニューを追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                        .tint(Color(hex: "1D9E75"))
                }
            }
        }
    }

    private var canAdd: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && !selectedDays.isEmpty
    }
}

private struct DayToggleButton: View {
    let day: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(day)
                .font(.subheadline)
                .fontWeight(isSelected ? .bold : .regular)
                .foregroundColor(isSelected ? .white : .primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? Color(hex: "1D9E75") : Color(.systemGray5))
                )
        }
        .buttonStyle(.plain)
    }
}
