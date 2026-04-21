import SwiftUI

struct BudgetUpdateCompleteView: View {
    let addedAmount: Int
    @AppStorage("monthlyBudget") private var monthlyBudget = 30000
    @AppStorage("spentAmount") private var spentAmount = 8450
    @Environment(\.dismiss) private var dismiss

    var newSpent: Int { spentAmount + addedAmount }
    var budgetRatio: Double { min(Double(newSpent) / Double(monthlyBudget), 1.0) }
    var remaining: Int { max(monthlyBudget - newSpent, 0) }

    var progressColor: Color {
        budgetRatio > 0.9 ? .red : budgetRatio > 0.7 ? .orange : Color(hex: "1D9E75")
    }

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
                        Text("¥\(newSpent.formatted()) / ¥\(monthlyBudget.formatted())")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }

                    ProgressView(value: budgetRatio)
                        .tint(progressColor)

                    HStack {
                        Spacer()
                        Text("残り ¥\(remaining.formatted())")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .padding(.horizontal, 32)

            Spacer()

            Button(action: {
                spentAmount = newSpent
                dismiss()
            }) {
                Text("ホームへ")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(hex: "1D9E75"))
                    .foregroundColor(.white)
                    .cornerRadius(14)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    NavigationStack {
        BudgetUpdateCompleteView(addedAmount: 1230)
    }
}
