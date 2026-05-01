import SwiftUI

struct MealPlanView: View {
    @EnvironmentObject private var viewModel: MealPlanViewModel
    @EnvironmentObject private var settings: UserSettings

    private let days = ["月", "火", "水", "木", "金", "土", "日"]
    private let mealTimes = ["朝", "昼", "夜"]

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    loadingView
                } else {
                    mealPlanGrid
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("週間献立")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task { await generateMealPlan() }
                    } label: {
                        Label("AI提案", systemImage: "sparkles")
                            .tint(Color(hex: "1D9E75"))
                    }
                    .disabled(viewModel.isLoading)
                }
            }
            .alert("エラー", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView()
                .scaleEffect(1.2)
            Text("AIが献立を考えています...")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text(settings.familySummary)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
        }
    }

    private var mealPlanGrid: some View {
        ScrollView {
            VStack(spacing: 0) {
                headerRow
                ForEach(mealTimes, id: \.self) { mealTime in
                    mealTimeRow(mealTime: mealTime)
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
            .padding()

            settingsContextView
        }
    }

    private var headerRow: some View {
        HStack(spacing: 4) {
            Text("")
                .frame(width: 32)
            ForEach(days, id: \.self) { day in
                Text(day)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .foregroundColor(day == "土" ? .blue : day == "日" ? .red : .primary)
            }
        }
        .padding(.vertical, 8)
    }

    private func mealTimeRow(mealTime: String) -> some View {
        HStack(spacing: 4) {
            Text(mealTime)
                .font(.caption)
                .fontWeight(.semibold)
                .frame(width: 32)
                .foregroundColor(Color(hex: "1D9E75"))
            ForEach(days, id: \.self) { day in
                let slot = viewModel.slot(for: day, mealTime: mealTime)
                MealCellView(slot: slot) {
                    viewModel.toggleCooking(for: day, mealTime: mealTime)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var settingsContextView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("献立生成条件")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            Text(settings.buildPersonalizedPromptContext())
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(nil)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .padding(.horizontal)
        .padding(.bottom)
    }

    private func generateMealPlan() async {
        let context = settings.buildPersonalizedPromptContext()
        await viewModel.generateMealPlan(personalizedContext: context)
    }
}

struct MealCellView: View {
    let slot: MealSlot?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 2) {
                Text(slot?.name ?? "未設定")
                    .font(.system(size: 9))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .foregroundColor(slot?.isCooking == false ? .secondary : .primary)
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .padding(4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(slot?.isCooking == false
                          ? Color(.systemFill)
                          : Color(hex: "1D9E75").opacity(0.08))
            )
        }
        .buttonStyle(.plain)
    }
}
