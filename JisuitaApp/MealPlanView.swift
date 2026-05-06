import SwiftUI

struct MealPlanView: View {
    @EnvironmentObject private var viewModel: MealPlanViewModel
    @State private var showGenerateSheet = false

    private let days = ["月", "火", "水", "木", "金", "土", "日"]
    private let mealTimes = ["朝", "昼", "夜"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    headerRow
                    Divider()
                    ForEach(mealTimes, id: \.self) { time in
                        mealRow(for: time)
                        if time != mealTimes.last {
                            Divider()
                        }
                    }
                }
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("今週の献立")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showGenerateSheet = true }) {
                        Image(systemName: "sparkles")
                    }
                    .tint(Color(hex: "1D9E75"))
                }
            }
            .sheet(isPresented: $showGenerateSheet) {
                GenerateMealPlanSheet()
                    .environmentObject(viewModel)
            }
        }
    }

    private var headerRow: some View {
        HStack(spacing: 0) {
            Text("")
                .frame(width: 44)
            ForEach(days, id: \.self) { day in
                Text(day)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
    }

    private func mealRow(for mealTime: String) -> some View {
        HStack(spacing: 0) {
            Text(mealTime)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(Color(hex: "1D9E75"))
                .frame(width: 44)
            ForEach(days, id: \.self) { day in
                slotCell(day: day, mealTime: mealTime)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
    }

    @ViewBuilder
    private func slotCell(day: String, mealTime: String) -> some View {
        let slot = viewModel.slot(for: day, mealTime: mealTime)
        let isSet = slot?.name != "未設定" && slot?.name.isEmpty == false

        Group {
            if let slot, isSet {
                NavigationLink(destination: MealDetailView(meal: slot)) {
                    slotLabel(name: slot.name, isSet: true)
                }
                .buttonStyle(.plain)
            } else {
                slotLabel(name: slot?.name ?? "未設定", isSet: false)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 2)
    }

    private func slotLabel(name: String, isSet: Bool) -> some View {
        Text(name)
            .font(.system(size: 10))
            .foregroundColor(isSet ? Color(hex: "1D9E75") : Color(.tertiaryLabel))
            .multilineTextAlignment(.center)
            .lineLimit(3)
            .padding(4)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSet ? Color(hex: "1D9E75").opacity(0.08) : Color(.secondarySystemBackground))
            )
    }
}
