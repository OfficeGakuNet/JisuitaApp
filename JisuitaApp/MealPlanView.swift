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

    @State private var showErrorAlert = false
    @State private var selectedSlot: MealSlot? = nil

    private let days = ["月", "火", "水", "木", "金", "土", "日"]
    private let mealTimes = ["朝", "昼", "夜"]

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        aiSuggestionButton

                        if viewModel.isLoading {
                            loadingView
                        } else {
                            weekGrid
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
            .navigationTitle("今週の献立")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.resetSlots()
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .foregroundColor(Color(hex: "1D9E75"))
                    }
                    .disabled(viewModel.isLoading)
                }
            }
            .alert("エラー", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .onChange(of: viewModel.errorMessage) { msg in
                showErrorAlert = msg != nil
            }
            .sheet(item: $selectedSlot) { slot in
                MealSlotEditView(slot: slot) { updated in
                    viewModel.updateSlot(updated)
                }
            }
        }
    }

    // MARK: - Subviews

    private var aiSuggestionButton: some View {
        Button {
            Task {
                await viewModel.fetchAISuggestion(userSettings: userSettings)
            }
        } label: {
            HStack(spacing: 8) {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.9)
                } else {
                    Image(systemName: "sparkles")
                }
                Text(viewModel.isLoading ? "AI提案を取得中..." : "AIで献立を提案")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(viewModel.isLoading ? Color(hex: "1D9E75").opacity(0.7) : Color(hex: "1D9E75"))
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(viewModel.isLoading)
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ForEach(days, id: \.self) { day in
                DayCardSkeleton(day: day)
            }
        }
    }

    private var weekGrid: some View {
        VStack(spacing: 12) {
            ForEach(days, id: \.self) { day in
                DayCard(
                    day: day,
                    mealTimes: mealTimes,
                    slots: viewModel.slots,
                    onTap: { slot in selectedSlot = slot }
                )
            }
        }
    }
}

// MARK: - DayCard

private struct DayCard: View {
    let day: String
    let mealTimes: [String]
    let slots: [MealSlot]
    let onTap: (MealSlot) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("\(day)曜日")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 10)

            Divider().padding(.horizontal, 16)

            ForEach(mealTimes, id: \.self) { time in
                if let slot = slots.first(where: { $0.day == day && $0.mealTime == time }) {
                    MealRow(slot: slot, onTap: { onTap(slot) })
                    if time != mealTimes.last {
                        Divider().padding(.leading, 60)
                    }
                }
            }

            Spacer(minLength: 10)
        }
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(14)
    }
}

// MARK: - MealRow

private struct MealRow: View {
    let slot: MealSlot
    let onTap: () -> Void

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
        Button(action: onTap) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(mealTimeColor.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: mealTimeIcon)
                        .font(.system(size: 14))
                        .foregroundColor(mealTimeColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(slot.mealTime + "食")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(slot.name)
                        .font(.body)
                        .foregroundColor(slot.name == "未設定" ? .secondary : .primary)
                        .lineLimit(1)
                }

                Spacer()

                if slot.isFixed {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Skeleton

private struct DayCardSkeleton: View {
    let day: String
    @State private var opacity: Double = 0.4

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(.systemFill))
                .frame(width: 60, height: 16)
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 12)

            Divider().padding(.horizontal, 16)

            ForEach(["朝", "昼", "夜"], id: \.self) { _ in
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color(.systemFill))
                        .frame(width: 36, height: 36)
                    VStack(alignment: .leading, spacing: 4) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(.systemFill))
                            .frame(width: 30, height: 10)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(.systemFill))
                            .frame(width: 120, height: 14)
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }

            Spacer(minLength: 10)
        }
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(14)
        .opacity(opacity)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                opacity = 1.0
            }
        }
    }
}

// MARK: - MealSlotEditView

struct MealSlotEditView: View {
    @State private var slot: MealSlot
    let onSave: (MealSlot) -> Void
    @Environment(\.dismiss) private var dismiss

    init(slot: MealSlot, onSave: @escaping (MealSlot) -> Void) {
        _slot = State(initialValue: slot)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("料理名") {
                    TextField("例：鮭の塩焼き定食", text: $slot.name)
                }
                Section("メモ") {
                    TextField("メモを入力", text: $slot.memo, axis: .vertical)
                        .lineLimit(3...6)
                }
                Section {
                    Toggle("自炊する", isOn: $slot.isCooking)
                    Toggle("固定メニュー", isOn: $slot.isFixed)
                }
            }
            .navigationTitle("\(slot.day)曜日の\(slot.mealTime)食")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        onSave(slot)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(Color(hex: "1D9E75"))
                }
            }
        }
    }
}
