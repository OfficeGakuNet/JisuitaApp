//
//  MealPlanView.swift
//  JisuitaApp
//
//  Created by 株式会社オフィス岳 on 2026/04/10.
//

import SwiftUI

struct MealPlanView: View {

    @EnvironmentObject private var viewModel: MealPlanViewModel
    @EnvironmentObject private var userSettings: UserSettings
    @StateObject private var budgetViewModel = BudgetViewModel()
    @State private var showErrorAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        aiSuggestionButton
                        weeklyMealGrid
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 32)
                }

                if viewModel.isLoadingAI {
                    loadingOverlay
                }
            }
            .navigationTitle("今週の献立")
            .navigationBarTitleDisplayMode(.large)
            .alert("AI提案エラー", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) {
                    viewModel.aiError = nil
                }
            } message: {
                Text(viewModel.aiError ?? "")
            }
            .onChange(of: viewModel.aiError) { error in
                showErrorAlert = error != nil
            }
        }
    }

    // MARK: - AI提案ボタン

    private var aiSuggestionButton: some View {
        Button {
            Task {
                await viewModel.requestAISuggestion(
                    refrigeratorItems: userSettings.refrigeratorItems,
                    budgetRemaining: budgetViewModel.remaining,
                    mealHistory: viewModel.slots.map { $0.name }.filter { $0 != "未設定" }
                )
            }
        } label: {
            HStack(spacing: 10) {
                if viewModel.isLoadingAI {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.9)
                } else {
                    Image(systemName: "sparkles")
                        .font(.system(size: 16, weight: .semibold))
                }
                Text(viewModel.isLoadingAI ? "AI提案中..." : "AIに献立を提案してもらう")
                    .font(.system(size: 15, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                viewModel.isLoadingAI
                    ? Color(hex: "1D9E75").opacity(0.7)
                    : Color(hex: "1D9E75")
            )
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(viewModel.isLoadingAI)
        .animation(.easeInOut(duration: 0.2), value: viewModel.isLoadingAI)
    }

    // MARK: - 週間献立グリッド

    private var weeklyMealGrid: some View {
        VStack(spacing: 12) {
            ForEach(viewModel.days, id: \.self) { day in
                DayMealCard(day: day)
            }
        }
    }

    // MARK: - ローディングオーバーレイ

    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.35).ignoresSafeArea()
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "1D9E75")))
                    .scaleEffect(1.4)
                Text("AIが献立を考えています...")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
            }
            .padding(32)
            .background(.ultraThinMaterial)
            .cornerRadius(16)
        }
    }
}

// MARK: - 日別カード

private struct DayMealCard: View {

    let day: String
    @EnvironmentObject private var viewModel: MealPlanViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("\(day)曜日")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(hex: "1D9E75"))
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color(hex: "1D9E75").opacity(0.08))

            ForEach(viewModel.mealTimes, id: \.self) { mealTime in
                if let slot = viewModel.slot(for: day, mealTime: mealTime) {
                    MealSlotRow(slot: slot)
                    if mealTime != viewModel.mealTimes.last {
                        Divider().padding(.leading, 14)
                    }
                }
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

// MARK: - 食事スロット行

private struct MealSlotRow: View {

    let slot: MealSlot
    @EnvironmentObject private var viewModel: MealPlanViewModel
    @State private var isEditing = false
    @State private var editText = ""

    var body: some View {
        HStack(spacing: 12) {
            mealTimeBadge

            if isEditing {
                TextField("料理名を入力", text: $editText)
                    .font(.system(size: 14))
                    .onSubmit { commitEdit() }
                Button { commitEdit() } label: {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color(hex: "1D9E75"))
                }
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    Text(slot.name)
                        .font(.system(size: 14))
                        .foregroundColor(slot.name == "未設定" ? .secondary : .primary)
                    if slot.isFixed {
                        Text("固定")
                            .font(.system(size: 10))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange)
                            .cornerRadius(4)
                    }
                }
                Spacer()
                Button {
                    editText = slot.name == "未設定" ? "" : slot.name
                    isEditing = true
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }

    private var mealTimeBadge: some View {
        Text(slot.mealTime)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(badgeColor)
            .frame(width: 28, height: 28)
            .background(badgeColor.opacity(0.12))
            .cornerRadius(6)
    }

    private var badgeColor: Color {
        switch slot.mealTime {
        case "朝": return .orange
        case "昼": return Color(hex: "1D9E75")
        case "夜": return .indigo
        default: return .gray
        }
    }

    private func commitEdit() {
        var updated = slot
        updated.name = editText.trimmingCharacters(in: .whitespaces).isEmpty ? "未設定" : editText.trimmingCharacters(in: .whitespaces)
        viewModel.updateSlot(updated)
        isEditing = false
    }
}
