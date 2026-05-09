import SwiftUI

struct MealPlanView: View {
    @EnvironmentObject private var viewModel: MealPlanViewModel
    @State private var isGenerating = false
    @State private var errorMessage: String?
    @State private var selectedMeal: MealSlot?

    private let days = ["月", "火", "水", "木", "金", "土", "日"]
    private let mealTimes = ["朝食", "昼食", "夕食"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                    }

                    weeklyGrid

                    generateButton
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("今週の献立")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(item: $selectedMeal) { meal in
                MealDetailView(meal: meal)
            }
        }
    }

    private var weeklyGrid: some View {
        VStack(spacing: 12) {
            ForEach(days, id: \.self) { day in
                daySection(day: day)
            }
        }
    }

    private func daySection(day: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(day + "曜日")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)

            VStack(spacing: 1) {
                ForEach(mealTimes, id: \.self) { mealTime in
                    mealSlotRow(day: day, mealTime: mealTime)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func mealSlotRow(day: String, mealTime: String) -> some View {
        let slot = viewModel.slot(for: day, mealTime: mealTime)
        let isUnset = slot.name == "未設定"

        return Button {
            if !isUnset {
                selectedMeal = slot
            }
        } label: {
            HStack(spacing: 12) {
                Text(mealTime)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 36, alignment: .leading)

                Text(slot.name)
                    .font(.subheadline)
                    .fontWeight(isUnset ? .regular : .medium)
                    .foregroundColor(isUnset ? .secondary : .primary)

                Spacer()

                if !isUnset {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(Color(.tertiaryLabel))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
        }
        .buttonStyle(.plain)
        .disabled(isUnset)
    }

    private var generateButton: some View {
        Button {
            Task { await generateMealPlan() }
        } label: {
            HStack(spacing: 8) {
                if isGenerating {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(0.9)
                } else {
                    Image(systemName: "sparkles")
                }
                Text(isGenerating ? "生成中..." : "AIで献立を作り直す")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color(hex: "1D9E75"))
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(isGenerating)
    }

    private func generateMealPlan() async {
        isGenerating = true
        errorMessage = nil
        do {
            try await viewModel.generateMealPlan()
        } catch {
            errorMessage = "献立の生成に失敗しました。通信状況を確認してください。"
        }
        isGenerating = false
    }
}
