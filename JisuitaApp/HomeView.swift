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

    @State private var showErrorAlert = false

    private var todayLabel: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M月d日（E）"
        return formatter.string(from: Date())
    }

    private var todayDayOfWeek: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "E"
        let raw = formatter.string(from: Date())
        let map = ["月": "月", "火": "火", "水": "水", "木": "木", "金": "金", "土": "土", "日": "日"]
        return map[raw] ?? raw
    }

    private var todaySlots: [MealSlot] {
        mealPlanViewModel.slots.filter { $0.day == todayDayOfWeek }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        todaySection
                        aiSuggestionCard
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
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

    // MARK: - Today Section

    private var todaySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(todayLabel)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("今日の献立")
                .font(.title3)
                .fontWeight(.bold)

            if todaySlots.isEmpty {
                emptyTodayView
            } else {
                VStack(spacing: 8) {
                    ForEach(todaySlots) { slot in
                        HomeMealRow(slot: slot)
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }

    private var emptyTodayView: some View {
        HStack {
            Spacer()
            VStack(spacing: 8) {
                Image(systemName: "fork.knife")
                    .font(.title2)
                    .foregroundColor(.secondary)
                Text("献立が設定されていません")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 20)
            Spacer()
        }
    }

    // MARK: - AI Suggestion Card

    private var aiSuggestionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(Color(hex: "1D9E75"))
                Text("AI献立提案")
                    .font(.title3)
                    .fontWeight(.bold)
                Spacer()
            }

            Text("AIがあなたの設定に合わせて今週の献立を自動で提案します。")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Button {
                Task {
                    await mealPlanViewModel.fetchAISuggestion(userSettings: userSettings)
                }
            } label: {
                HStack(spacing: 8) {
                    if mealPlanViewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.85)
                    } else {
                        Image(systemName: "sparkles")
                    }
                    Text(mealPlanViewModel.isLoading ? "提案を取得中..." : "今週の献立をAIで作成")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(
                    mealPlanViewModel.isLoading
                        ? Color(hex: "1D9E75").opacity(0.7)
                        : Color(hex: "1D9E75")
                )
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(mealPlanViewModel.isLoading)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
}

// MARK: - HomeMealRow

private struct HomeMealRow: View {
    let slot: MealSlot

    private var mealTimeIcon: String {
        switch slot.mealTime {
        case "朝": return "sun.horizon.fill"
        case "昼": return "sun.max.fill"
        case "夜": return "moon.fill"
        default: return "fork.knife"
        }
    }

    private var mealTimeColor: Color {
        switch slot.mealTime {
        case "朝": return .orange
        case "昼": return .yellow
        case "夜": return Color(hex: "1D9E75")
        default: return .gray
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(mealTimeColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: mealTimeIcon)
                    .font(.system(size: 15))
                    .foregroundColor(mealTimeColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(slot.mealTime + "食")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(slot.name)
                    .font(.body)
                    .foregroundColor(slot.name == "未設定" ? .secondary : .primary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}
