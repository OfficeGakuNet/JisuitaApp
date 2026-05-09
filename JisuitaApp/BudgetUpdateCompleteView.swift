import SwiftUI

struct BudgetUpdateCompleteView: View {
    let addedAmount: Int
    @ObservedObject var viewModel: BudgetViewModel
    @Environment(\.dismiss) private var dismiss

    private var newSpent: Int { viewModel.spentAmount }
    private var budgetRatio: Double { viewModel.budgetRatio }
    private var remaining: Int { viewModel.remaining }
    private var progressColor: Color { viewModel.progressColor }
    private var isOverBudget: Bool { viewModel.spentAmount > viewModel.monthlyBudget }

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
                            .foregroundColor(.secondary)
                    }

                    ProgressView(value: budgetRatio)
                        .tint(progressColor)
                        .padding(.vertical, 4)

                    HStack {
                        Text("残り予算")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(isOverBudget ? "超過" : "¥\(remaining.formatted())")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(isOverBudget ? .red : progressColor)
                    }
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
            .padding(.horizontal)

            if isOverBudget {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text("今月の食費予算を超過しています")
                        .font(.subheadline)
                        .foregroundColor(.red)
                }
                .padding(.horizontal)
            }

            Spacer()

            Button {
                dismiss()
            } label: {
                Text("閉じる")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(hex: "1D9E75"))
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
        .background(Color(.systemGroupedBackground))
        .onAppear {
            viewModel.addSpending(addedAmount)
        }
    }
}
