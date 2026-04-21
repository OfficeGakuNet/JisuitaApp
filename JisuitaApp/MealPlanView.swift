import SwiftUI

// -------------------------------------------------------
// Meal
// 1食分の献立データ
// -------------------------------------------------------
struct Meal: Identifiable, Codable {
    var id = UUID()
    var day: String      // 曜日
    var mealTime: String // 朝・昼・夜
    var name: String     // 料理名
    var memo: String     // 一言メモ（例：「野菜たっぷり」）
}

// -------------------------------------------------------
// MealPlanView
// AI献立生成画面
// -------------------------------------------------------
struct MealPlanView: View {

    let apiKey = Secrets.claudeAPIKey

    let weekdays = ["月", "火", "水", "木", "金", "土", "日"]
    let meals = ["朝", "昼", "夜"]

    // 生成された献立リスト
    @State private var mealPlan: [Meal] = []

    // 読み込み中フラグ
    @State private var isLoading = false

    // エラーメッセージ
    @State private var errorMessage: String? = nil

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    // -----------------------------------------------
                    // 読み込み中の表示
                    // -----------------------------------------------
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("AIが献立を考えています…")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                } else if let error = errorMessage {
                    // -----------------------------------------------
                    // エラーの表示
                    // -----------------------------------------------
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 40))
                            .foregroundColor(.orange)
                        Text(error)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                        Button("もう一度試す") {
                            Task { await generateMealPlan() }
                        }
                        .foregroundColor(Color(hex: "1D9E75"))
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                } else if mealPlan.isEmpty {
                    // -----------------------------------------------
                    // 未生成の状態
                    // -----------------------------------------------
                    VStack(spacing: 20) {
                        Image(systemName: "fork.knife.circle")
                            .font(.system(size: 60))
                            .foregroundColor(Color(hex: "1D9E75"))
                        Text("今週の献立をAIに作ってもらいましょう")
                            .foregroundColor(.secondary)
                        Button(action: {
                            Task { await generateMealPlan() }
                        }) {
                            HStack {
                                Image(systemName: "sparkles")
                                Text("献立を生成する")
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 14)
                            .background(Color(hex: "1D9E75"))
                            .cornerRadius(12)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                } else {
                    // -----------------------------------------------
                    // 献立一覧の表示
                    // -----------------------------------------------
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(weekdays, id: \.self) { day in
                                let dayMeals = mealPlan.filter { $0.day == day }
                                if !dayMeals.isEmpty {
                                    DayMealCard(day: day, meals: dayMeals)
                                }
                            }
                        }
                        .padding(16)
                        .padding(.bottom, 32)
                    }
                }
            }
            .navigationTitle("今週の献立")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if !mealPlan.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            Task { await generateMealPlan() }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "sparkles")
                                Text("作り直す")
                            }
                            .foregroundColor(Color(hex: "1D9E75"))
                        }
                    }
                }
            }
        }
    }

    // -------------------------------------------------------
    // Claude APIを呼び出して献立を生成する
    // async/await = 時間のかかる処理を待つ仕組み
    // -------------------------------------------------------
    func generateMealPlan() async {
        isLoading = true
        errorMessage = nil

        // UserDefaultsからプロフィールとスケジュールを読み込む
        let defaults = UserDefaults.standard
        let height = defaults.string(forKey: "height") ?? "未設定"
        let weight = defaults.string(forKey: "weight") ?? "未設定"
        let targetWeight = defaults.string(forKey: "targetWeight") ?? "未設定"
        let age = defaults.string(forKey: "age") ?? "未設定"
        let activityLevel = defaults.string(forKey: "activityLevel") ?? "未設定"
        let avoidFoods = defaults.string(forKey: "avoidFoods") ?? "なし"
        let makesBento = defaults.bool(forKey: "makesBento")

        // 必食アイテムを読み込む
        var mustEatText = "なし"
        if let data = defaults.data(forKey: "mustEatItems"),
           let items = try? JSONDecoder().decode([MustEatItem].self, from: data) {
            let itemTexts = items.filter { !$0.food.isEmpty }.map { "\($0.food)（\($0.frequency)）" }
            if !itemTexts.isEmpty {
                mustEatText = itemTexts.joined(separator: "、")
            }
        }

        // スケジュールを読み込む
        var scheduleText = ""
        if let data = defaults.data(forKey: "weeklySchedule"),
           let slots = try? JSONDecoder().decode([MealSlot].self, from: data) {
            let cookingSlots = slots.filter { $0.isCooking }
            scheduleText = cookingSlots.map { "\($0.day)曜\($0.meal)" }.joined(separator: "、")
        }
        if scheduleText.isEmpty { scheduleText = "全食自炊" }
        // ⚠️ 確認用：2日分に絞る（確認が終わったら削除する）
        scheduleText = "月曜朝、月曜昼、月曜夜、火曜朝、火曜昼、火曜夜"

        // AIへのプロンプトを作る
        let prompt = """
        以下のプロフィールと自炊スケジュールに基づいて、今週の献立と各料理の材料を提案してください。

        【プロフィール】
        - 年齢：\(age)歳
        - 身長：\(height)cm
        - 体重：\(weight)kg
        - 目標体重：\(targetWeight)kg
        - 活動量：\(activityLevel)
        - 苦手食材・アレルギー：\(avoidFoods)
        - 必ず食べたいもの：\(mustEatText)
        - お弁当：\(makesBento ? "平日昼は弁当" : "なし")

        【自炊する食事】
        \(scheduleText)

        【出力形式】
        必ずJSON形式のみで返してください。前置きや説明は不要です。
        以下の形式で返してください：

        [
          {
            "day":"月",
            "mealTime":"朝",
            "name":"料理名",
            "memo":"一言メモ",
            "ingredients":[
              {"name":"食材名","amount":"量","category":"野菜"},
            ]
          }
        ]

        自炊しない食事は含めないでください。
        materialsは必ず各料理に含めてください。
        categoryは必ず以下の5つのどれかを使ってください：
        「野菜」「豆腐・納豆・卵・麺類」「魚」「肉」「その他」
        卵は「豆腐・納豆・卵・麺類」に入れてください。
        調味料・だし・油・みりん・醤油などは「その他」にしてください。
        液体調味料（醤油・みりん・酒・油・だし汁など）の量は必ずml単位で返してください。
        　例：大さじ1 → 15ml、小さじ1 → 5ml、大さじ2 → 30ml
        粉末・固形調味料（塩・砂糖・片栗粉など）はg単位で返してください。
        　例：小さじ1 → 3g、大さじ1 → 9g
        卵・豆腐などは個・丁などの個数単位で返してください。
        肉・魚はg単位で返してください。
        野菜は個・本・袋など一般的な単位で返してください。
        ご飯・白米は必ず「1膳」という単位で返してください。categoryは「米・穀物」にしてください。
        """

        do {
            // Claude APIにリクエストを送る
            let url = URL(string: "https://api.anthropic.com/v1/messages")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
            request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

            let body: [String: Any] = [
                "model": "claude-sonnet-4-6",
                "max_tokens": 4000,
                "messages": [
                    ["role": "user", "content": prompt]
                ]
            ]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)

            // レスポンスを受け取る
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(ClaudeResponse.self, from: data)

            if response.isError {
                throw NSError(domain: "APIError", code: 0,
                              userInfo: [NSLocalizedDescriptionKey: response.errorMessage])
            }

            guard let text = response.content?.first?.text else {
                throw NSError(domain: "ParseError", code: 0,
                              userInfo: [NSLocalizedDescriptionKey: "レスポンスの形式が不正です"])
            }

            // JSONをパースして献立データに変換する
            let cleanText = text
                .replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            guard let jsonData = cleanText.data(using: .utf8) else {
                throw NSError(domain: "ParseError", code: 1)
            }

            let decoded = try JSONDecoder().decode([MealJSON].self, from: jsonData)
            mealPlan = decoded.map {
                Meal(day: $0.day, mealTime: $0.mealTime, name: $0.name, memo: $0.memo)
            }

            // 献立をUserDefaultsに保存
            if let savedData = try? JSONEncoder().encode(mealPlan) {
                UserDefaults.standard.set(savedData, forKey: "savedMealPlan")
            }

            // 食材データを [料理名: [食材]] の形で保存
            var ingredientsMap: [String: [[String: String]]] = [:]
            for item in decoded {
                ingredientsMap[item.name] = item.ingredients.map {
                    ["name": $0.name, "amount": $0.amount, "category": $0.category]
                }
            }
            if let ingredientsData = try? JSONSerialization.data(withJSONObject: ingredientsMap) {
                UserDefaults.standard.set(ingredientsData, forKey: "savedIngredients")
            }

        } catch {
            errorMessage = "エラー：\(error.localizedDescription)\n\nデバッグ用：\(error)"
        }

        isLoading = false
    }
}

// -------------------------------------------------------
// DayMealCard
// 1日分の献立カード
// -------------------------------------------------------
struct DayMealCard: View {
    let day: String
    let meals: [Meal]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 曜日ヘッダー
            Text("\(day)曜日")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(dayColor(day))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(dayColor(day).opacity(0.08))

            // 食事リスト
            ForEach(meals) { meal in
                // NavigationLink = タップすると詳細画面に遷移する
                NavigationLink(destination: MealDetailView(meal: meal)) {
                    HStack(spacing: 12) {
                        // 朝・昼・夜バッジ
                        Text(meal.mealTime)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(width: 28, height: 28)
                            .background(mealColor(meal.mealTime))
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 2) {
                            Text(meal.name)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.primary)
                            Text(meal.memo)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }

                if meal.id != meals.last?.id {
                    Divider().padding(.leading, 56)
                }
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
    }

    func dayColor(_ day: String) -> Color {
        if day == "土" { return .blue }
        if day == "日" { return .red }
        return Color(hex: "1D9E75")
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
// APIレスポンスのデータ構造
// Claudeから返ってくるJSONをSwiftで受け取るための型
// -------------------------------------------------------
struct MealJSON: Codable {
    let day: String
    let mealTime: String
    let name: String
    let memo: String
    let ingredients: [IngredientJSON]
}

struct IngredientJSON: Codable {
    let name: String
    let amount: String
    let category: String
}

// -------------------------------------------------------
// プレビュー
// -------------------------------------------------------
#Preview {
    MealPlanView()
}
