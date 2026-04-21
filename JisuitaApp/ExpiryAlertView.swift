import SwiftUI

struct ExpiringIngredient: Identifiable {
    let id = UUID()
    let name: String
    let expiryDaysLeft: Int
    let amount: String
    var isHandled: Bool = false
}

struct ExpiryAlertView: View {
    @State private var ingredients: [ExpiringIngredient] = [
        ExpiringIngredient(name: "豆腐", expiryDaysLeft: 1, amount: "1/2丁"),
        ExpiringIngredient(name: "ほうれん草", expiryDaysLeft: 2, amount: "1束"),
        ExpiringIngredient(name: "鮭", expiryDaysLeft: 3, amount: "1切れ")
    ]

    var body: some View {
        List {
            Section(header: Text("期限の近い食材")) {
                ForEach($ingredients) { $item in
                    ExpiryRow(item: $item)
                }
            }

            Section {
                Text("「献立を自動変更」を押すと、これらの食材を優先的に使う献立に更新されます。")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("賞味期限アラート")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("すべて自動変更") {
                    for idx in ingredients.indices {
                        ingredients[idx].isHandled = true
                    }
                }
                .tint(Color(hex: "1D9E75"))
            }
        }
    }
}

private struct ExpiryRow: View {
    @Binding var item: ExpiringIngredient

    var urgencyColor: Color {
        switch item.expiryDaysLeft {
        case ...1: return .red
        case 2: return .orange
        default: return .yellow
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(urgencyColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                VStack(spacing: 0) {
                    Text("\(item.expiryDaysLeft)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(urgencyColor)
                    Text("日")
                        .font(.caption2)
                        .foregroundColor(urgencyColor)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .fontWeight(.medium)
                Text(item.amount)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if item.isHandled {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(Color(hex: "1D9E75"))
            } else {
                Button("献立を自動変更") {
                    item.isHandled = true
                }
                .font(.caption)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color(hex: "1D9E75"))
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        ExpiryAlertView()
    }
}
