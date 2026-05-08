//
//  MealPlanView.swift
//  JisuitaApp
//

import SwiftUI

struct MealPlanView: View {

    @EnvironmentObject private var viewModel: MealPlanViewModel
    @EnvironmentObject private var userSettings: UserSettings
    @State private var selectedSlot: MealSlot?
    @State private var showResetConfirm = false

    private let days = ["月", "火", "水", "木", "金", "土", "日"]
    private let mealTimes = ["朝", "昼", "夜"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if viewModel.isLoading {
                        loadingBanner
                    }

                    if let error = viewModel.errorMessage {
                        errorBanner(error)
                    }

                    weekGrid
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("今週の献立")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            Task { await viewModel.generateAIPlan(userSettings: userSettings) }
                        } label: {
                            Label("AIで提案", systemImage: "sparkles")
                        }
                        Button(role: .destructive) {
                            showResetConfirm = true
                        } label: {
                            Label("リセット", systemImage: "arrow.counterclockwise")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .tint(Color(hex: "1D9E75"))
                    }
                }
            }
            .sheet(item: $selectedSlot) { slot in
                MealSlotEditView(slot: slot) { updated in
                    viewModel.updateSlot(updated)
                }
            }
            .confirmationDialog("献立をリセットしますか？", isPresented: $showResetConfirm, titleVisibility: .visible) {
                Button("リセット", role: .destructive) {
                    viewModel.resetSlots()
                }
                Button("キャンセル", role: .cancel) {}
            }
            .onAppear {
                viewModel.applyFixedMenus()
            }
        }
    }

    // MARK: - Subviews

    private var weekGrid: some View {
        VStack(spacing: 12) {
            ForEach(days, id: \.self) { day in
                DayCard(day: day, mealTimes: mealTimes, slots: viewModel.slots) { slot in
                    selectedSlot = slot
                }
            }
        }
    }

    private var loadingBanner: some View {
        HStack(spacing: 8) {
            ProgressView()
                .tint(Color(hex: "1D9E75"))
            Text("AIが献立を考えています…")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
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
            Text("\(day)曜日")
                .font(.subheadline)
                .fontWeight(.semibold)
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 10)

            Divider()
                .padding(.horizontal, 16)

            VStack(spacing: 0) {
                ForEach(mealTimes, id: \.self) { mealTime in
                    if let slot = slots.first(where: { $0.day == day && $0.mealTime == mealTime }) {
                        MealSlotRow(slot: slot) {
                            onTap(slot)
                        }
                        if mealTime != mealTimes.last {
                            Divider()
                                .padding(.horizontal, 16)
                        }
                    }
                }
            }
            .padding(.bottom, 4)
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - MealSlotRow

private struct MealSlotRow: View {
    let slot: MealSlot
    let onTap: () -> Void

    var mealTimeIcon: String {
        switch slot.mealTime {
        case "朝": return "sunrise.fill"
        case "昼": return "sun.max.fill"
        case "夜": return "moon.stars.fill"
        default: return "fork.knife"
        }
    }

    var mealTimeColor: Color {
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
                Image(systemName: mealTimeIcon)
                    .font(.system(size: 16))
                    .foregroundColor(mealTimeColor)
                    .frame(width: 24)

                Text(slot.mealTime)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 24, alignment: .leading)

                Text(slot.name)
                    .font(.body)
                    .foregroundColor(slot.name == "未設定" ? .secondary : .primary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if slot.isFixed {
                    Image(systemName: "pin.fill")
                        .font(.caption)
                        .foregroundColor(Color(hex: "1D9E75"))
                }

                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundColor(Color(.tertiaryLabel))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - MealSlotEditView

struct MealSlotEditView: View {
    let slot: MealSlot
    let onSave: (MealSlot) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var memo: String
    @State private var isCooking: Bool
    @State private var isFixed: Bool

    init(slot: MealSlot, onSave: @escaping (MealSlot) -> Void) {
        self.slot = slot
        self.onSave = onSave
        _name = State(initialValue: slot.name == "未設定" ? "" : slot.name)
        _memo = State(initialValue: slot.memo)
        _isCooking = State(initialValue: slot.isCooking)
        _isFixed = State(initialValue: slot.isFixed)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("メニュー名", text: $name)
                } header: {
                    Text("\(slot.day)曜日・\(slot.mealTime)食")
                }

                Section {
                    TextField("メモ（任意）", text: $memo, axis: .vertical)
                        .lineLimit(3...)
                } header: {
                    Text("メモ")
                }

                Section {
                    Toggle("自炊する", isOn: $isCooking)
                        .tint(Color(hex: "1D9E75"))
                    Toggle("固定メニューにする", isOn: $isFixed)
                        .tint(Color(hex: "1D9E75"))
                }
            }
            .navigationTitle("献立を編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        var updated = slot
                        updated.name = name.trimmingCharacters(in: .whitespaces).isEmpty ? "未設定" : name.trimmingCharacters(in: .whitespaces)
                        updated.memo = memo
                        updated.isCooking = isCooking
                        updated.isFixed = isFixed
                        onSave(updated)
                        dismiss()
                    }
                    .tint(Color(hex: "1D9E75"))
                }
            }
        }
    }
}
