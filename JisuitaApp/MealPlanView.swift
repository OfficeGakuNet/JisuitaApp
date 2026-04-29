import SwiftUI

struct MealPlanView: View {

    @AppStorage("fixedMenus") private var fixedMenusData: Data = Data()
    @State private var mealSlots: [MealSlot] = []
    @State private var isLoading = false
    @State private var errorMessage: String? = nil

    let days = ["月", "火", "水", "木", "金", "土", "日"]
    let mealTimes = ["朝", "昼", "夜"]

    var fixedMenus: [FixedMenu] {
        (try? JSONDecoder().decode([FixedMenu].self, from: fixedMenusData)) ?? []
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(days, id: \.self) { day in
                        DayCard(
                            day: day,
                            slots: slotsFor(day: day),
                            isFixed: { slot in isFixed(slot) },
                            onToggle: { slot in toggle(slot) }
                        )
                    }
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("今週の献立")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isLoading {
                        ProgressView().tint(Color(hex: "1D9E75"))
                    } else {
                        Button {
                            Task { await generateMealPlan() }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "sparkles")
                                Text("AI提案")
                            }
                        }
                        .tint(Color(hex: "1D9E75"))
                    }
                }
            }
            .alert("エラー", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
            .onAppear { buildSlots() }
        }
    }

    // MARK: - スロット構築

    private func buildSlots() {
        var slots: [MealSlot] = []
        for day in days {
            for time in mealTimes {
                let fixedName = fixedMenus.first {
                    $0.isEnabled && $0.mealTime == time && $0.days.contains(day)
                }?.name
                let existing = mealSlots.first { $0.day == day && $0.mealTime == time }
                slots.append(MealSlot(
                    day: day,
                    mealTime: time,
                    name: fixedName ?? (existing?.name ?? "未設定"),
                    isCooking: existing?.isCooking ?? true
                ))
            }
        }
        mealSlots = slots
    }

    private func slotsFor(day: String) -> [MealSlot] {
        mealTimes.compactMap { time in
            mealSlots.first { $0.day == day && $0.mealTime == time }
        }
    }

    private func isFixed(_ slot: MealSlot) -> Bool {
        fixedMenus.contains {
            $0.isEnabled && $0.mealTime == slot.mealTime && $0.days.contains(slot.day)
        }
    }

    private func toggle(_ slot: MealSlot) {
        guard let idx = mealSlots.firstIndex(where: { $0.id == slot.id }) else { return }
        mealSlots[idx].isCooking.toggle()
    }

    // MARK: - AI提案

    private func generateMealPlan() async {
        let targets = mealSlots.filter { $0.isCooking && !isFixed($0) }
        guard !targets.isEmpty else {
            errorMessage = "AI提案する食事がありません。要のスロットを1つ以上設定してください。"
            return
        }

        isLoading = true
        defer { isLoading = false }

        let slotList = targets.map { "\($0.day)曜\($0.mealTime)" }.joined(separator: "、")
        let userMessage = """
        以下の食事の献立を提案してください：\(slotList)

        栄養バランスを考え、日本の家庭料理を中心に提案してください。
        必ずJSON配列のみで返してください（前置き・説明不要）：
        [{"day":"月","mealTime":"朝","name":"料理名"}, ...]
        """

        do {
            let result = try await ClaudeAPIClient.shared.send(
                systemPrompt: "あなたは栄養バランスを考えた献立を提案する専門家です。JSONのみ返してください。",
                userMessage: userMessage
            )
            applyProposals(result)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func applyProposals(_ text: String) {
        let clean = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        struct Proposal: Codable { let day, mealTime, name: String }
        guard let data = clean.data(using: .utf8),
              let proposals = try? JSONDecoder().decode([Proposal].self, from: data) else { return }

        for p in proposals {
            guard let idx = mealSlots.firstIndex(where: { $0.day == p.day && $0.mealTime == p.mealTime }) else { continue }
            mealSlots[idx].name = p.name
        }
    }
}

// MARK: - DayCard

private struct DayCard: View {
    let day: String
    let slots: [MealSlot]
    let isFixed: (MealSlot) -> Bool
    let onToggle: (MealSlot) -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("\(day)曜日")
                    .font(.headline)
                    .foregroundColor(dayColor)
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 8)

            ForEach(Array(slots.enumerated()), id: \.element.id) { i, slot in
                if i > 0 { Divider().padding(.horizontal, 14) }
                MealRow(slot: slot, fixed: isFixed(slot), onToggle: { onToggle(slot) })
            }
            .padding(.bottom, 8)
        }
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    private var dayColor: Color {
        switch day {
        case "土": return .blue
        case "日": return .red
        default: return Color(hex: "1D9E75")
        }
    }
}

// MARK: - MealRow

private struct MealRow: View {
    let slot: MealSlot
    let fixed: Bool
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Text(slot.mealTime)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 28, alignment: .leading)

            if fixed {
                Image(systemName: "pin.fill")
                    .font(.caption2)
                    .foregroundColor(Color(hex: "1D9E75"))
            }

            Text(slot.name)
                .font(.subheadline)
                .foregroundColor(fixed ? Color(hex: "1D9E75") : (slot.isCooking ? .primary : .secondary))

            Spacer()

            if !fixed {
                Toggle("", isOn: Binding(get: { slot.isCooking }, set: { _ in onToggle() }))
                    .labelsHidden()
                    .tint(Color(hex: "1D9E75"))
                    .scaleEffect(0.85)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .opacity(fixed ? 1 : (slot.isCooking ? 1 : 0.45))
    }
}

#Preview {
    MealPlanView()
}
