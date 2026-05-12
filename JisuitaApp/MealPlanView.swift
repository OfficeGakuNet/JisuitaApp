import SwiftUI

struct MealPlanView: View {
    @EnvironmentObject private var viewModel: MealPlanViewModel
    @State private var isGenerating = false
    @State private var errorMessage: String?

    private let mealTimes = ["朝", "昼", "夜"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(viewModel.weekDays, id: \.self) { day in
                        DayColumnView(day: day, mealTimes: mealTimes, viewModel: viewModel)
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
                    Button {
                        Task { await generateMealPlan() }
                    } label: {
                        if isGenerating {
                            ProgressView()
                        } else {
                            Label("AIで作り直す", systemImage: "sparkles")
                        }
                    }
                    .tint(Color(hex: "1D9E75"))
                    .disabled(isGenerating)
                }
            }
            .alert("エラー", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private func generateMealPlan() async {
        isGenerating = true
        defer { isGenerating = false }
        do {
            try await viewModel.generateMealPlan()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct DayColumnView: View {
    let day: String
    let mealTimes: [String]
    @ObservedObject var viewModel: MealPlanViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(day)
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.leading, 4)

            ForEach(mealTimes, id: \.self) { mealTime in
                if let index = viewModel.slots.firstIndex(where: { $0.day == day && $0.mealTime == mealTime }) {
                    NavigationLink {
                        MealDetailView(slot: $viewModel.slots[index])
                    } label: {
                        MealSlotRow(slot: viewModel.slots[index])
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

private struct MealSlotRow: View {
    let slot: MealSlot

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(slot.mealTime)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(slot.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                if !slot.memo.isEmpty {
                    Text(slot.memo)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer()
            HStack(spacing: 6) {
                if slot.isFixed {
                    Image(systemName: "pin.fill")
                        .font(.caption)
                        .foregroundColor(Color(hex: "1D9E75"))
                }
                Image(systemName: slot.isCooking ? "flame.fill" : "takeoutbag.and.cup.and.straw.fill")
                    .font(.caption)
                    .foregroundColor(slot.isCooking ? Color(hex: "1D9E75") : .orange)
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .contentShape(Rectangle())
    }
}
