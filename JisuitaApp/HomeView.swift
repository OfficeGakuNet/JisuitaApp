//
//  HomeView.swift
//  JisuitaApp
//
//  Created by 株式会社オフィス岳 on 2026/04/10.
//

import SwiftUI

struct HomeView: View {

    @EnvironmentObject private var mealPlanViewModel: MealPlanViewModel
    @EnvironmentObject private var userSettings: UserSettings
    @StateObject private var budgetViewModel = BudgetViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    todayMealSection
                    weekSummarySection
                    budgetSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("ホーム")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Today Meal Section

    private var todayMealSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "本日の献立", subtitle: "\(mealPlanViewModel.todayDayString())曜日")

            let todaySlots = mealPlanViewModel.todaySlots()
            VStack(spacing: 8) {
                ForEach(todaySlots) { slot in
                    TodayMealRow(slot: slot)
                }
            }
        }
    }

    // MARK: - Week Summary Section

    private var weekSummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "今週の献立", subtitle: nil)

            let summary = mealPlanViewModel.weekSummary()
            VStack(spacing: 6) {
                ForEach(summary, id: \.day) { entry in
                    WeekSummaryRow(day: entry.day, slots: entry.slots)
                }
            }
        }
    }

    // MARK: - Budget Section

    private var budgetSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "今月の食費", subtitle: nil)

            BudgetCardView(viewModel: budgetViewModel)
        }
    }

    // MARK: - Helpers

    private func sectionHeader(title: String, subtitle: String?) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(title)
                .font(.headline)
                .fontWeight(.bold)
            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
    }
}

// MARK: - TodayMealRow

struct TodayMealRow: View {
    let slot: MealSlot

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(hex: "1D9E75").opacity(0.12))
                    .frame(width: 44, height: 44)
                Text(slot.mealTime)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(hex: "1D9E75"))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(slot.name.isEmpty ? "未設定" : slot.name)
                    .font(.body)
                    .fontWeight(slot.name == "未設定" || slot.name.isEmpty ? .regular : .medium)
                    .foregroundColor(slot.name == "未設定" || slot.name.isEmpty ? .secondary : .primary)

                if !slot.memo.isEmpty {
                    Text(slot.memo)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            if slot.isFixed {
                Label("固定", systemImage: "pin.fill")
                    .font(.caption2)
                    .foregroundColor(Color(hex: "1D9E75"))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color(hex: "1D9E75").opacity(0.1))
                    .clipShape(Capsule())
            }
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

// MARK: - WeekSummaryRow

struct WeekSummaryRow: View {
    let day: String
    let slots: [MealSlot]

    @Environment(\.colorScheme) private var colorScheme

    private var isToday: Bool {
        let weekday = Calendar.current.component(.weekday, from: Date())
        let map = [1: "日", 2: "月", 3: "火", 4: "水", 5: "木", 6: "金", 7: "土"]
        return map[weekday] == day
    }

    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(isToday ? Color(hex: "1D9E75") : Color(.tertiarySystemGroupedBackground))
                    .frame(width: 32, height: 32)
                Text(day)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(isToday ? .white : .secondary)
            }

            HStack(spacing: 4) {
                ForEach(slots) { slot in
                    MealChip(slot: slot)
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - MealChip

struct MealChip: View {
    let slot: MealSlot

    private var isUnset: Bool {
        slot.name == "未設定" || slot.name.isEmpty
    }

    var body: some View {
        Text(isUnset ? "－" : slot.name)
            .font(.caption2)
            .lineLimit(1)
            .truncationMode(.tail)
            .foregroundColor(isUnset ? .secondary : .primary)
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isUnset
                          ? Color(.tertiarySystemGroupedBackground)
                          : Color(hex: "1D9E75").opacity(0.08))
            )
    }
}

// MARK: - BudgetCardView

struct BudgetCardView: View {
    @ObservedObject var viewModel: BudgetViewModel

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("今月の支出")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("¥\(viewModel.spentAmount.formatted())")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("予算")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("¥\(viewModel.monthlyBudget.formatted())")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.tertiarySystemGroupedBackground))
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(viewModel.progressColor)
                        .frame(width: geo.size.width * viewModel.budgetRatio, height: 8)
                }
            }
            .frame(height: 8)

            HStack {
                Text("残り ¥\(viewModel.remaining.formatted())")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(String(format: "%.0f%%", viewModel.budgetRatio * 100))
                    .font(.caption)
                    .foregroundColor(viewModel.progressColor)
                    .fontWeight(.semibold)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}
