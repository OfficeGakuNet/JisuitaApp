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

    private let days = ["月", "火", "水", "木", "金", "土", "日"]
    private let mealTimes = ["朝", "昼", "夜"]

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        aiSuggestionButton

                        if viewModel.isLoading {
                            loadingView
                        }

                        ForEach(days, id: \.self) { day in
                            DayMealCard(day: day, mealTimes: mealTimes)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
            .navigationTitle("今週の献立")
            .navigationBarTitleDisplayMode(.large)
            .alert("エラー", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .onChange(of: viewModel.errorMessage) { msg in
                showErrorAlert = msg != nil
            }
        }
    }

    private var aiSuggestionButton: some View {
        Button {
            Task {
                await viewModel.fetchAISuggestion(userSettings: userSettings)
            }
        } label: {
            HStack(spacing: 10) {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(0.85)
                } else {
                    Image(systemName: "sparkles")
                        .font(.system(size: 16, weight: .semibold))
                }
                Text(viewModel.isLoading ? "AI提案を取得中..." : "AIに献立を提案してもらう")
                    .font(.system(size: 15, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(viewModel.isLoading ? Color(hex: "1D9E75").opacity(0.6) : Color(hex: "1D9E75"))
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(viewModel.isLoading)
    }

    private var loadingView: some View {
        HStack(spacing: 10) {
            ProgressView()
                .tint(Color(hex: "1D9E75"))
            Text("AIが献立を考えています...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(10)
    }
}

private struct DayMealCard: View {

    let day: String
    let mealTimes: [String]

    @EnvironmentObject private var viewModel: MealPlanViewModel

    private var daySlots: [MealSlot] {
        mealTimes.compactMap { time in
            viewModel.slots.first { $0.day == day && $0.mealTime == time }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("\(day)曜日")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color(hex: "1D9E75"))
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 10)

            Divider()
                .padding(.horizontal, 16)

            ForEach(daySlots) { slot in
                MealSlotRow(slot: slot)
                if slot.id != daySlots.last?.id {
                    Divider()
                        .padding(.horizontal, 16)
                }
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(14)
    }
}

private struct MealSlotRow: View {

    let slot: MealSlot
    @EnvironmentObject private var viewModel: MealPlanViewModel
    @State private var showEdit = false

    var body: some View {
        Button {
            showEdit = true
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(slot.mealTime + "食")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(slot.name)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(slot.name == "未設定" ? .secondary : .primary)
                        .lineLimit(2)
                }

                Spacer()

                HStack(spacing: 6) {
                    if slot.isFixed {
                        Label("固定", systemImage: "pin.fill")
                            .font(.caption2)
                            .foregroundColor(Color(hex: "1D9E75"))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color(hex: "1D9E75").opacity(0.1))
                            .cornerRadius(6)
                    }
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(Color(.tertiaryLabel))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showEdit) {
            MealSlotEditView(slot: slot)
                .environmentObject(viewModel)
        }
    }
}

private struct MealSlotEditView: View {

    let slot: MealSlot
    @EnvironmentObject private var viewModel: MealPlanViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var isCooking: Bool
    @State private var isFixed: Bool
    @State private var memo: String

    init(slot: MealSlot) {
        self.slot = slot
        _name = State(initialValue: slot.name == "未設定" ? "" : slot.name)
        _isCooking = State(initialValue: slot.isCooking)
        _isFixed = State(initialValue: slot.isFixed)
        _memo = State(initialValue: slot.memo)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("料理名") {
                    TextField("例：鶏の照り焼き", text: $name)
                }
                Section {
                    Toggle("自炊する", isOn: $isCooking)
                    Toggle("固定メニューにする", isOn: $isFixed)
                }
                Section("メモ") {
                    TextField("任意のメモ", text: $memo, axis: .vertical)
                        .lineLimit(3...5)
                }
            }
            .navigationTitle("\(slot.day)曜日 \(slot.mealTime)食")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        var updated = slot
                        updated.name = name.isEmpty ? "未設定" : name
                        updated.isCooking = isCooking
                        updated.isFixed = isFixed
                        updated.memo = memo
                        viewModel.updateSlot(updated)
                        dismiss()
                    }
                    .tint(Color(hex: "1D9E75"))
                }
            }
        }
    }
}
