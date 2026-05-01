//
//  MealPlanView.swift
//  JisuitaApp
//

import SwiftUI

struct MealPlanView: View {

    @EnvironmentObject private var viewModel: MealPlanViewModel
    @State private var isGenerating = false
    @State private var errorMessage: String?
    @State private var selectedSlot: MealSlot?

    private let days = ["月", "火", "水", "木", "金", "土", "日"]
    private let mealTimes = ["朝", "昼", "夜"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if let error = errorMessage {
                        ErrorBanner(message: error) {
                            errorMessage = nil
                        }
                    }

                    ForEach(days, id: \.self) { day in
                        DayCard(
                            day: day,
                            mealTimes: mealTimes,
                            viewModel: viewModel,
                            onTap: { slot in selectedSlot = slot }
                        )
                    }
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("今週の献立")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task { await generateAll() }
                    } label: {
                        if isGenerating {
                            ProgressView()
                                .tint(Color(hex: "1D9E75"))
                        } else {
                            Label("AI提案", systemImage: "sparkles")
                        }
                    }
                    .disabled(isGenerating)
                    .tint(Color(hex: "1D9E75"))
                }
            }
            .sheet(item: $selectedSlot) { slot in
                EditMealSlotSheet(slot: slot) { updated in
                    viewModel.update(updated)
                }
            }
        }
    }

    private func generateAll() async {
        isGenerating = true
        errorMessage = nil
        defer { isGenerating = false }

        let prompt = "以下のJSON形式で今週の献立を提案してください。各要素は {\"day\":\"曜日\",\"mealTime\":\"朝|昼|夜\",\"name\":\"料理名\"} の配列です。曜日は月火水木金土日、食事は朝昼夜のすべてを含めてください。JSONのみ返してください。"
        do {
            let response = try await ClaudeAPIClient.shared.send(
                systemPrompt: "あなたは家庭料理の献立プランナーです。",
                userMessage: prompt
            )
            let suggestions = parseSuggestions(from: response)
            await MainActor.run {
                viewModel.applyAISuggestions(suggestions)
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func parseSuggestions(from text: String) -> [(day: String, mealTime: String, name: String)] {
        struct Item: Decodable {
            let day: String
            let mealTime: String
            let name: String
        }
        let jsonString: String
        if let start = text.range(of: "["), let end = text.range(of: "]", options: .backwards) {
            jsonString = String(text[start.lowerBound...end.upperBound])
        } else {
            return []
        }
        guard
            let data = jsonString.data(using: .utf8),
            let items = try? JSONDecoder().decode([Item].self, from: data)
        else { return [] }
        return items.map { (day: $0.day, mealTime: $0.mealTime, name: $0.name) }
    }
}

private struct DayCard: View {
    let day: String
    let mealTimes: [String]
    let viewModel: MealPlanViewModel
    let onTap: (MealSlot) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(day + "曜日")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(Color(hex: "1D9E75"))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

            Divider()

            ForEach(mealTimes, id: \.self) { time in
                if let slot = viewModel.slot(day: day, mealTime: time) {
                    MealSlotRow(slot: slot)
                        .contentShape(Rectangle())
                        .onTapGesture { onTap(slot) }
                    if time != mealTimes.last {
                        Divider().padding(.leading, 16)
                    }
                }
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

private struct MealSlotRow: View {
    let slot: MealSlot

    var body: some View {
        HStack(spacing: 12) {
            Text(slot.mealTime)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(mealTimeColor)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(slot.name)
                    .font(.subheadline)
                    .foregroundColor(slot.name == "未設定" ? .secondary : .primary)
                if !slot.isCooking {
                    Text("外食 / 買い")
                        .font(.caption2)
                        .foregroundColor(.secondary)
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

    private var mealTimeColor: Color {
        switch slot.mealTime {
        case "朝": return .orange
        case "昼": return Color(hex: "1D9E75")
        case "夜": return .indigo
        default: return .gray
        }
    }
}

private struct ErrorBanner: View {
    let message: String
    let onDismiss: () -> Void

    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            Text(message)
                .font(.caption)
                .foregroundColor(.primary)
            Spacer()
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(10)
    }
}

struct EditMealSlotSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var slot: MealSlot
    private let onSave: (MealSlot) -> Void

    init(slot: MealSlot, onSave: @escaping (MealSlot) -> Void) {
        _slot = State(initialValue: slot)
        self.onSave = onSave
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
            .navigationTitle(slot.day + "曜・" + slot.mealTime)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") { dismiss() }
                        .tint(.secondary)
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
