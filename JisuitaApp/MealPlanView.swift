import SwiftUI

struct MealPlanView: View {

    @State private var mealSlots: [MealSlot] = Self.defaultSlots()
    @State private var isLoading = false
    @State private var errorAlert: ErrorAlert? = nil

    let days = ["月", "火", "水", "木", "金", "土", "日"]
    let mealTimes = ["朝", "昼", "夜"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(days, id: \.self) { day in
                        DayCard(
                            day: day,
                            slots: slotsFor(day: day),
                            onToggle: { slot in toggle(slot) }
                        )
                    }
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("献立")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isLoading {
                        ProgressView().tint(Color(hex: "1D9E75"))
                    } else {
                        Button("AI提案") {
                            Task { await generateMealPlan() }
                        }
                        .tint(Color(hex: "1D9E75"))
                    }
                }
            }
            .alert(item: $errorAlert) { alert in
                Alert(
                    title: Text(alert.title),
                    message: Text(alert.message),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }

    private func slotsFor(day: String) -> [MealSlot] {
        mealTimes.compactMap { time in
            mealSlots.first { $0.day == day && $0.mealTime == time }
        }
    }

    private func toggle(_ slot: MealSlot) {
        guard let idx = mealSlots.firstIndex(where: { $0.id == slot.id }) else { return }
        mealSlots[idx].isCooking.toggle()
    }

    private func generateMealPlan() async {
        isLoading = true
        defer { isLoading = false }

        let cookingSlots = mealSlots.filter { $0.isCooking }
        guard !cookingSlots.isEmpty else {
            errorAlert = ErrorAlert(title: "対象なし", message: "自炊する食事を1つ以上選んでください")
            return
        }

        let slotList = cookingSlots.map { "\($0.day)曜\($0.mealTime)" }.joined(separator: "、")
        let userMessage = """
        以下の食事の献立を提案してください：\(slotList)

        必ずJSON配列のみで返してください（前置き・説明不要）：
        [{"day":"月","mealTime":"朝","name":"料理名"}, ...]
        """

        do {
            let result = try await ClaudeAPIClient.shared.send(
                systemPrompt: "あなたは栄養バランスを考えた献立を提案する専門家です。JSONのみ返してください。",
                userMessage: userMessage
            )
            applyGeneratedPlan(result)
        } catch let apiError as APIError {
            errorAlert = ErrorAlert(title: errorTitle(for: apiError), message: apiError.localizedDescription)
        } catch {
            errorAlert = ErrorAlert(title: "エラー", message: "不明なエラーが発生しました")
        }
    }

    private func applyGeneratedPlan(_ text: String) {
        let clean = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let data = clean.data(using: .utf8),
              let proposals = try? JSONDecoder().decode([MealProposal].self, from: data) else { return }

        for proposal in proposals {
            guard let idx = mealSlots.firstIndex(where: {
                $0.day == proposal.day && $0.mealTime == proposal.mealTime
            }) else { continue }
            mealSlots[idx].name = proposal.name
        }
    }

    private func errorTitle(for error: APIError) -> String {
        switch error {
        case .network: return "通信エラー"
        case .apiError: return "APIエラー"
        case .decodeError: return "データエラー"
        case .unknown: return "エラー"
        }
    }

    static func defaultSlots() -> [MealSlot] {
        let days = ["月", "火", "水", "木", "金", "土", "日"]
        let times = ["朝", "昼", "夜"]
        return days.flatMap { day in
            times.map { time in MealSlot(day: day, mealTime: time) }
        }
    }
}

private struct MealProposal: Codable {
    let day: String
    let mealTime: String
    let name: String
}

private struct DayCard: View {
    let day: String
    let slots: [MealSlot]
    let onToggle: (MealSlot) -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("\(day)曜日")
                    .font(.headline)
                    .foregroundColor(Color(hex: "1D9E75"))
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 8)

            ForEach(slots) { slot in
                Divider().padding(.horizontal, 14)
                MealRow(slot: slot, onToggle: { onToggle(slot) })
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

private struct MealRow: View {
    let slot: MealSlot
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Text(slot.mealTime)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 28, alignment: .leading)

            Text(slot.name)
                .font(.subheadline)
                .foregroundColor(slot.isCooking ? .primary : .secondary)

            Spacer()

            Toggle("", isOn: Binding(get: { slot.isCooking }, set: { _ in onToggle() }))
                .labelsHidden()
                .tint(Color(hex: "1D9E75"))
                .scaleEffect(0.85)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .opacity(slot.isCooking ? 1 : 0.5)
    }
}

private struct ErrorAlert: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

#Preview {
    MealPlanView()
}
