import SwiftUI

struct RecordTopView: View {
    @StateObject private var viewModel = BudgetViewModel()
    @State private var amountText = ""
    @State private var showComplete = false
    @State private var pendingAmount = 0
    @State private var records: [FoodRecord] = FoodRecord.loadAll()

    private var inputAmount: Int? {
        Int(amountText.filter { $0.isNumber })
    }

    var body: some View {
        List {
            budgetSection
            inputSection
            if !records.isEmpty {
                historySection
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("食費記録")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showComplete, onDismiss: {
            records = FoodRecord.loadAll()
        }) {
            BudgetUpdateCompleteView(addedAmount: pendingAmount, viewModel: viewModel)
        }
    }

    private var budgetSection: some View {
        Section {
            VStack(spacing: 12) {
                HStack {
                    Text("今月の予算")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("¥\(viewModel.monthlyBudget.formatted())")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("累計支出")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("¥\(viewModel.spentAmount.formatted())")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(.systemGray5))
                            .frame(height: 8)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(viewModel.progressColor)
                            .frame(width: geo.size.width * viewModel.budgetRatio, height: 8)
                    }
                }
                .frame(height: 8)

                HStack {
                    Text("残り")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("¥\(viewModel.remaining.formatted())")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(viewModel.progressColor)
                }
            }
            .padding(.vertical, 4)
        } header: {
            Text("今月の食費")
        }
    }

    private var inputSection: some View {
        Section {
            HStack {
                Text("¥")
                    .foregroundColor(.secondary)
                TextField("金額を入力", text: $amountText)
                    .keyboardType(.numberPad)
            }

            Button(action: record) {
                HStack {
                    Spacer()
                    Text("記録する")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.vertical, 4)
            }
            .listRowBackground(inputAmount != nil ? Color(hex: "1D9E75") : Color(.systemGray4))
            .disabled(inputAmount == nil)
        } header: {
            Text("食費を入力")
        }
    }

    private var historySection: some View {
        Section {
            ForEach(records) { record in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(record.dateLabel)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        if !record.memo.isEmpty {
                            Text(record.memo)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                    Text("¥\(record.amount.formatted())")
                        .fontWeight(.semibold)
                }
            }
        } header: {
            Text("過去の記録")
        }
    }

    private func record() {
        guard let amount = inputAmount else { return }
        pendingAmount = amount
        viewModel.addSpending(amount)
        FoodRecord.append(FoodRecord(amount: amount, date: Date()))
        amountText = ""
        showComplete = true
    }
}

struct FoodRecord: Identifiable, Codable {
    let id: UUID
    let amount: Int
    let date: Date
    var memo: String

    init(id: UUID = UUID(), amount: Int, date: Date, memo: String = "") {
        self.id = id
        self.amount = amount
        self.date = date
        self.memo = memo
    }

    var dateLabel: String {
        let f = DateFormatter()
        f.dateFormat = "M/d HH:mm"
        return f.string(from: date)
    }

    private static let key = "foodRecords"

    static func loadAll() -> [FoodRecord] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let records = try? JSONDecoder().decode([FoodRecord].self, from: data)
        else { return [] }
        return records.sorted { $0.date > $1.date }
    }

    static func append(_ record: FoodRecord) {
        var all = loadAll()
        all.insert(record, at: 0)
        if let data = try? JSONEncoder().encode(all) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
