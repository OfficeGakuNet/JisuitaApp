import SwiftUI

struct UpdateCompleteView: View {
    @Environment(\.dismiss) private var dismiss

    let updatedItems = [
        ("fork.knife", "献立が更新されました"),
        ("cart.fill", "買い出しリストが更新されました"),
        ("leaf.fill", "食材トラッカーが更新されました")
    ]

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
                Text("更新完了！")
                    .font(.title)
                    .fontWeight(.bold)
                Text("以下の内容が一括で更新されました")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            VStack(alignment: .leading, spacing: 14) {
                ForEach(updatedItems, id: \.0) { icon, label in
                    HStack(spacing: 12) {
                        Image(systemName: icon)
                            .foregroundColor(Color(hex: "1D9E75"))
                            .frame(width: 24)
                        Text(label)
                            .font(.subheadline)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .padding(.horizontal, 32)

            Spacer()

            Button(action: { dismiss() }) {
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
        UpdateCompleteView()
    }
}
