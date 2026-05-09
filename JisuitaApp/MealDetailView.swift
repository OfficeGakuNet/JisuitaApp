import SwiftUI

struct MealDetailView: View {
    let meal: MealSlot

    @State private var recipeText: String = ""
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
                    errorSection(message: error)
                } else if !recipeText.isEmpty {
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
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
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
        .padding(.vertical, 40)
    }

    private func errorSection(message: String) -> some View {
        VStack(spacing: 16) {
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
        .padding(.vertical, 40)
    }

    private var recipeSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: "text.book.closed.fill")
                    .foregroundColor(Color(hex: "1D9E75"))
                Text("レシピ・作り方")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .padding(.bottom, 12)

            Text(recipeText)
                .font(.body)
                .lineSpacing(6)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var mealTimeIcon: String {
        switch meal.mealTime {
        case "朝食": return "sunrise.fill"
        case "昼食": return "sun.max.fill"
        case "夕食": return "moon.stars.fill"
        default: return "fork.knife"
        }
    }

    private func fetchRecipe() async {
        isLoading = true
        errorMessage = nil
        recipeText = ""

        let systemPrompt = "あなたはプロの料理家です。ユーザーが指定した料理のレシピと作り方を、わかりやすく丁寧に説明してください。材料（2人分目安）と手順を含めて回答してください。"
        let userMessage = "「\(meal.name)」のレシピと作り方を教えてください。"

        do {
            let result = try await client.send(systemPrompt: systemPrompt, userMessage: userMessage)
            recipeText = result
        } catch {
            errorMessage = "レシピの取得に失敗しました。\n通信状況を確認してください。"
        }

        isLoading = false
    }
}
