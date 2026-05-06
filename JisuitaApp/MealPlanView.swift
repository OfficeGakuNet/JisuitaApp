import SwiftUI

struct MealPlanView: View {
    @EnvironmentObject private var viewModel: MealPlanViewModel
    @AppStorage("fixedMenus") private var fixedMenusData: Data = Data()
    @State private var isGenerating = false
    @State private var errorMessage: String?
    @State private var showError = false

    private let days = ["月", "火", "水", "木", "金", "土", "日"]
    private let mealTimes = ["朝", "昼", "夜"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(days, id: \.self) { day in
                        DayMealCard(
                            day: day,
                            slots: viewModel.slots.filter { $0.day == day },
                            isFixed: { mealTime in viewModel.isFixedSlot(day: day, mealTime: mealTime) },
                            onUpdate: { viewModel.updateSlot($0) }
                        )
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("今週の献立")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: generateMealPlan) {
                        if isGenerating {
                            ProgressView()
                        } else {
                            Label("AI提案", systemImage: "sparkles")
                        }
                    }
                    .disabled(isGenerating)
                    .tint(Color(hex: "1D9E75"))
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { viewModel.reloadWithFixedMenus() }) {
                        Image(systemName: "arrow.counterclockwise")
                    }
                    .tint(Color(hex: "1D9E75"))
                }
            }
            .alert("エラー", isPresented: $showError, actions: {
                Button("OK", role: .cancel) {}
            }, message: {
                Text(errorMessage ?? "")
            })
            .onAppear {
                viewModel.reloadWithFixedMenus()
            }
            .onChange(of: fixedMenusData) { _ in
                viewModel.reloadWithFixedMenus()
            }
        }
    }

    private func generateMealPlan() {
        isGenerating = true
        Task {
            defer { isGenerating = false }
            do {
                let targetSlots = viewModel.slotsForAISuggestion()
                let slotDescriptions = targetSlots.map { "\($0.day)曜\($0.mealTime)" }.joined(separator: "、")
                let systemPrompt = """
                あなたは家庭料理の献立プランナーです。
                指定されたスロットに対して、バランスの良い日本の家庭料理を提案してください。
                JSON配列で返してください。フォーマット: [{"day":"月","mealTime":"朝","name":"料理名"}]
                """
                let userMessage = "以下のスロットの献立を提案してください: \(slotDescriptions)"
                let response = try await ClaudeAPIClient.shared.send(systemPrompt: systemPrompt, userMessage: userMessage)
                let parsed = parseMealPlanResponse(response, targetSlots: targetSlots)
                viewModel.applyAIResult(parsed)
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    private func parseMealPlanResponse(_ response: String, targetSlots: [MealSlot]) -> [MealSlot] {
        guard let data = response.data(using: .utf8),
              let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: String]] else {
            return []
        }
        return jsonArray.compactMap { dict in
            guard let day = dict["day"], let mealTime = dict["mealTime"], let name = dict["name"],
                  let original = targetSlots.first(where: { $0.day == day && $0.mealTime == mealTime }) else {
                return nil
            }
            return MealSlot(id: original.id, day: day, mealTime: mealTime, name: name, isCooking: original.isCooking)
        }
    }
}

private struct DayMealCard: View {
    let day: String
    let slots: [MealSlot]
    let isFixed: (String) -> Bool
    let onUpdate: (MealSlot) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("\(day)曜日")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: "1D9E75"))
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            ForEach(slots) { slot in
                MealSlotRow(
                    slot: slot,
                    isFixed: isFixed(slot.mealTime),
                    onUpdate: onUpdate
                )
                if slot.mealTime != "夜" {
                    Divider().padding(.leading, 56)
                }
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

private struct MealSlotRow: View {
    let slot: MealSlot
    let isFixed: Bool
    let onUpdate: (MealSlot) -> Void
    @State private var showEdit = false

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(mealTimeColor(slot.mealTime).opacity(0.15))
                    .frame(width: 36, height: 36)
                Text(mealTimeIcon(slot.mealTime))
                    .font(.system(size: 18))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(slot.mealTime)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(slot.name)
                    .font(.subheadline)
                    .fontWeight(slot.name == "未設定" ? .regular : .medium)
                    .foregroundColor(slot.name == "未設定" ? .secondary : .primary)
            }

            Spacer()

            if isFixed {
                Image(systemName: "pin.fill")
                    .font(.caption)
                    .foregroundColor(Color(hex: "1D9E75"))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .onTapGesture { if !isFixed { showEdit = true } }
        .sheet(isPresented: $showEdit) {
            EditMealSlotSheet(slot: slot, onSave: { updated in
                onUpdate(updated)
            })
        }
    }

    private func mealTimeColor(_ mealTime: String) -> Color {
        switch mealTime {
        case "朝": return .orange
        case "昼": return .yellow
        case "夜": return .indigo
        default: return .gray
        }
    }

    private func mealTimeIcon(_ mealTime: String) -> String {
        switch mealTime {
        case "朝": return "🌅"
        case "昼": return "☀️"
        case "夜": return "🌙"
        default: return "🍽️"
        }
    }
}

private struct EditMealSlotSheet: View {
    let slot: MealSlot
    let onSave: (MealSlot) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var isCooking: Bool

    init(slot: MealSlot, onSave: @escaping (MealSlot) -> Void) {
        self.slot = slot
        self.onSave = onSave
        _name = State(initialValue: slot.name == "未設定" ? "" : slot.name)
        _isCooking = State(initialValue: slot.isCooking)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("料理名") {
                    TextField("例: 野菜炒め", text: $name)
                }
                Section {
                    Toggle("自炊する", isOn: $isCooking)
                        .tint(Color(hex: "1D9E75"))
                }
            }
            .navigationTitle("\(slot.day)曜 \(slot.mealTime)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        var updated = slot
                        updated.name = name.isEmpty ? "未設定" : name
                        updated.isCooking = isCooking
                        onSave(updated)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .tint(Color(hex: "1D9E75"))
                }
            }
        }
    }
}
