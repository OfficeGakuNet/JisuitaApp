import SwiftUI

struct RecordTopView: View {
    @StateObject private var budgetVM = BudgetViewModel()
    @AppStorage("foodExpenseRecords") private var recordsData: Data = Data()
    @State private var records: [FoodExpenseRecord] = []
    @State private var showAddSheet = false
    @State private var selectedMonth: Date = Date()

    private let calendar = Calendar.current

    private var filteredRecords: [FoodExpenseRecord] {
        records.filter { record in
            let comps = calendar.dateComponents([.year, .month], from: record.date)
            let selComps = calendar.dateComponents([.year, .month], from: selectedMonth)
            return comps.year == selComps.year && comps.month == selComps.month
        }
        .sorted { $0.date > $1.date }
    }

    private var totalThisMonth: Int {
        filteredRecords.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                monthSelectorSection
                budgetSummaryCard
                weeklyBarChart
                historySection
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("食費記録")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showAddSheet = true }) {
                    Image(systemName: "plus")
                        .foregroundColor(Color(hex: "1D9E75"))
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddExpenseSheet { newRecord in
                records.append(newRecord)
                budgetVM.addSpending(newRecord.amount)
                saveRecords()
            }
        }
        .onAppear { loadRecords() }
    }

    private var monthSelectorSection: some View {
        HStack {
            Button(action: { shiftMonth(by: -1) }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(Color(hex: "1D9E75"))
            }
            Spacer()
            Text(monthDisplayString(selectedMonth))
                .font(.headline)
                .fontWeight(.semibold)
            Spacer()
            Button(action: { shiftMonth(by: 1) }) {
                Image(systemName: "chevron.right")
                    .foregroundColor(
                        isFutureMonth ? Color(.systemGray4) : Color(hex: "1D9E75")
                    )
            }
            .disabled(isFutureMonth)
        }
        .padding(.top, 8)
    }

    private var isFutureMonth: Bool {
        let selComps = calendar.dateComponents([.year, .month], from: selectedMonth)
        let nowComps = calendar.dateComponents([.year, .month], from: Date())
        if let sy = selComps.year, let sm = selComps.month,
           let ny = nowComps.year, let nm = nowComps.month {
            return sy > ny || (sy == ny && sm >= nm)
        }
        return false
    }

    private var budgetSummaryCard: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("今月の食費")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("¥\(totalThisMonth.formatted())")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: "1D9E75"))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("予算")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("¥\(budgetVM.monthlyBudget.formatted())")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(.systemGray5))
                        .frame(height: 10)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(budgetVM.progressColor)
                        .frame(
                            width: geo.size.width * budgetVM.budgetRatio,
                            height: 10
                        )
                        .animation(.easeInOut(duration: 0.4), value: budgetVM.budgetRatio)
                }
            }
            .frame(height: 10)

            HStack {
                Label(
                    "残り ¥\(budgetVM.remaining.formatted())",
                    systemImage: "creditcard"
                )
                .font(.caption)
                .foregroundColor(budgetVM.progressColor)
                Spacer()
                Text("\(Int(budgetVM.budgetRatio * 100))% 使用")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
    }

    private var weeklyBarChart: some View {
        let weeklyData = computeWeeklyData()
        let maxVal = weeklyData.map { $0.amount }.max() ?? 1

        return VStack(alignment: .leading, spacing: 12) {
            Text("週別支出")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)

            HStack(alignment: .bottom, spacing: 8) {
                ForEach(weeklyData) { week in
                    VStack(spacing: 4) {
                        Text("¥\(shortAmount(week.amount))")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(hex: "1D9E75").opacity(0.8))
                            .frame(
                                height: maxVal > 0
                                    ? max(CGFloat(week.amount) / CGFloat(maxVal) * 80, week.amount > 0 ? 4 : 0)
                                    : 0
                            )
                            .animation(.easeInOut(duration: 0.4), value: week.amount)
                        Text(week.label)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 110)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("支出履歴")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)

            if filteredRecords.isEmpty {
                ContentUnavailableView(
                    "記録なし",
                    systemImage: "tray",
                    description: Text("右上の＋ボタンから食費を記録できます")
                )
                .padding(.vertical, 16)
            } else {
                VStack(spacing: 0) {
                    ForEach(filteredRecords) { record in
                        RecordRow(record: record)
                        if record.id != filteredRecords.last?.id {
                            Divider().padding(.leading, 56)
                        }
                    }
                }
                .background(Color(.systemBackground))
                .cornerRadius(14)
                .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
            }
        }
    }

    private func shiftMonth(by value: Int) {
        if let newDate = calendar.date(byAdding: .month, value: value, to: selectedMonth) {
            selectedMonth = newDate
        }
    }

    private func monthDisplayString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }

    private func shortAmount(_ amount: Int) -> String {
        if amount >= 10000 {
            return String(format: "%.1fk", Double(amount) / 1000)
        }
        return "\(amount)"
    }

    private struct WeekData: Identifiable {
        let id = UUID()
        let label: String
        let amount: Int
    }

    private func computeWeeklyData() -> [WeekData] {
        guard let monthStart = calendar.date(
            from: calendar.dateComponents([.year, .month], from: selectedMonth)
        ) else { return [] }

        var weeks: [WeekData] = []
        var weekStart = monthStart
        var weekIndex = 1

        while true {
            guard let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) else { break }
            let endOfMonth = calendar.date(
                byAdding: DateComponents(month: 1, day: -1),
                to: monthStart
            ) ?? weekStart
            let actualEnd = min(weekEnd, calendar.date(byAdding: .day, value: 1, to: endOfMonth) ?? weekEnd)

            let weekTotal = filteredRecords
                .filter { $0.date >= weekStart && $0.date < actualEnd }
                .reduce(0) { $0 + $1.amount }

            weeks.append(WeekData(label: "第\(weekIndex)週", amount: weekTotal))
            weekIndex += 1
            weekStart = weekEnd
            if weekStart > endOfMonth { break }
        }
        return weeks
    }

    private func saveRecords() {
        recordsData = (try? JSONEncoder().encode(records)) ?? Data()
    }

    private func loadRecords() {
        records = (try? JSONDecoder().decode([FoodExpenseRecord].self, from: recordsData)) ?? []
    }
}

struct FoodExpenseRecord: Identifiable, Codable {
    var id = UUID()
    var date: Date
    var amount: Int
    var category: String
    var memo: String
}

private struct RecordRow: View {
    let record: FoodExpenseRecord

    private var categoryIcon: String {
        switch record.category {
        case "スーパー": return "cart.fill"
        case "外食": return "fork.knife"
        case "コンビニ": return "bag.fill"
        case "その他": return "ellipsis.circle.fill"
        default: return "yensign.circle.fill"
        }
    }

    private var categoryColor: Color {
        switch record.category {
        case "スーパー": return Color(hex: "1D9E75")
        case "外食": return .orange
        case "コンビニ": return .blue
        default: return .gray
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(categoryColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: categoryIcon)
                    .foregroundColor(categoryColor)
                    .font(.system(size: 16))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(record.category)
                    .font(.subheadline)
                    .fontWeight(.medium)
                if !record.memo.isEmpty {
                    Text(record.memo)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("¥\(record.amount.formatted())")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(shortDate(record.date))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }

    private func shortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}

private struct AddExpenseSheet: View {
    let onAdd: (FoodExpenseRecord) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var amountText = ""
    @State private var selectedCategory = "スーパー"
    @State private var memo = ""
    @State private var date = Date()
    @State private var showAmountError = false

    private let categories = ["スーパー", "外食", "コンビニ", "その他"]

    var body: some View {
        NavigationStack {
            Form {
                Section("金額") {
                    HStack {
                        Text("¥")
                            .foregroundColor(.secondary)
                        TextField("例: 1500", text: $amountText)
                            .keyboardType(.numberPad)
                    }
                    if showAmountError {
                        Text("金額を正しく入力してください")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }

                Section("カテゴリ") {
                    Picker("カテゴリ", selection: $selectedCategory) {
                        ForEach(categories, id: \.self) { cat in
                            Text(cat).tag(cat)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("日付") {
                    DatePicker(
                        "日付",
                        selection: $date,
                        in: ...Date(),
                        displayedComponents: .date
                    )
                    .environment(\.locale, Locale(identifier: "ja_JP"))
                }

                Section("メモ（任意）") {
                    TextField("例: 週末まとめ買い", text: $memo)
                }
            }
            .navigationTitle("食費を記録")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") { dismiss() }
                        .foregroundColor(Color(hex: "1D9E75"))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("追加") {
                        guard let amount = Int(amountText), amount > 0 else {
                            showAmountError = true
                            return
                        }
                        let record = FoodExpenseRecord(
                            date: date,
                            amount: amount,
                            category: selectedCategory,
                            memo: memo
                        )
                        onAdd(record)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(Color(hex: "1D9E75"))
                }
            }
        }
    }
}
