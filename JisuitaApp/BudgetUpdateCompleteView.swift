import SwiftUI

struct BudgetUpdateCompleteView: View {
    let addedAmount: Int
    @ObservedObject var viewModel: BudgetViewModel
    @Environment(\.dismiss) private var dismiss

    private var newSpent: Int { viewModel.spentAmount }
    private var budgetRatio: Double { viewModel.budgetRatio }
    private var remaining: Int { viewModel.remaining }
    private var progressColor: Color { viewModel.progressColor }

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color(hex: "1D9E75").opacity(0.12))
                    .frame(width: 100, height: 100)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(Color(hex: "1D9E75"))
            }

            VStack(spacing: 8) {
                Text("反映完了！")
                    .font(.title)
                    .fontWeight(.bold)
                Text("食費と食材トラッカーを更新しました")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 16) {
                HStack {
                    Text("今回の食費")
                    Spacer()
                    Text("+ ¥\(addedAmount.formatted())")
                        .fontWeight(.semibold)
                        .foregroundColor(Color(hex: "1D9E75"))
                }

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("今月の食費予算")
                            .font(.subheadline)
                        Spacer()
                        Text("¥\(viewModel.monthlyBudget.formatted())")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("累計支出")
                            .font(.subheadline)
                        Spacer()
                        Text("¥\(newSpent.formatted())")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color(.systemFill))
                                .frame(height: 10)
                            Capsule()
                                .fill(progressColor)
                                .frame(width: geo.size.width * budgetRatio, height: 10)
                        }
                    }
                    .frame(height: 10)

                    HStack {
                        Text("残り")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("¥\(remaining.formatted())")
                            .font(.caption)
                            .foregroundColor(progressColor)
                            .fontWeight(.semibold)
                    }
                }
            }
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
            .padding(.horizontal, 24)

            Spacer()

            Button {
                dismiss()
            } label: {
                Text("完了")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(hex: "1D9E75"))
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
}
