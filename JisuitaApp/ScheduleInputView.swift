import SwiftUI

// -------------------------------------------------------
// MealSlot
// 1マス分のデータ（例：月曜日の朝）
// Codable = UserDefaultsに保存するため
// -------------------------------------------------------
//struct MealSlot: Identifiable, Codable {
//    var id = UUID()
//    var day: String      // 曜日（例："月"）
//    var meal: String     // 食事（"朝" / "昼" / "夜"）
//    var isCooking: Bool  // 自炊するか
//}

// -------------------------------------------------------
// ScheduleInputView
// 週の自炊スケジュール入力画面
// -------------------------------------------------------
struct ScheduleInputView: View {

    // 曜日と食事の種類
    let weekdays = ["月", "火", "水", "木", "金", "土", "日"]
    let meals = ["朝", "昼", "夜"]

    // スケジュールデータ（曜日×食事のマス目）
    // 初期値はすべて「自炊する」にしておく
    @State private var slots: [MealSlot] = {
        let weekdays = ["月", "火", "水", "木", "金", "土", "日"]
        let meals = ["朝", "昼", "夜"]
        var result: [MealSlot] = []
        for day in weekdays {
            for meal in meals {
                result.append(MealSlot(day: day, mealTime: meal, isCooking: true))
            }
        }
        return result
    }()

    // 保存完了メッセージ
    @State private var showSavedMessage = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                // -----------------------------------------------
                // ヘッダー行（朝・昼・夜のラベル）
                // -----------------------------------------------
                HStack(spacing: 0) {
                    // 曜日列のスペース
                    Text("")
                        .frame(width: 44)

                    ForEach(meals, id: \.self) { meal in
                        Text(meal)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(.systemGroupedBackground))

                Divider()

                // -----------------------------------------------
                // スケジュールのマス目
                // -----------------------------------------------
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(weekdays, id: \.self) { day in
                            HStack(spacing: 0) {

                                // 曜日ラベル
                                Text(day)
                                    .font(.system(size: 15, weight: .medium))
                                    .frame(width: 44)
                                    .foregroundColor(dayColor(day))

                                // 朝・昼・夜のチェックマス
                                ForEach(meals, id: \.self) { meal in
                                    let index = slotIndex(day: day, meal: meal)
                                    Button(action: {
                                        slots[index].isCooking.toggle()
                                    }) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(slots[index].isCooking
                                                      ? Color(hex: "1D9E75").opacity(0.15)
                                                      : Color(.systemGray6))
                                                .frame(height: 52)
                                                .padding(4)

                                            Image(systemName: slots[index].isCooking
                                                  ? "checkmark.circle.fill"
                                                  : "circle")
                                                .font(.system(size: 22))
                                                .foregroundColor(slots[index].isCooking
                                                                 ? Color(hex: "1D9E75")
                                                                 : Color(.systemGray3))
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                            }
                            .padding(.horizontal, 16)

                            Divider()
                                .padding(.leading, 44)
                        }
                    }
                    .padding(.top, 4)

                    // -----------------------------------------------
                    // 自炊回数のサマリー
                    // -----------------------------------------------
                    VStack(spacing: 4) {
                        Text("今週の自炊回数")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Text("\(cookingCount) 回 / 21回")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(Color(hex: "1D9E75"))

                        Text("（朝\(mealCount("朝"))・昼\(mealCount("昼"))・夜\(mealCount("夜"))）")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(Color(.systemGroupedBackground))
                    .cornerRadius(12)
                    .padding(16)

                    // -----------------------------------------------
                    // 献立を作成するボタン
                    // -----------------------------------------------
                    Button(action: saveAndGenerate) {
                        HStack {
                            Image(systemName: "sparkles")
                            Text("この内容で献立を作成する")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(hex: "1D9E75"))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
                }
                .background(Color(.systemBackground))
            }
            .navigationTitle("今週の自炊スケジュール")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                // 右上に「全選択 / 全解除」ボタン
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(allSelected ? "全解除" : "全選択") {
                        let newValue = !allSelected
                        for i in slots.indices {
                            slots[i].isCooking = newValue
                        }
                    }
                    .foregroundColor(Color(hex: "1D9E75"))
                }
            }
            .alert("保存しました", isPresented: $showSavedMessage) {
                Button("OK") {}
            } message: {
                Text("スケジュールを保存しました。\n次は献立プランを確認してください。")
            }
        }
    }

    // -------------------------------------------------------
    // ヘルパー関数
    // -------------------------------------------------------

    // 曜日とメール名からslotsの配列番号を返す
    func slotIndex(day: String, meal: String) -> Int {
        let dayIndex = weekdays.firstIndex(of: day) ?? 0
        let mealIndex = meals.firstIndex(of: meal) ?? 0
        return dayIndex * 3 + mealIndex
    }

    // 自炊する合計回数
    var cookingCount: Int {
        slots.filter { $0.isCooking }.count
    }

    // 食事ごとの自炊回数
    func mealCount(_ meal: String) -> Int {
        slots.filter { $0.mealTime == meal && $0.isCooking }.count
    }

    // 全部選択されているか
    var allSelected: Bool {
        slots.allSatisfy { $0.isCooking }
    }

    // 土日は色を変える
    func dayColor(_ day: String) -> Color {
        if day == "土" { return .blue }
        if day == "日" { return .red }
        return .primary
    }

    // 保存処理
    func saveAndGenerate() {
        if let encoded = try? JSONEncoder().encode(slots) {
            UserDefaults.standard.set(encoded, forKey: "weeklySchedule")
        }
        showSavedMessage = true
    }
}

// -------------------------------------------------------
// プレビュー
// -------------------------------------------------------
#Preview {
    ScheduleInputView()
}
