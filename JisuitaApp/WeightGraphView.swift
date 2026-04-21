import SwiftUI
import Charts

struct WeightEntry: Identifiable {
    let id = UUID()
    let date: Date
    let weight: Double
}

struct WeightGraphView: View {
    let targetWeight: Double = 60.0

    let entries: [WeightEntry] = {
        let cal = Calendar.current
        let today = Date()
        let weights = [63.2, 63.0, 62.8, 62.9, 62.6, 62.7, 62.4,
                       62.5, 62.3, 62.2, 62.4, 62.1, 62.0, 62.2,
                       61.9, 62.0, 61.8, 61.7, 61.9, 61.6, 61.5,
                       61.7, 61.4, 61.5, 61.3, 61.2, 61.4, 61.1]
        return weights.enumerated().map { idx, w in
            WeightEntry(date: cal.date(byAdding: .day, value: -(weights.count - 1 - idx), to: today)!, weight: w)
        }
    }()

    var currentWeight: Double { entries.last?.weight ?? 0 }
    var diffFromTarget: Double { currentWeight - targetWeight }

    var estimatedDaysToGoal: Int {
        guard entries.count >= 7 else { return 0 }
        let recent = entries.suffix(7)
        let first = recent.first!.weight
        let last = recent.last!.weight
        let dailyLoss = (first - last) / 6
        guard dailyLoss > 0 else { return 999 }
        return Int(ceil(diffFromTarget / dailyLoss))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                summaryCard
                chartCard
                forecastCard
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("体重グラフ")
        .navigationBarTitleDisplayMode(.large)
    }

    private var summaryCard: some View {
        HStack(spacing: 0) {
            statItem(label: "現在", value: String(format: "%.1f kg", currentWeight))
            Divider().frame(height: 40)
            statItem(label: "目標", value: String(format: "%.1f kg", targetWeight))
            Divider().frame(height: 40)
            statItem(label: "残り", value: String(format: "%.1f kg", max(diffFromTarget, 0)))
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    private func statItem(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
    }

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("4週間の推移")
                .font(.subheadline)
                .fontWeight(.semibold)

            Chart {
                ForEach(entries) { entry in
                    LineMark(
                        x: .value("日付", entry.date),
                        y: .value("体重", entry.weight)
                    )
                    .foregroundStyle(Color(hex: "1D9E75"))
                    .interpolationMethod(.catmullRom)

                    AreaMark(
                        x: .value("日付", entry.date),
                        y: .value("体重", entry.weight)
                    )
                    .foregroundStyle(Color(hex: "1D9E75").opacity(0.08))
                    .interpolationMethod(.catmullRom)
                }

                RuleMark(y: .value("目標", targetWeight))
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                    .foregroundStyle(.orange)
                    .annotation(position: .trailing) {
                        Text("目標")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
            }
            .chartYScale(domain: (targetWeight - 1)...(entries.map(\.weight).max() ?? 65) + 0.5)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: .dateTime.month().day())
                }
            }
            .frame(height: 220)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    private var forecastCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "flag.fill")
                .foregroundColor(.orange)
                .font(.title2)

            VStack(alignment: .leading, spacing: 4) {
                Text("達成見通し")
                    .font(.caption)
                    .foregroundColor(.secondary)
                if estimatedDaysToGoal < 999 {
                    Text("このペースなら約 \(estimatedDaysToGoal) 日後に達成できます")
                        .font(.subheadline)
                        .fontWeight(.medium)
                } else {
                    Text("もう少し頑張りましょう！")
                        .font(.subheadline)
                        .fontWeight(.medium)
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
        WeightGraphView()
    }
}
