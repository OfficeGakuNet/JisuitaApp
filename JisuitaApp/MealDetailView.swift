import SwiftUI

struct MealDetailView: View {
    let meal: MealSlot

    @State private var recipeText: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String? = nil

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if isLoading {
                    HStack {
                        Spacer()
                        VStack(spacing: 12) {
                            ProgressView()
                                .scaleEffect(1.2)
                            Text("レシピを取得中...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.top, 60)
                } else if let error = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.orange)
                        Text(error)
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
                    .padding(.top, 60)
                } else if !recipeText.isEmpty {
                    Text(recipeText)
                        .font(.body)
                        .lineSpacing(6)
                        .padding(.horizontal)
                        .padding(.top, 8)
                }
            }
            .padding(.bottom, 32)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(meal.name)
        .navigationBarTitleDisplayMode(.large)
        .task {
            await fetchRecipe()
        }
    }

    private func fetchRecipe() async {
        isLoading = true
        errorMessage = nil
        recipeText = ""
        do {
            let system = "あなたはプロの料理家です。ユーザーが指定した料理のレシピと作り方を、材料・手順を含めてわかりやすく日本語で教えてください。"
            let user = "「\(meal.name)」のレシピと作り方を教えてください。"
            let result = try await ClaudeAPIClient.shared.send(systemPrompt: system, userMessage: user)
            recipeText = result
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
