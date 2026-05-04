//
//  MealPlanView.swift
//  JisuitaApp
//

import SwiftUI

struct MealPlanView: View {
    @EnvironmentObject private var viewModel: MealPlanViewModel

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
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("献立")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(role: .destructive) {
                        viewModel.resetAll()
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                    }
                    .tint(Color(hex: "1D9E75"))
                }
            }
        }
    }
}

private struct DayMealCard: View {
    @EnvironmentObject private var viewModel: MealPlanViewModel
    let day: String
    let mealTimes: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(day + "曜日")
                .font(.headline)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(hex: "1D9E75").opacity(0.1))

            ForEach(mealTimes, id: \.self) { mealTime in
                if let slot = viewModel.slot(day: day, mealTime: mealTime) {
                    MealSlotRow(slot: slot)
                    if mealTime != mealTimes.last {
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
    @EnvironmentObject private var viewModel: MealPlanViewModel
    let slot: MealSlot
    @State private var isEditing = false

    var body: some View {
        Button {
            isEditing = true
        } label: {
            HStack(spacing: 12) {
                Text(slot.mealTime)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(width: 28)

                Text(slot.name)
                    .font(.body)
                    .foregroundColor(slot.name == "未設定" ? .secondary : .primary)

                Spacer()

                Image(systemName: slot.isCooking ? "flame.fill" : "takeoutbag.and.cup.and.straw.fill")
                    .font(.caption)
                    .foregroundColor(slot.isCooking ? Color(hex: "1D9E75") : .orange)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $isEditing) {
            MealSlotEditSheet(slot: slot)
        }
    }
}

private struct MealSlotEditSheet: View {
    @EnvironmentObject private var viewModel: MealPlanViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var slot: MealSlot

    init(slot: MealSlot) {
        _slot = State(initialValue: slot)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("料理名", text: $slot.name)
                }

                Section {
                    Toggle("自炊する", isOn: $slot.isCooking)
                        .tint(Color(hex: "1D9E75"))
                }
            }
            .navigationTitle(slot.day + "曜" + slot.mealTime + "食")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        viewModel.updateSlot(slot)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .tint(Color(hex: "1D9E75"))
                }
            }
        }
    }
}
