import SwiftUI

struct MealDetailView: View {
    let meal: MealSlot

    @State private var recipe: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let client: ClaudeAPIClientProtocol = ClaudeAPIClient.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerSection

                if isLoading {
                    loadingSection
                } else if let error = errorMessage {
                    errorSection(error)
                } else if !recipe.isEmpty {
                    recipeSection
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(meal.name)
        .navigationBarTitleDisplayMode(.large)
        .task {
            await fetchRecipe()
        }
    }

    private var headerSection: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: "1D9E75").opacity(0.12))
                    .frame(width: 52, height: 52)
                Image(systemName: mealTimeIcon)
                    .font(.title2)
                    .foregroundColor(Color(hex: "1D9E75"))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(meal.day + " " + meal.mealTime)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(meal.name)
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }

    private var loadingSection: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(Color(hex: "1D9E75"))
            Text("レシピを取得中...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }

    private func errorSection(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.orange)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button("再試行") {
                Task { await fetchRecipe() }
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(hex: "1D9E75"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    private var recipeSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: "doc.text")
                    .foregroundColor(Color(hex: "1D9E75"))
                Text("レシピ・作り方")
                    .font(.headline)
            }
            .padding(.bottom, 12)

            Text(recipe)
                .font(.body)
                .lineSpacing(6)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }

    private var mealTimeIcon: String {
        switch meal.mealTime {
        case "朝食": return "sunrise.fill"
        case "昼食": return "sun.max.fill"
        case "夕食": return "moon.fill"
        default: return "fork.knife"
        }
    }

    private func fetchRecipe() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let systemPrompt = """
        あなたはプロの料理研究家です。
        ユーザーが指定した料理のレシピと作り方を、わかりやすく日本語で提供してください。
        回答は以下の形式で記述してください：
        
        【材料（1人分）】
        - 材料名：分量
        
        【作り方】
        1. 手順を番号付きで記述
        
        【ポイント】
        コツや注意点を簡潔に記述
        """

        let userMessage = "\(meal.name)のレシピと作り方を教えてください。"

        do {
            recipe = try await client.send(systemPrompt: systemPrompt, userMessage: userMessage)
        } catch {
            errorMessage = "レシピの取得に失敗しました。\nもう一度お試しください。"
        }
    }
}
