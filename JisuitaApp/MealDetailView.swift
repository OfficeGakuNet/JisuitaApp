import SwiftUI

// -------------------------------------------------------
// Recipe・Ingredient（レシピデータ）
// -------------------------------------------------------
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

// -------------------------------------------------------
// MealDetailView
// 献立詳細画面（材料確認）
// -------------------------------------------------------
struct MealDetailView: View {

    // ⚠️ 自分のAPIキーに書き換えてください
    let apiKey = Secrets.claudeAPIKey

    let meal: Meal

    @State private var recipe: Recipe? = nil
    @State private var isLoading = false
    @State private var errorMessage: String? = nil

    // 調理モードを開くフラグ
    @State private var showCooking = false

    // 「食べた」ボタンを押したか
    @State private var didEat = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                // -----------------------------------------------
                // ヘッダー
                // -----------------------------------------------
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text(meal.mealTime)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(width: 28, height: 28)
                            .background(mealColor(meal.mealTime))
                            .clipShape(Circle())

                        Text("\(meal.day)曜日の\(meal.mealTime)ごはん")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Text(meal.name)
                        .font(.system(size: 28, weight: .bold))

                    Text(meal.memo)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    if let recipe = recipe {
                        HStack(spacing: 16) {
                            Label("\(recipe.calories) kcal", systemImage: "flame.fill")
                                .foregroundColor(.orange)
                            Label("\(recipe.cookingTime) 分", systemImage: "clock.fill")
                                .foregroundColor(Color(hex: "1D9E75"))
                        }
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .padding(.top, 4)
                    }
                }
                .padding(20)

                Divider()

                // -----------------------------------------------
                // レシピ部分
                // -----------------------------------------------
                if isLoading {
                    VStack(spacing: 16) {
                        ProgressView().scaleEffect(1.3)
                        Text("レシピを考えています…")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 60)

                } else if let error = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 36))
                            .foregroundColor(.orange)
                        Text(error)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                        Button("もう一度試す") {
                            Task { await fetchRecipe() }
                        }
                        .foregroundColor(Color(hex: "1D9E75"))
                    }
                    .padding()
                    .frame(maxWidth: .infinity)

                } else if let recipe = recipe {

                    // -----------------------------------------------
                    // 材料リスト
                    // -----------------------------------------------
                    VStack(alignment: .leading, spacing: 12) {
                        Text("材料（1人前）")
                            .font(.system(size: 18, weight: .bold))
                            .padding(.horizontal, 20)
                            .padding(.top, 20)

                        VStack(spacing: 0) {
                            ForEach(recipe.ingredients) { ingredient in
                                HStack {
                                    Text(ingredient.name)
                                        .font(.system(size: 15))
                                    Spacer()
                                    Text(ingredient.amount)
                                        .font(.system(size: 15))
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)

                                if ingredient.id != recipe.ingredients.last?.id {
                                    Divider().padding(.leading, 20)
                                }
                            }
                        }
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                        .padding(.horizontal, 20)
                    }

                    // -----------------------------------------------
                    // ボタンエリア（調理開始 ＋ 食べた）
                    // -----------------------------------------------
                    VStack(spacing: 12) {

                        // 調理開始ボタン
                        Button(action: {
                            showCooking = true
                        }) {
                            HStack {
                                Image(systemName: "play.fill")
                                Text("調理開始")
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color(hex: "1D9E75"))
                            .cornerRadius(12)
                        }

                        // 「食べた」ボタン（調理せずに記録だけしたい時）
                        Button(action: {
                            didEat = true
                        }) {
                            HStack {
                                Image(systemName: didEat ? "checkmark.circle.fill" : "hand.thumbsup.fill")
                                Text(didEat ? "✓ 記録しました" : "食べた")
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(didEat ? .secondary : Color(hex: "1D9E75"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color(hex: "1D9E75").opacity(didEat ? 0.05 : 0.1))
                            .cornerRadius(12)
                        }
                        .disabled(didEat)
                    }
                    .padding(20)
                    .padding(.bottom, 16)
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(meal.name)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await fetchRecipe()
        }
        // 調理モードをフルスクリーンで開く
        .fullScreenCover(isPresented: $showCooking) {
            if let recipe = recipe {
                CookingView(meal: meal, recipe: recipe)
            }
        }
    }

    // -------------------------------------------------------
    // Claude APIを呼び出してレシピを生成する
    // -------------------------------------------------------
    func fetchRecipe() async {
        isLoading = true
        errorMessage = nil

        let avoidFoods = UserDefaults.standard.string(forKey: "avoidFoods") ?? "なし"

        let prompt = """
        「\(meal.name)」のレシピを1人前で教えてください。
        苦手食材・アレルギー：\(avoidFoods)（使わないでください）

        必ずJSON形式のみで返してください。前置きや説明は不要です。
        {
          "ingredients": [{"name":"食材名","amount":"分量"}],
          "steps": ["手順1","手順2",...],
          "calories": カロリー整数,
          "cookingTime": 調理時間整数（分）
        }
        """

        do {
            let url = URL(string: "https://api.anthropic.com/v1/messages")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
            request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

            let body: [String: Any] = [
                "model": "claude-sonnet-4-6",
                "max_tokens": 1000,
                "messages": [["role": "user", "content": prompt]]
            ]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)

            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(ClaudeResponse.self, from: data)

            if response.isError {
                throw NSError(domain: "APIError", code: 0,
                              userInfo: [NSLocalizedDescriptionKey: response.errorMessage])
            }
            guard let text = response.content?.first?.text else {
                throw NSError(domain: "ParseError", code: 0)
            }

            let cleanText = text
                .replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            struct RecipeJSON: Codable {
                let ingredients: [IngredientJSON]
                let steps: [String]
                let calories: Int
                let cookingTime: Int
            }
            struct IngredientJSON: Codable {
                let name: String
                let amount: String
            }

            let decoded = try JSONDecoder().decode(RecipeJSON.self, from: cleanText.data(using: .utf8)!)
            recipe = Recipe(
                ingredients: decoded.ingredients.map { Ingredient(name: $0.name, amount: $0.amount) },
                steps: decoded.steps,
                calories: decoded.calories,
                cookingTime: decoded.cookingTime
            )
        } catch {
            errorMessage = "レシピの取得に失敗しました。\nネットワークを確認してください。"
        }

        isLoading = false
    }

    func mealColor(_ meal: String) -> Color {
        switch meal {
        case "朝": return .orange
        case "昼": return Color(hex: "1D9E75")
        case "夜": return .indigo
        default: return .gray
        }
    }
}

// -------------------------------------------------------
// CookingView
// 調理モード画面（1ステップずつ表示）
// -------------------------------------------------------
struct CookingView: View {

    let meal: Meal
    let recipe: Recipe

    // 現在のステップ番号（0始まり）
    @State private var currentStep = 0

    // 調理モードを閉じるための仕組み
    @Environment(\.dismiss) var dismiss

    // 完了アラート
    @State private var showFinished = false

    var body: some View {
        VStack(spacing: 0) {

            // -----------------------------------------------
            // 上部バー（閉じるボタン＋進捗）
            // -----------------------------------------------
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: 36, height: 36)
                        .background(Color(.systemGray6))
                        .clipShape(Circle())
                }

                Spacer()

                Text("\(meal.name)")
                    .font(.system(size: 15, weight: .semibold))

                Spacer()

                // プログレスバッジ
                Text("\(currentStep + 1) / \(recipe.steps.count)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(hex: "1D9E75"))
                    .frame(width: 52, height: 36)
                    .background(Color(hex: "1D9E75").opacity(0.1))
                    .cornerRadius(8)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)

            // プログレスバー
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(height: 3)
                    Rectangle()
                        .fill(Color(hex: "1D9E75"))
                        .frame(width: geo.size.width * CGFloat(currentStep + 1) / CGFloat(recipe.steps.count), height: 3)
                        .animation(.easeInOut, value: currentStep)
                }
            }
            .frame(height: 3)

            // -----------------------------------------------
            // メインコンテンツ（ステップ表示）
            // -----------------------------------------------
            TabView(selection: $currentStep) {
                ForEach(Array(recipe.steps.enumerated()), id: \.offset) { index, step in
                    VStack(spacing: 24) {
                        Spacer()

                        // ステップ番号
                        Text("ステップ \(index + 1)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(hex: "1D9E75"))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(Color(hex: "1D9E75").opacity(0.1))
                            .cornerRadius(20)

                        // ステップの内容（大きく表示）
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

            // -----------------------------------------------
            // 下部ナビゲーション（前へ／次へ）
            // -----------------------------------------------
            HStack(spacing: 16) {
                // 前へボタン
                Button(action: {
                    if currentStep > 0 {
                        withAnimation { currentStep -= 1 }
                    }
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("前へ")
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(currentStep == 0 ? .clear : Color(hex: "1D9E75"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(currentStep == 0 ? Color.clear : Color(hex: "1D9E75").opacity(0.1))
                    .cornerRadius(12)
                }
                .disabled(currentStep == 0)

                // 次へ／完了ボタン
                Button(action: {
                    if currentStep < recipe.steps.count - 1 {
                        withAnimation { currentStep += 1 }
                    } else {
                        showFinished = true
                    }
                }) {
                    HStack {
                        Text(currentStep == recipe.steps.count - 1 ? "完了！" : "次へ")
                        Image(systemName: currentStep == recipe.steps.count - 1 ? "checkmark" : "chevron.right")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color(hex: "1D9E75"))
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
            .padding(.top, 8)
        }
        .alert("調理完了！", isPresented: $showFinished) {
            Button("食べた！") { dismiss() }
            Button("戻る", role: .cancel) {}
        } message: {
            Text("\(meal.name)の完成です🎉\n記録しますか？")
        }
    }
}

// -------------------------------------------------------
// プレビュー
// -------------------------------------------------------
#Preview {
    NavigationStack {
        MealDetailView(meal: Meal(
            day: "月",
            mealTime: "朝",
            name: "納豆ご飯",
            memo: "たんぱく質たっぷり"
        ))
    }
}
