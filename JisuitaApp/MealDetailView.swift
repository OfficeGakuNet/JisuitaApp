import SwiftUI

struct MealDetailView: View {
    @Binding var slot: MealSlot
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section("料理名") {
                TextField("料理名を入力", text: $slot.name)
            }

            Section("自炊設定") {
                Toggle("自炊する", isOn: $slot.isCooking)
                    .tint(Color(hex: "1D9E75"))
            }

            Section("メモ") {
                TextField("メモを入力", text: $slot.memo, axis: .vertical)
                    .lineLimit(4, reservesSpace: true)
            }
        }
        .scrollContentBackground(.visible)
        .background(Color(.systemGroupedBackground))
        .navigationTitle("\(slot.day) \(slot.mealTime)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("完了") { dismiss() }
                    .foregroundColor(Color(hex: "1D9E75"))
            }
        }
    }
}
