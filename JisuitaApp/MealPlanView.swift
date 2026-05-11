import SwiftUI

struct MealPlanView: View {
    @EnvironmentObject private var viewModel: MealPlanViewModel
    @State private var showingRegenerateAlert = false

    private let days = ["月", "火", "水", "木", "金", "土", "日"]
    private let mealTimes = ["朝食", "昼食", "夕食"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(days, id: \.self) { day in
                        DayMealCard(day: day, mealTimes: mealTimes, viewModel: viewModel)
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("今週の献立")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingRegenerateAlert = true
                    } label: {
                        Label("AIで作り直す", systemImage: "sparkles")
                    }
                    .tint(Color(hex: "1D9E75"))
                }
            }
            .alert("献立を作り直しますか？", isPresented: $showingRegenerateAlert) {
                Button("キャンセル", role: .cancel) {}
                Button("作り直す") {
                    Task { await viewModel.generateMealPlan() }
                }
            } message: {
                Text("現在の献立はリセットされます。")
            }
            .overlay {
                if viewModel.isLoading {
                    loadingOverlay
                }
            }
        }
    }

    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3).ignoresSafeArea()
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.4)
                    .tint(.white)
                Text("献立を生成中...")
                    .foregroundColor(.white)
                    .font(.subheadline)
            }
            .padding(32)
            .background(.ultraThinMaterial)
            .cornerRadius(20)
        }
    }
}

private struct DayMealCard: View {
    let day: String
    let mealTimes: [String]
    @ObservedObject var viewModel: MealPlanViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(day + "曜日")
                .font(.headline)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

            Divider()

            ForEach(mealTimes, id: \.self) { mealTime in
                let slot = viewModel.slot(for: day, mealTime: mealTime)
                MealSlotRow(slot: slot)

                if mealTime != mealTimes.last {
                    Divider().padding(.leading, 16)
                }
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
}

private struct MealSlotRow: View {
    let slot: MealSlot

    private var isUnset: Bool { slot.name == "未設定" }

    var body: some View {
        Group {
            if isUnset {
                slotContent
            } else {
                NavigationLink(destination: MealDetailView(meal: slot)) {
                    slotContent
                }
            }
        }
    }

    private var slotContent: some View {
        HStack(spacing: 12) {
            Image(systemName: mealTimeIcon)
                .foregroundColor(isUnset ? .secondary : Color(hex: "1D9E75"))
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(slot.mealTime)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(slot.name)
                    .font(.body)
                    .foregroundColor(isUnset ? .secondary : .primary)
            }

            Spacer()

            if !isUnset {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var mealTimeIcon: String {
        switch slot.mealTime {
        case "朝食": return "sunrise.fill"
        case "昼食": return "sun.max.fill"
        case "夕食": return "moon.fill"
        default: return "fork.knife"
        }
    }
}
