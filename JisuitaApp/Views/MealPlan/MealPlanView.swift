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

    private let days = ["月", "火", "水", "木", "金", "土", "日"]
    private let mealTimes = ["朝", "昼", "夜"]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(days, id: \.self) { day in
                        DayMealCard(day: day, mealTimes: mealTimes)
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
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(Color(hex: "1D9E75"))
                    } else {
                        Button {
                            Task {
                                await viewModel.generateMealPlan(userSettings: userSettings)
                            }
                        } label: {
                            Label("AI提案", systemImage: "sparkles")
                        }
                        .tint(Color(hex: "1D9E75"))
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        viewModel.resetSlots()
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                    }
                    .tint(Color(hex: "1D9E75"))
                }
            }
            .alert("エラー", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .onAppear {
                viewModel.applyFixedMenus()
            }
        }
    }
}

private struct DayMealCard: View {
    let day: String
    let mealTimes: [String]
    @EnvironmentObject private var viewModel: MealPlanViewModel

    private var isWeekend: Bool {
        day == "土" || day == "日"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(day + "曜日")
                    .font(.headline)
                    .foregroundColor(isWeekend ? Color(hex: "1D9E75") : .primary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()
                .padding(.horizontal, 16)

            ForEach(mealTimes, id: \.self) { mealTime in
                if let slot = viewModel.slot(for: day, mealTime: mealTime) {
                    MealSlotRow(slot: slot)
                    if mealTime != mealTimes.last {
                        Divider()
                            .padding(.leading, 56)
                    }
                }
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct MealSlotRow: View {
    let slot: MealSlot
    @EnvironmentObject private var viewModel: MealPlanViewModel
    @State private var showingEdit = false

    private var mealTimeIcon: String {
        switch slot.mealTime {
        case "朝": return "sunrise.fill"
        case "昼": return "sun.max.fill"
        case "夜": return "moon.fill"
        default: return "fork.knife"
        }
    }

    private var mealTimeColor: Color {
        switch slot.mealTime {
        case "朝": return .orange
        case "昼": return .yellow
        case "夜": return .indigo
        default: return .gray
        }
    }

    var body: some View {
        Button {
            showingEdit = true
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(mealTimeColor.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: mealTimeIcon)
                        .font(.system(size: 16))
                        .foregroundColor(mealTimeColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(slot.name)
                            .font(.subheadline)
                            .foregroundColor(slot.name == "未設定" ? .secondary : .primary)

                        if slot.isFixed {
                            Image(systemName: "pin.fill")
                                .font(.caption2)
                                .foregroundColor(Color(hex: "1D9E75"))
                        }
                    }

                    if !slot.memo.isEmpty {
                        Text(slot.memo)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingEdit) {
            MealSlotEditSheet(slot: slot)
        }
    }
}

private struct MealSlotEditSheet: View {
    let slot: MealSlot
    @EnvironmentObject private var viewModel: MealPlanViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var editedName: String
    @State private var editedMemo: String
    @State private var editedIsCooking: Bool
    @State private var editedIsFixed: Bool

    init(slot: MealSlot) {
        self.slot = slot
        _editedName = State(initialValue: slot.name == "未設定" ? "" : slot.name)
        _editedMemo = State(initialValue: slot.memo)
        _editedIsCooking = State(initialValue: slot.isCooking)
        _editedIsFixed = State(initialValue: slot.isFixed)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("料理名") {
                    TextField("料理名を入力", text: $editedName)
                }

                Section {
                    Toggle("自炊する", isOn: $editedIsCooking)
                        .tint(Color(hex: "1D9E75"))
                    Toggle("固定メニュー", isOn: $editedIsFixed)
                        .tint(Color(hex: "1D9E75"))
                }

                Section("メモ") {
                    TextField("補足メモ（任意）", text: $editedMemo, axis: .vertical)
                        .lineLimit(3...)
                }
            }
            .navigationTitle("\(slot.day)曜日・\(slot.mealTime)食")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                        .tint(Color(hex: "1D9E75"))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        var updated = slot
                        updated.name = editedName.trimmingCharacters(in: .whitespaces).isEmpty ? "未設定" : editedName
                        updated.memo = editedMemo
                        updated.isCooking = editedIsCooking
                        updated.isFixed = editedIsFixed
                        viewModel.updateSlot(updated)
                        dismiss()
                    }
                    .tint(Color(hex: "1D9E75"))
                    .fontWeight(.semibold)
                }
            }
        }
    }
}
