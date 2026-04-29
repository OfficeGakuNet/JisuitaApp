import SwiftUI

struct MealPlanView: View {

    @State private var mealSlots: [MealSlot] = Self.defaultSlots()
    @State private var isLoading = false
    @State private var errorAlert: ErrorAlert? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    ForEach($mealSlots) { $slot in
                        MealSlotCard(slot: $slot)
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
                        ProgressView()
                            .tint(Color(hex: "1D9E75"))
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

    private func generateMealPlan() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await ClaudeAPIClient.shared.send(
                systemPrompt: "あなたは栄養バランスを考えた献立を提案する専門家です。",
                userMessage: "今週の夕食の献立を7日分、簡潔に提案してください。"
            )
            applyGeneratedPlan(result)
        } catch let apiError as APIError {
            errorAlert = ErrorAlert(
                title: errorTitle(for: apiError),
                message: apiError.localizedDescription
            )
        } catch {
            errorAlert = ErrorAlert(
                title: "エラー",
                message: "不明なエラーが発生しました"
            )
        }
    }

    private func errorTitle(for error: APIError) -> String {
        switch error {
        case .network:
            return "通信エラー"
        case .apiError:
            return "APIエラー"
        case .decodeError:
            return "データエラー"
        case .unknown:
            return "エラー"
        }
    }

    private func applyGeneratedPlan(_ text: String) {
        let lines = text.split(separator: "\n").map(String.init)
        for (index, line) in lines.prefix(mealSlots.count).enumerated() {
            mealSlots[index].meal = line
        }
    }

    static func defaultSlots() -> [MealSlot] {
        let days = ["月", "火", "水", "木", "金", "土", "日"]
        return days.map { MealSlot(day: $0, meal: "未設定", isCooking: true) }
    }
}

private struct MealSlotCard: View {
    @Binding var slot: MealSlot

    var body: some View {
        HStack(spacing: 12) {
            Text(slot.day)
                .font(.headline)
                .frame(width: 32)
                .foregroundColor(Color(hex: "1D9E75"))

            VStack(alignment: .leading, spacing: 4) {
                Text(slot.meal)
                    .font(.subheadline)
                Toggle("自炊", isOn: $slot.isCooking)
                    .font(.caption)
                    .tint(Color(hex: "1D9E75"))
            }

            Spacer()
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

private struct ErrorAlert: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}
