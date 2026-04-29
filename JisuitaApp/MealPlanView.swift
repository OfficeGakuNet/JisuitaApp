//
//  MealPlanView.swift
//  JisuitaApp
//

import SwiftUI

struct MealPlanView: View {

    @StateObject private var viewModel = MealPlanViewModel()
    @AppStorage("userName") private var userName = ""
    @AppStorage("cookingLevel") private var cookingLevel = "普通"
    @State private var showGenerateConfirm = false
    @State private var showSlotEditor = false
    @State private var selectedSlot: MealSlot? = nil

    private let days = MealPlanViewModel.days
    private let mealTimes = MealPlanViewModel.mealTimes

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        weekGridCard
                        generateButton
                    }
                    .padding(16)
                }

                if viewModel.isLoading {
                    loadingOverlay
                }
            }
            .navigationTitle("今週の献立")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showGenerateConfirm = true }) {
                        Image(systemName: "sparkles")
                            .foregroundColor(Color(hex: "1D9E75"))
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("リセット") {
                        viewModel.resetToDefault()
                    }
                    .foregroundColor(.secondary)
                    .font(.subheadline)
                }
            }
            .alert("AI献立を生成", isPresented: $showGenerateConfirm) {
                Button("生成する") {
                    Task {
                        let profile = "名前: \(userName), 料理レベル: \(cookingLevel)"
                        await viewModel.generateWithClaude(userProfile: profile)
                    }
                }
                Button("キャンセル", role: .cancel) {}
            } message: {
                Text("現在の献立をAIで上書きします。よろしいですか？")
            }
            .alert("エラー", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .sheet(item: $selectedSlot) { slot in
                MealSlotEditSheet(slot: slot) { updated in
                    viewModel.update(updated)
                }
            }
        }
    }

    private var weekGridCard: some View {
        VStack(spacing: 0) {
            gridHeader
            Divider()
            ForEach(mealTimes, id: \.self) { mealTime in
                VStack(spacing: 0) {
                    gridRow(mealTime: mealTime)
                    if mealTime != mealTimes.last {
                        Divider().padding(.leading, 40)
                    }
                }
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(14)
    }

    private var gridHeader: some View {
        HStack(spacing: 0) {
            Text("")
                .frame(width: 36)
            ForEach(days, id: \.self) { day in
                Text(day)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(dayColor(day))
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
    }

    private func gridRow(mealTime: String) -> some View {
        HStack(spacing: 0) {
            Text(mealTime)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .frame(width: 36)

            ForEach(days, id: \.self) { day in
                let slot = viewModel.slot(day: day, mealTime: mealTime)
                MealSlotCell(slot: slot, day: day, mealTime: mealTime) {
                    if let s = slot {
                        selectedSlot = s
                    } else {
                        let newSlot = MealSlot(day: day, mealTime: mealTime)
                        viewModel.update(newSlot)
                        selectedSlot = newSlot
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 4)
    }

    private var generateButton: some View {
        Button(action: { showGenerateConfirm = true }) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                Text("AIで献立を自動生成")
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color(hex: "1D9E75"))
            .cornerRadius(12)
        }
    }

    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3).ignoresSafeArea()
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(Color(hex: "1D9E75"))
                    .scaleEffect(1.4)
                Text("献立を生成中…")
                    .font(.subheadline)
                    .foregroundColor(.white)
            }
            .padding(32)
            .background(.ultraThinMaterial)
            .cornerRadius(16)
        }
    }

    private func dayColor(_ day: String) -> Color {
        switch day {
        case "土": return .blue
        case "日": return .red
        default: return .primary
        }
    }
}

// MARK: - MealSlotCell

private struct MealSlotCell: View {
    let slot: MealSlot?
    let day: String
    let mealTime: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 2) {
                if let slot {
                    if !slot.isCooking {
                        Image(systemName: "takeoutbag.and.cup.and.straw")
                            .font(.system(size: 10))
                            .foregroundColor(.orange)
                    }
                    Text(slot.name)
                        .font(.system(size: 9))
                        .foregroundColor(slot.name == "未設定" ? .secondary : .primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                } else {
                    Text("―")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .padding(2)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(cellBackground)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 1)
    }

    private var cellBackground: Color {
        guard let slot else { return Color(.tertiarySystemGroupedBackground) }
        if slot.name == "未設定" { return Color(.tertiarySystemGroupedBackground) }
        return Color(hex: "1D9E75").opacity(0.12)
    }
}

// MARK: - MealSlotEditSheet

struct MealSlotEditSheet: View {
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
                Section {
                    HStack {
                        Text(slot.day + "曜日")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(slot.mealTime + "食")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("食事")
                }

                Section {
                    TextField("料理名", text: $slot.name)
                } header: {
                    Text("料理名")
                }

                Section {
                    Toggle("自炊する", isOn: $slot.isCooking)
                        .tint(Color(hex: "1D9E75"))
                } header: {
                    Text("調理")
                }
            }
            .navigationTitle("献立を編集")
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
