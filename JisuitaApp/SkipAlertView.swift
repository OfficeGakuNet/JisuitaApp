import SwiftUI

struct SkippedIngredient: Identifiable {
    let id = UUID()
    let name: String
    let amount: String
    var action: SkipAction?
}

enum SkipAction: String, CaseIterable {
    case freeze = "冷凍する"
    case nextMeal = "次の食事に使う"
    case remove = "献立から除外"
}

struct SkipAlertView: View {
    let skippedMeal: String
    @State private var ingredients: [SkippedIngredient] = [
        SkippedIngredient(name: "鶏むね肉", amount: "150g"),
        SkippedIngredient(name: "ほうれん草", amount: "1/2束")
    ]
    @Environment(\.dismiss) private var dismiss

    var allHandled: Bool {
        ingredients.allSatisfy { $0.action != nil }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                skippedMealHeader
                    .padding()

                List {
                    Section(header: Text("余る食材")) {
                        ForEach($ingredients) { $item in
                            SkipIngredientRow(item: $item)
                        }
                    }
                }
                .listStyle(.insetGrouped)

                confirmButton
                    .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("スキップ時のアラート")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
    }

    private var skippedMealHeader: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
                .font(.title2)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(skippedMeal) をスキップしました")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text("以下の食材の扱いを決めてください")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }

    private var confirmButton: some View {
        Button(action: dismiss.callAsFunction) {
            Text("確定して献立を更新する")
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding()
                .background(allHandled ? Color(hex: "1D9E75") : Color.secondary.opacity(0.3))
                .foregroundColor(.white)
                .cornerRadius(14)
        }
        .disabled(!allHandled)
    }
}

private struct SkipIngredientRow: View {
    @Binding var item: SkippedIngredient

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(item.name)
                    .fontWeight(.medium)
                Spacer()
                Text(item.amount)
                    .foregroundColor(.secondary)
                    .font(.subheadline)
            }

            HStack(spacing: 8) {
                ForEach(SkipAction.allCases, id: \.self) { action in
                    Button(action: { item.action = action }) {
                        Text(action.rawValue)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(item.action == action
                                ? Color(hex: "1D9E75")
                                : Color(.systemFill))
                            .foregroundColor(item.action == action ? .white : .primary)
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    SkipAlertView(skippedMeal: "水曜夜 · 豆腐と野菜の味噌汁定食")
}
