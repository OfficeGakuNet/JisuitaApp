//
//  MealPlanView.swift
//  JisuitaApp
//
//  Created by 株式会社オフィス岳 on 2026/04/10.
//

import SwiftUI

struct MealPlanView: View {

    @EnvironmentObject private var viewModel: MealPlanViewModel

    private let days = ["月", "火", "水", "木", "金", "土", "日"]
    private let times = ["朝", "昼", "夜"]

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("献立を生成中…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    scrollContent
                }
            }
            .navigationTitle("献立プラン")
            .navigationBarTitleDisplayMode(.large)
            .toolbar { toolbarContent }
            .background(Color(.systemGroupedBackground))
            .alert("エラー", isPresented: errorBinding) {
                Button("OK", role: .cancel) { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    private var scrollContent: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(days, id: \.self) { day in
                    DayCard(day: day, times: times)
                }
            }
            .padding()
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                Task { await viewModel.generateWithAI(
                    systemPrompt: MealPlanPrompts.system,
                    userMessage: MealPlanPrompts.user
                )}
            } label: {
                Label("AI生成", systemImage: "sparkles")
            }
            .tint(Color(hex: "1D9E75"))
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )
    }
}

private struct DayCard: View {

    let day: String
    let times: [String]
    @EnvironmentObject private var viewModel: MealPlanViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("\(day)曜日")
                .font(.headline)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(hex: "1D9E75").opacity(0.12))

            ForEach(times, id: \.self) { time in
                if let slot = viewModel.slot(for: day, mealTime: time) {
                    MealSlotRow(slot: slot)
                    if time != times.last {
                        Divider().padding(.leading, 16)
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
    @State private var isEditing = false

    var body: some View {
        Button {
            isEditing = true
        } label: {
            HStack(spacing: 12) {
                Text(slot.mealTime)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(width: 28, height: 28)
                    .background(mealTimeColor)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(slot.name)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    if !slot.memo.isEmpty {
                        Text(slot.memo)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                if slot.isFixed {
                    Image(systemName: "pin.fill")
                        .font(.caption)
                        .foregroundColor(Color(hex: "1D9E75"))
                }

                if !slot.isCooking {
                    Image(systemName: "takeoutbag.and.cup.and.straw")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .sheet(isPresented: $isEditing) {
            MealSlotEditView(slot: slot)
        }
    }

    private var mealTimeColor: Color {
        switch slot.mealTime {
        case "朝": return .orange
        case "昼": return Color(hex: "1D9E75")
        default: return .indigo
        }
    }
}

private struct MealSlotEditView: View {

    @State private var slot: MealSlot
    @EnvironmentObject private var viewModel: MealPlanViewModel
    @Environment(\.dismiss) private var dismiss

    init(slot: MealSlot) {
        _slot = State(initialValue: slot)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("メニュー名") {
                    TextField("例：鶏の照り焼き", text: $slot.name)
                }
                Section("メモ") {
                    TextField("補足など", text: $slot.memo)
                }
                Section {
                    Toggle("自炊する", isOn: $slot.isCooking)
                        .tint(Color(hex: "1D9E75"))
                    Toggle("固定メニュー", isOn: $slot.isFixed)
                        .tint(Color(hex: "1D9E75"))
                }
            }
            .navigationTitle("\(slot.day)曜 \(slot.mealTime)食")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        viewModel.update(slot)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .tint(Color(hex: "1D9E75"))
                }
            }
        }
    }
}

private enum MealPlanPrompts {
    static let system = """
    あなたはAI管理栄養士です。
    ユーザーの1週間分の献立を朝・昼・夜で提案してください。
    以下のJSON配列フォーマットのみで回答してください。他のテキストは不要です。
    [
      {"id":"UUID文字列","day":"月","mealTime":"朝","name":"メニュー名","isCooking":true,"isFixed":false,"memo":""}
    ]
    dayは月火水木金土日のいずれか。mealTimeは朝昼夜のいずれか。
    """
    static let user = "今週の献立を提案してください。バランスよく、作りやすいものをお願いします。"
}
