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
    @State private var showErrorAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        greetingSection
                        todayMealSection
                        budgetSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
            .navigationTitle("ホーム")
            .navigationBarTitleDisplayMode(.large)
            .alert("エラー", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) { mealPlanViewModel.errorMessage = nil }
            } message: {
                Text(mealPlanViewModel.errorMessage ?? "")
            }
            .onChange(of: mealPlanViewModel.errorMessage) { msg in
                showErrorAlert = msg != nil
            }
        }
    }

    private var greetingSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(greetingText)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(userSettings.userName.isEmpty ? "こんにちは！" : "\(userSettings.userName)さん")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            Spacer()
        }
        .padding(.top, 4)
    }

    private var todayMealSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("今日の献立")
                    .font(.headline)
                Spacer()
                if mealPlanViewModel.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(Color(hex: "1D9E75"))
                } else {
                    Button {
                        Task {
                            await mealPlanViewModel.fetchAISuggestion(userSettings: userSettings)
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "sparkles")
                                .font(.caption)
                            Text("AI提案")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(Color(hex: "1D9E75"))
                    }
                }
            }

            if mealPlanViewModel.todaySlots.isEmpty {
                emptyMealView
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(mealPlanViewModel.todaySlots.enumerated()), id: \.element.id) { index, slot in
                        HomeMealRow(slot: slot)
                        if index < mealPlanViewModel.todaySlots.count - 1 {
                            Divider()
                                .padding(.horizontal, 16)
                        }
                    }
                }
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(14)
            }
        }
    }

    private var emptyMealView: some View {
        VStack(spacing: 10) {
            Image(systemName: "fork.knife")
                .font(.system(size: 32))
                .foregroundColor(Color(hex: "1D9E75").opacity(0.5))
            Text("献立が設定されていません")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Button {
                Task {
                    await mealPlanViewModel.fetchAISuggestion(userSettings: userSettings)
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                    Text("AIに提案してもらう")
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color(hex: "1D9E75"))
                .cornerRadius(10)
            }
            .disabled(mealPlanViewModel.isLoading)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(14)
    }

    private var budgetSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("今月の食費")
                .font(.headline)

            VStack(spacing: 10) {
                HStack {
                    Text("支出")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("¥\(budgetViewModel.spentAmount.formatted())")
                        .font(.system(size: 17, weight: .semibold))
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(.systemFill))
                            .frame(height: 8)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(budgetViewModel.progressColor)
                            .frame(width: geo.size.width * budgetViewModel.budgetRatio, height: 8)
                    }
                }
                .frame(height: 8)

                HStack {
                    Text("残り ¥\(budgetViewModel.remaining.formatted())")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("予算 ¥\(budgetViewModel.monthlyBudget.formatted())")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(14)
        }
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<10: return "おはようございます"
        case 10..<17: return "こんにちは"
        default: return "こんばんは"
        }
    }
}

private struct HomeMealRow: View {

    let slot: MealSlot

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(slot.mealTime + "食")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(slot.name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(slot.name == "未設定" ? .secondary : .primary)
            }
            Spacer()
            if slot.name != "未設定" {
                Image(systemName: slot.isCooking ? "flame.fill" : "takeoutbag.and.cup.and.straw.fill")
                    .font(.caption)
                    .foregroundColor(Color(hex: "1D9E75").opacity(0.7))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
