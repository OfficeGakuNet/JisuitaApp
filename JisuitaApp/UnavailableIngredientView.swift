import SwiftUI

struct UnavailableIngredient: Identifiable {
    let id = UUID()
    let originalName: String
    let amount: String
    let alternatives: [String]
    var selectedAlternative: String?
    var isConfirmed: Bool = false
}

struct UnavailableIngredientView: View {
    @State private var ingredients: [UnavailableIngredient] = [
        UnavailableIngredient(originalName: "鮭", amount: "2切れ", alternatives: ["タラ", "サバ（缶）", "ツナ缶"]),
        UnavailableIngredient(originalName: "アスパラガス", amount: "1束", alternatives: ["ブロッコリー", "いんげん", "ズッキーニ"])
    ]
    @State private var showCompletion = false

    var allConfirmed: Bool {
        ingredients.allSatisfy { $0.isConfirmed }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("買えなかった食材について、代替案を選んでください。献立が自動で更新されます。")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)

                ForEach($ingredients) { $item in
                    UnavailableIngredientCard(item: $item)
                }

                Button(action: { showCompletion = true }) {
                    Text("献立を更新する")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(allConfirmed ? Color(hex: "1D9E75") : Color.secondary.opacity(0.3))
                        .foregroundColor(.white)
                        .cornerRadius(14)
                }
                .disabled(!allConfirmed)
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("買えなかった食材")
        .navigationBarTitleDisplayMode(.large)
        .navigationDestination(isPresented: $showCompletion) {
            UpdateCompleteView()
        }
    }
}

private struct UnavailableIngredientCard: View {
    @Binding var item: UnavailableIngredient

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.originalName)
                        .font(.headline)
                    Text(item.amount)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                if item.isConfirmed {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color(hex: "1D9E75"))
                }
            }

            Text("代替案")
                .font(.caption)
                .foregroundColor(.secondary)

            ForEach(item.alternatives, id: \.self) { alt in
                Button(action: {
                    item.selectedAlternative = alt
                    item.isConfirmed = true
                }) {
                    HStack {
                        Text(alt)
                            .foregroundColor(.primary)
                        Spacer()
                        if item.selectedAlternative == alt {
                            Image(systemName: "checkmark")
                                .foregroundColor(Color(hex: "1D9E75"))
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(item.selectedAlternative == alt
                        ? Color(hex: "1D9E75").opacity(0.12)
                        : Color(.systemBackground))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

#Preview {
    NavigationStack {
        UnavailableIngredientView()
    }
}
