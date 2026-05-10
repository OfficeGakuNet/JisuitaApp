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
    @State private var selectedSlot: MealSlot? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        weekGrid
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }

                if viewModel.isLoading {
                    loadingOverlay
                }
            }
            .navigationTitle("今週の献立")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    regenerateButton
                }
            }
            .alert("エラー", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .sheet(item: $selectedSlot) { slot in
                MealSlotEditView(slot: slot) { updated in
                    viewModel.update(updated)
                }
            }
        }
    }

    private var weekGrid: some View {
        ForEach(viewModel.days, id: \.self) { day in
            VStack(alignment: .leading, spacing: 8) {
                Text(day + "曜日")
                    .font(.headline)
                    .foregroundColor(Color(hex: "1D9E75"))
                    .padding(.leading, 4)

                HStack(spacing: 8) {
                    ForEach(viewModel.mealTimes, id: \.self) { time in
                        if let slot = viewModel.slot(day: day, mealTime: time) {
                            MealSlotCard(slot: slot)
                                .onTapGesture { selectedSlot = slot }
                        }
                    }
                }
            }
        }
    }

    private var regenerateButton: some View {
        Button {
            Task { await viewModel.regenerateWithAI(userSettings: userSettings) }
        } label: {
            Label("AI再生成", systemImage: "sparkles")
                .font(.subheadline)
                .foregroundColor(Color(hex: "1D9E75"))
        }
        .disabled(viewModel.isLoading)
    }

    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.25).ignoresSafeArea()
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "1D9E75")))
                    .scaleEffect(1.4)
                Text("AIが献立を生成中…")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(32)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
    }
}

private struct MealSlotCard: View {
    let slot: MealSlot

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(slot.mealTime)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(Color(hex: "1D9E75"))

            Text(slot.name)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .lineLimit(2)
                .minimumScaleFactor(0.8)

            if slot.isFixed {
                Label("固定", systemImage: "pin.fill")
                    .font(.caption2)
                    .foregroundColor(.orange)
            }

            if !slot.isCooking {
                Label("外食", systemImage: "fork.knife.circle")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

struct MealSlotEditView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var slot: MealSlot
    let onSave: (MealSlot) -> Void

    init(slot: MealSlot, onSave: @escaping (MealSlot) -> Void) {
        _slot = State(initialValue: slot)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("料理名") {
                    TextField("料理名", text: $slot.name)
                }

                Section("設定") {
                    Toggle("自炊する", isOn: $slot.isCooking)
                        .tint(Color(hex: "1D9E75"))
                    Toggle("固定メニュー", isOn: $slot.isFixed)
                        .tint(Color(hex: "1D9E75"))
                }

                Section("メモ") {
                    TextField("メモ（任意）", text: $slot.memo, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("\(slot.day)曜 \(slot.mealTime)")
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
                    .tint(Color(hex: "1D9E75"))
                }
            }
        }
    }
}
