import SwiftUI
import Combine

// MARK: - Models

struct Recipe: Codable {
    var ingredients: [Ingredient]
    var steps: [String]
    var calories: Int
    var cookingTime: Int
}

struct Ingredient: Identifiable, Codable {
    var id = UUID()
    var name: String
    var amount: String
}

// MARK: - RecipeViewModel

@MainActor
final class RecipeViewModel: ObservableObject {
    @Published var recipe: Recipe? = nil
    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    func fetch(for mealName: String) async {
        guard recipe == nil, mealName != "未設定", !mealName.isEmpty else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let systemPrompt = """
        料理レシピをJSON形式のみで返してください（前置き・説明不要）：
        {"ingredients":[{"name":"食材名","amount":"分量"}],"steps":["手順"],"calories":整数,"cookingTime":整数}
        """
        let userMessage = "「\(mealName)」の一人分レシピを教えてください。自明な準備（ご飯を炊く等）は省いてください。"

        do {
            let text = try await ClaudeAPIClient.shared.send(
                systemPrompt: systemPrompt,
                userMessage: userMessage
            )
            if let parsed = parseRecipe(from: text) {
                recipe = parsed
            } else {
                errorMessage = "レシピの解析に失敗しました"
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func retry(for mealName: String) async {
        recipe = nil
        errorMessage = nil
        await fetch(for: mealName)
    }

    private func parseRecipe(from text: String) -> Recipe? {
        let stripped = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let startIdx = stripped.firstIndex(of: "{"),
              let endIdx = stripped.lastIndex(of: "}"),
              let data = String(stripped[startIdx...endIdx]).data(using: .utf8),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        let ingredientsRaw = root["ingredients"] as? [[String: Any]] ?? []
        let ingredients = ingredientsRaw.compactMap { d -> Ingredient? in
            guard let name = d["name"] as? String else { return nil }
            return Ingredient(name: name, amount: d["amount"] as? String ?? "")
        }
        let steps = root["steps"] as? [String] ?? []
        let calories = (root["calories"] as? NSNumber)?.intValue ?? 0
        let cookingTime = (root["cookingTime"] as? NSNumber)?.intValue ?? 0
        guard !ingredients.isEmpty || !steps.isEmpty else { return nil }
        return Recipe(ingredients: ingredients, steps: steps,
                      calories: calories, cookingTime: cookingTime)
    }
}

// MARK: - MealDetailView

struct MealDetailView: View {
    let day: String
    let mealTime: String
    @EnvironmentObject private var mealPlanViewModel: MealPlanViewModel
    @StateObject private var recipeViewModel = RecipeViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showCooking = false

    private var slot: MealSlot? {
        mealPlanViewModel.slot(for: day, mealTime: mealTime)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if let slot {
                        headerSection(slot: slot)
                        Divider()
                        contentSection(slot: slot)
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(slot?.name ?? "献立詳細")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
        .task {
            if let slot, slot.isCooking {
                await recipeViewModel.fetch(for: slot.name)
            }
        }
        .fullScreenCover(isPresented: $showCooking) {
            if let slot, let recipe = recipeViewModel.recipe {
                CookingView(
                    meal: Meal(day: slot.day, mealTime: slot.mealTime, name: slot.name),
                    recipe: recipe
                )
            }
        }
    }

    // MARK: Header

    private func headerSection(slot: MealSlot) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(slot.mealTime)
                    .font(.caption).fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(width: 28, height: 28)
                    .background(mealTimeColor(slot.mealTime))
                    .clipShape(Circle())
                Text("\(slot.day)曜日の\(slot.mealTime)ごはん")
                    .font(.subheadline).foregroundColor(.secondary)
            }
            Text(slot.name)
                .font(.system(size: 26, weight: .bold))
            if let recipe = recipeViewModel.recipe {
                HStack(spacing: 16) {
                    if recipe.calories > 0 {
                        Label("\(recipe.calories) kcal", systemImage: "flame.fill")
                            .foregroundColor(.orange)
                    }
                    if recipe.cookingTime > 0 {
                        Label("\(recipe.cookingTime) 分", systemImage: "clock.fill")
                            .foregroundColor(Color(hex: "1D9E75"))
                    }
                }
                .font(.subheadline).fontWeight(.medium)
                .padding(.top, 2)
            }
            if !slot.isFixed {
                Toggle("自炊する", isOn: .init(
                    get: { slot.isCooking },
                    set: { _ in mealPlanViewModel.toggleCooking(for: day, mealTime: mealTime) }
                ))
                .tint(Color(hex: "1D9E75"))
                .padding(.top, 4)
            }
        }
        .padding(20)
    }

    // MARK: Content

    @ViewBuilder
    private func contentSection(slot: MealSlot) -> some View {
        if !slot.isCooking {
            placeholder(icon: "fork.knife.circle", text: "外食・テイクアウト")
        } else if slot.name == "未設定" {
            placeholder(icon: "questionmark.circle",
                        text: "献立タブのAI提案で\n料理名を設定してください")
        } else if recipeViewModel.isLoading {
            loadingView
        } else if let error = recipeViewModel.errorMessage {
            errorView(message: error, mealName: slot.name)
        } else if let recipe = recipeViewModel.recipe {
            recipeView(recipe: recipe)
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView().scaleEffect(1.3)
            Text("レシピを考えています…").foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 60)
    }

    private func placeholder(icon: String, text: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 48)).foregroundColor(.secondary)
            Text(text).font(.subheadline).foregroundColor(.secondary).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 60).padding(.horizontal)
    }

    private func errorView(message: String, mealName: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 36)).foregroundColor(.orange)
            Text(message).multilineTextAlignment(.center).foregroundColor(.secondary)
            Button("もう一度試す") {
                Task { await recipeViewModel.retry(for: mealName) }
            }
            .foregroundColor(Color(hex: "1D9E75"))
        }
        .padding().frame(maxWidth: .infinity)
    }

    // MARK: Recipe

    private func recipeView(recipe: Recipe) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Ingredients
            VStack(alignment: .leading, spacing: 12) {
                Text("材料（1人前）")
                    .font(.system(size: 18, weight: .bold))
                    .padding(.horizontal, 20).padding(.top, 20)
                VStack(spacing: 0) {
                    ForEach(Array(recipe.ingredients.enumerated()), id: \.offset) { i, ing in
                        HStack {
                            Text(ing.name)
                            Spacer()
                            Text(ing.amount).foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 20).padding(.vertical, 10)
                        if i < recipe.ingredients.count - 1 {
                            Divider().padding(.leading, 20)
                        }
                    }
                }
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 4)
                .padding(.horizontal, 20)
            }

            // Steps
            VStack(alignment: .leading, spacing: 12) {
                Text("作り方（\(recipe.steps.count)ステップ）")
                    .font(.system(size: 18, weight: .bold))
                    .padding(.horizontal, 20).padding(.top, 24)
                VStack(spacing: 8) {
                    ForEach(Array(recipe.steps.enumerated()), id: \.offset) { i, step in
                        HStack(alignment: .top, spacing: 12) {
                            Text("\(i + 1)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 22, height: 22)
                                .background(Color(hex: "1D9E75").opacity(0.8))
                                .clipShape(Circle())
                            Text(step)
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.vertical, 16)
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 4)
                .padding(.horizontal, 20)
            }

            // Buttons
            Button {
                showCooking = true
            } label: {
                Label("調理開始", systemImage: "play.fill")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color(hex: "1D9E75"))
                    .cornerRadius(12)
            }
            .padding(20)
            .padding(.bottom, 8)
        }
    }

    private func mealTimeColor(_ t: String) -> Color {
        switch t {
        case "朝": return .orange
        case "昼": return Color(hex: "1D9E75")
        case "夜": return .indigo
        default: return .gray
        }
    }
}

// MARK: - CookingView

struct CookingView: View {
    let meal: Meal
    let recipe: Recipe
    @State private var currentStep = 0
    @State private var showFinished = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: 36, height: 36)
                        .background(Color(.systemGray6))
                        .clipShape(Circle())
                }
                Spacer()
                Text(meal.name).font(.system(size: 15, weight: .semibold))
                Spacer()
                Text("\(currentStep + 1) / \(recipe.steps.count)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(hex: "1D9E75"))
                    .frame(width: 52, height: 36)
                    .background(Color(hex: "1D9E75").opacity(0.1))
                    .cornerRadius(8)
            }
            .padding(.horizontal, 20).padding(.vertical, 14)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle().fill(Color(.systemGray5)).frame(height: 3)
                    Rectangle()
                        .fill(Color(hex: "1D9E75"))
                        .frame(
                            width: geo.size.width * CGFloat(currentStep + 1) / CGFloat(recipe.steps.count),
                            height: 3
                        )
                        .animation(.easeInOut, value: currentStep)
                }
            }
            .frame(height: 3)

            TabView(selection: $currentStep) {
                ForEach(Array(recipe.steps.enumerated()), id: \.offset) { index, step in
                    VStack(spacing: 24) {
                        Spacer()
                        Text("ステップ \(index + 1)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(hex: "1D9E75"))
                            .padding(.horizontal, 16).padding(.vertical, 6)
                            .background(Color(hex: "1D9E75").opacity(0.1))
                            .cornerRadius(20)
                        Text(step)
                            .font(.system(size: 22, weight: .medium))
                            .multilineTextAlignment(.center)
                            .lineSpacing(6)
                            .padding(.horizontal, 32)
                        Spacer()
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            HStack(spacing: 16) {
                Button {
                    if currentStep > 0 { withAnimation { currentStep -= 1 } }
                } label: {
                    Label("前へ", systemImage: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(currentStep == 0 ? .clear : Color(hex: "1D9E75"))
                        .frame(maxWidth: .infinity).padding(.vertical, 16)
                        .background(currentStep == 0 ? .clear : Color(hex: "1D9E75").opacity(0.1))
                        .cornerRadius(12)
                }
                .disabled(currentStep == 0)

                Button {
                    if currentStep < recipe.steps.count - 1 {
                        withAnimation { currentStep += 1 }
                    } else {
                        showFinished = true
                    }
                } label: {
                    HStack {
                        Text(currentStep == recipe.steps.count - 1 ? "完了！" : "次へ")
                        Image(systemName: currentStep == recipe.steps.count - 1 ? "checkmark" : "chevron.right")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 16)
                    .background(Color(hex: "1D9E75"))
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal, 20).padding(.bottom, 32).padding(.top, 8)
        }
        .alert("調理完了！", isPresented: $showFinished) {
            Button("閉じる") { dismiss() }
        } message: {
            Text("\(meal.name)の完成です！")
        }
    }
}
