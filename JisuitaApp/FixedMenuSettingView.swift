import SwiftUI

struct FixedMenu: Identifiable, Codable {
    var id = UUID()
    var name: String
    var mealTime: String
    var days: [String]
    var isEnabled: Bool
}

struct FixedMenuSettingView: View {
    @AppStorage("fixedMenus") private var fixedMenusData: Data = Data()
    @State private var fixedMenus: [FixedMenu] = []
    @State private var showAddSheet = false

    var body: some View {
        List {
            if fixedMenus.isEmpty {
                ContentUnavailableView(
                    "固定メニューなし",
                    systemImage: "pin.slash",
                    description: Text("毎日同じ朝食などを登録しておくと\n献立・買い出しに自動反映されます")
                )
            } else {
                ForEach($fixedMenus) { $menu in
                    FixedMenuRow(menu: $menu)
                }
                .onDelete { indices in
                    fixedMenus.remove(atOffsets: indices)
                    save()
                }
            }
        }
        .navigationTitle("固定メニュー")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showAddSheet = true }) {
                    Image(systemName: "plus")
                }
            }
            ToolbarItem(placement: .navigationBarLeading) {
                if !fixedMenus.isEmpty { EditButton() }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddFixedMenuSheet { newMenu in
                fixedMenus.append(newMenu)
                save()
            }
        }
        .onAppear { load() }
    }

    private func save() {
        fixedMenusData = (try? JSONEncoder().encode(fixedMenus)) ?? Data()
    }

    private func load() {
        fixedMenus = (try? JSONDecoder().decode([FixedMenu].self, from: fixedMenusData)) ?? []
        if fixedMenus.isEmpty {
            fixedMenus = [
                FixedMenu(name: "ヨーグルト・バナナ", mealTime: "朝", days: ["月", "火", "水", "木", "金"], isEnabled: true)
            ]
        }
    }
}

private struct FixedMenuRow: View {
    @Binding var menu: FixedMenu

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(menu.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(menu.isEnabled ? .primary : .secondary)
                HStack(spacing: 4) {
                    Text(menu.mealTime)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(hex: "1D9E75").opacity(0.15))
                        .foregroundColor(Color(hex: "1D9E75"))
                        .cornerRadius(4)
                    Text(menu.days.joined(separator: "・"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            Toggle("", isOn: $menu.isEnabled)
                .labelsHidden()
                .tint(Color(hex: "1D9E75"))
        }
        .padding(.vertical, 4)
    }
}

private struct AddFixedMenuSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onAdd: (FixedMenu) -> Void

    @State private var name = ""
    @State private var mealTime = "朝"
    @State private var selectedDays: Set<String> = ["月", "火", "水", "木", "金"]

    let mealTimes = ["朝", "昼", "夜"]
    let weekdays = ["月", "火", "水", "木", "金", "土", "日"]

    var body: some View {
        NavigationStack {
            Form {
                Section("メニュー名") {
                    TextField("例：ヨーグルト・バナナ", text: $name)
                }
                Section("食事の時間帯") {
                    Picker("時間帯", selection: $mealTime) {
                        ForEach(mealTimes, id: \.self) { Text($0) }
                    }
                    .pickerStyle(.segmented)
                }
                Section("固定する曜日") {
                    HStack(spacing: 8) {
                        ForEach(weekdays, id: \.self) { day in
                            Button(action: { toggle(day) }) {
                                Text(day)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .frame(width: 36, height: 36)
                                    .background(selectedDays.contains(day)
                                        ? Color(hex: "1D9E75")
                                        : Color(.systemFill))
                                    .foregroundColor(selectedDays.contains(day) ? .white : .primary)
                                    .clipShape(Circle())
                            }
                        }
                    }
                    .padding(.vertical, 4)
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
                        let menu = FixedMenu(
                            name: name,
                            mealTime: mealTime,
                            days: weekdays.filter { selectedDays.contains($0) },
                            isEnabled: true
                        )
                        onAdd(menu)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || selectedDays.isEmpty)
                }
            }
        }
    }

    private func toggle(_ day: String) {
        if selectedDays.contains(day) { selectedDays.remove(day) }
        else { selectedDays.insert(day) }
    }
}

#Preview {
    NavigationStack {
        FixedMenuSettingView()
    }
}
