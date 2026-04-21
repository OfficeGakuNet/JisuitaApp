import SwiftUI

struct MealPlanWithFixedView: View {
    let weekdays = ["月", "火", "水", "木", "金", "土", "日"]
    let mealTimes = ["朝", "昼", "夜"]

    @State private var plan: [String: [String: MealEntry]] = {
        var dict: [String: [String: MealEntry]] = [:]
        let fixed = ["朝": "ヨーグルト・バナナ"]
        let ai: [String: [String: String]] = [
            "月": ["昼": "お弁当（鶏の照り焼き）", "夜": "豆腐と野菜の味噌汁定食"],
            "火": ["昼": "お弁当（鮭おにぎり）", "夜": "豚の生姜焼き"],
            "水": ["昼": "お弁当（卵焼き）", "夜": "鶏むね肉のポン酢蒸し"],
            "木": ["昼": "お弁当（照り焼きチキン）", "夜": "なすとひき肉の炒め物"],
            "金": ["昼": "お弁当（肉巻きおにぎり）", "夜": "鮭のホイル焼き"],
            "土": ["昼": "パスタランチ", "夜": "手巻き寿司"],
            "日": ["昼": "親子丼", "夜": "カレーライス"]
        ]
        for day in ["月", "火", "水", "木", "金", "土", "日"] {
            var dayDict: [String: MealEntry] = [:]
            for time in ["朝", "昼", "夜"] {
                if let name = fixed[time] {
                    dayDict[time] = MealEntry(name: name, isFixed: true)
                } else if let name = ai[day]?[time] {
                    dayDict[time] = MealEntry(name: name, isFixed: false)
                }
            }
            dict[day] = dayDict
        }
        return dict
    }()

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                legendRow

                ForEach(weekdays, id: \.self) { day in
                    DayCard(day: day, mealTimes: mealTimes, entries: plan[day] ?? [:])
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("今週の献立")
        .navigationBarTitleDisplayMode(.large)
    }

    private var legendRow: some View {
        HStack(spacing: 16) {
            HStack(spacing: 6) {
                Image(systemName: "pin.fill")
                    .font(.caption)
                    .foregroundColor(.orange)
                Text("固定メニュー")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.caption)
                    .foregroundColor(Color(hex: "1D9E75"))
                Text("AI提案")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 4)
    }
}

struct MealEntry {
    let name: String
    let isFixed: Bool
}

private struct DayCard: View {
    let day: String
    let mealTimes: [String]
    let entries: [String: MealEntry]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(day)曜日")
                .font(.subheadline)
                .fontWeight(.semibold)

            ForEach(mealTimes, id: \.self) { time in
                if let entry = entries[time] {
                    HStack(spacing: 8) {
                        Text(time)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .frame(width: 24, height: 24)
                            .background(Color(hex: "1D9E75"))
                            .clipShape(Circle())

                        Text(entry.name)
                            .font(.subheadline)
                            .foregroundColor(entry.isFixed ? .secondary : .primary)

                        Spacer()

                        Image(systemName: entry.isFixed ? "pin.fill" : "sparkles")
                            .font(.caption)
                            .foregroundColor(entry.isFixed ? .orange : Color(hex: "1D9E75"))
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

#Preview {
    NavigationStack {
        MealPlanWithFixedView()
    }
}
