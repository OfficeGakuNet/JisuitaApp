import SwiftUI
import Combine

struct PlanShoppingItem: Identifiable {
    var id = UUID()
    var name: String
    var category: String
    var totalAmount: String
    var usages: [UsageInfo]
    var isChecked: Bool = false
}

struct UsageInfo {
    var day: String
    var mealTime: String
    var mealName: String
    var amount: String
}

@MainActor
final class ShoppingListViewModel: ObservableObject {
    @Published var items: [PlanShoppingItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var hasGenerated = false

    func generate(from slots: [MealSlot]) async {
        let targets = slots.filter { $0.isCooking && $0.name != "未設定" }
        guard !targets.isEmpty else {
            errorMessage = "献立に料理名が設定されていません。先に献立でAI提案を実行してください。"
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let mealList = targets.map { "\($0.day) \($0.mealTime)：\($0.name)" }.joined(separator: "\n")

        let systemPrompt = """
        あなたは食材管理の専門家です。以下のJSON形式のみで返答してください（他のテキスト不要）：
        {"items": [{"name": "食材名", "category": "カテゴリ", "totalAmount": "合計量", "usages": [{"day": "月", "mealTime": "夜", "mealName": "料理名", "amount": "使用量"}]}]}
        カテゴリは「米・穀物」「野菜」「豆腐・納豆・卵・麺類」「魚」「肉」「その他」のいずれかを使用してください。
        """

        let userMessage = """
        以下の献立（一人暮らし用）から今週の買い出しリストを作成してください。
        同じ食材は重複を排除して合算し、どの料理で使うかも記載してください。

        献立：
        \(mealList)
        """

        do {
            let response = try await ClaudeAPIClient.shared.send(
                systemPrompt: systemPrompt,
                userMessage: userMessage
            )
            let parsed = parseItems(from: response)
            if parsed.isEmpty {
                errorMessage = "食材リストの解析に失敗しました。再試行してください。"
            } else {
                items = parsed
                hasGenerated = true
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggle(_ item: PlanShoppingItem) {
        guard let idx = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[idx].isChecked.toggle()
    }

    private func parseItems(from text: String) -> [PlanShoppingItem] {
        let stripped = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        // レスポンス内の最初の { から最後の } までを切り出す
        guard let startIdx = stripped.firstIndex(of: "{"),
              let endIdx = stripped.lastIndex(of: "}") else { return [] }
        let jsonString = String(stripped[startIdx...endIdx])
        guard let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let itemsArray = json["items"] as? [[String: Any]] else { return [] }
        return itemsArray.compactMap { dict in
            guard let name = dict["name"] as? String,
                  let category = dict["category"] as? String,
                  let totalAmount = dict["totalAmount"] as? String,
                  let usagesArray = dict["usages"] as? [[String: Any]] else { return nil }
            let usages = usagesArray.compactMap { u -> UsageInfo? in
                guard let day = u["day"] as? String,
                      let mealTime = u["mealTime"] as? String,
                      let mealName = u["mealName"] as? String,
                      let amount = u["amount"] as? String else { return nil }
                return UsageInfo(day: day, mealTime: mealTime, mealName: mealName, amount: amount)
            }
            return PlanShoppingItem(name: name, category: category, totalAmount: totalAmount, usages: usages)
        }
    }
}

struct ShoppingListWithPlanView: View {
    @EnvironmentObject private var mealPlanViewModel: MealPlanViewModel
    @StateObject private var viewModel = ShoppingListViewModel()

    private let categoryOrder = ["米・穀物", "野菜", "豆腐・納豆・卵・麺類", "魚", "肉", "その他"]

    var groupedItems: [(String, [PlanShoppingItem])] {
        let dict = Dictionary(grouping: viewModel.items, by: \.category)
        return categoryOrder.compactMap { cat in
            guard let group = dict[cat], !group.isEmpty else { return nil }
            return (cat, group)
        }
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                loadingView
            } else if viewModel.items.isEmpty {
                emptyView
            } else {
                listView
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Task { await viewModel.generate(from: mealPlanViewModel.slots) }
                } label: {
                    Label(viewModel.hasGenerated ? "再生成" : "AI生成", systemImage: "sparkles")
                        .tint(Color(hex: "1D9E75"))
                }
                .disabled(viewModel.isLoading)
            }
        }
        .alert("エラー", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView().scaleEffect(1.2)
            Text("AIが買い出しリストを作成中...")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
        }
    }

    private var emptyView: some View {
        ContentUnavailableView(
            "買い出しリストが空です",
            systemImage: "cart",
            description: Text("AI生成ボタンで献立から自動作成できます")
        )
    }

    private var listView: some View {
        List {
            ForEach(groupedItems, id: \.0) { category, group in
                Section(header: Text(category).font(.subheadline).fontWeight(.semibold)) {
                    ForEach(group) { item in
                        ShoppingPlanRow(item: item, onToggle: { viewModel.toggle(item) })
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

private struct ShoppingPlanRow: View {
    let item: PlanShoppingItem
    let onToggle: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Button(action: onToggle) {
                    Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(item.isChecked ? Color(hex: "1D9E75") : .secondary)
                        .font(.title3)
                }
                .buttonStyle(.plain)

                Text(item.name)
                    .fontWeight(.medium)
                    .strikethrough(item.isChecked, color: .secondary)
                    .foregroundColor(item.isChecked ? .secondary : .primary)

                Spacer()

                Text(item.totalAmount)
                    .foregroundColor(.secondary)
                    .font(.subheadline)
            }

            ForEach(item.usages, id: \.mealName) { usage in
                HStack(spacing: 4) {
                    Image(systemName: "arrow.right")
                        .font(.caption2)
                        .foregroundColor(Color(hex: "1D9E75"))
                    Text("\(usage.day) \(usage.mealTime) · \(usage.mealName)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(usage.amount)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.leading, 32)
            }
        }
        .padding(.vertical, 4)
    }
}
