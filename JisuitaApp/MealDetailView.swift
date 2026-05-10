import SwiftUI

struct MealDetailView: View {
    @Binding var slot: MealSlot
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var memo: String
    @State private var isCooking: Bool

    init(slot: Binding<MealSlot>) {
        self._slot = slot
        self._name = State(initialValue: slot.wrappedValue.name)
        self._memo = State(initialValue: slot.wrappedValue.memo)
        self._isCooking = State(initialValue: slot.wrappedValue.isCooking)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("料理名") {
                    TextField("例：鶏むね肉の照り焼き", text: $name)
                }

                Section("メモ") {
                    TextField("補足や調理メモを入力", text: $memo, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section {
                    Toggle(isOn: $isCooking) {
                        Label("自炊する", systemImage: "flame")
                    }
                    .tint(Color(hex: "1D9E75"))

                    if !isCooking {
                        HStack(spacing: 6) {
                            Image(systemName: "info.circle")
                                .foregroundColor(.secondary)
                            Text("外食・テイクアウト扱いになります")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("自炊設定")
                }

                Section {
                    HStack {
                        Label("曜日", systemImage: "calendar")
                        Spacer()
                        Text(slot.day)
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Label("食事タイム", systemImage: "clock")
                        Spacer()
                        Text(slot.mealTime)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("スロット情報")
                }
            }
            .scrollContentBackground(.visible)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("\(slot.day) \(slot.mealTime)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                    .foregroundColor(Color(hex: "1D9E75"))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        slot.name = name.trimmingCharacters(in: .whitespaces).isEmpty ? "未設定" : name.trimmingCharacters(in: .whitespaces)
                        slot.memo = memo
                        slot.isCooking = isCooking
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(Color(hex: "1D9E75"))
                }
            }
        }
    }
}
