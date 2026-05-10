import SwiftUI

struct MealPlanView: View {
    @EnvironmentObject private var viewModel: MealPlanViewModel
    @State private var selectedSlot: MealSlot?

    private let mealTimes = ["朝", "昼", "夜"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(viewModel.weekDays, id: \.self) { day in
                        DayCard(
                            day: day,
                            mealTimes: mealTimes,
                            slots: $viewModel.mealSlots,
                            onSlotTap: { slot in
                                selectedSlot = slot
                            }
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("今週の献立")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task { await viewModel.generateMealPlan() }
                    } label: {
                        Label("AIで作り直す", systemImage: "sparkles")
                            .font(.subheadline)
                    }
                    .tint(Color(hex: "1D9E75"))
                    .disabled(viewModel.isLoading)
                }
            }
            .overlay {
                if viewModel.isLoading {
                    LoadingOverlay()
                }
            }
            .sheet(item: $selectedSlot) { slot in
                if let idx = viewModel.mealSlots.firstIndex(where: { $0.id == slot.id }) {
                    MealDetailView(slot: $viewModel.mealSlots[idx])
                }
            }
        }
    }
}

private struct DayCard: View {
    let day: String
    let mealTimes: [String]
    @Binding var slots: [MealSlot]
    let onSlotTap: (MealSlot) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(day)
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

            Divider()
                .padding(.horizontal, 16)

            VStack(spacing: 0) {
                ForEach(mealTimes, id: \.self) { mealTime in
                    if let idx = slots.firstIndex(where: { $0.day == day && $0.mealTime == mealTime }) {
                        SlotRow(
                            slot: slots[idx],
                            onTap: { onSlotTap(slots[idx]) }
                        )
                        if mealTime != mealTimes.last {
                            Divider()
                                .padding(.leading, 16)
                        }
                    }
                }
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct SlotRow: View {
    let slot: MealSlot
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Text(slot.mealTime)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(slot.name)
                        .font(.body)
                        .foregroundColor(.primary)
                        .lineLimit(1)

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
                        Label("固定", systemImage: "pin.fill")
                            .font(.caption2)
                            .foregroundColor(Color(hex: "1D9E75"))
                            .labelStyle(.iconOnly)
                    }
                    if !slot.isCooking {
                        Label("外食", systemImage: "takeoutbag.and.cup.and.straw")
                            .font(.caption2)
                            .foregroundColor(.orange)
                            .labelStyle(.iconOnly)
                    }
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.tertiaryLabel)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct LoadingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.25)
                .ignoresSafeArea()
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(1.4)
                    .tint(Color(hex: "1D9E75"))
                Text("AIが献立を作成中…")
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }
            .padding(32)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
    }
}
