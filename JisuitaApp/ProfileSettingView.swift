import SwiftUI

// -------------------------------------------------------
// MustEatItem
// 「必ず食べたいもの」1件分のデータ
// Identifiable = ForEachで使うためのプロトコル
// Codable = UserDefaultsに保存するためのプロトコル
// -------------------------------------------------------
struct MustEatItem: Identifiable, Codable {
    var id = UUID()        // 各アイテムを区別するためのユニークID
    var food: String = ""  // 食材名
    var frequency: String = "毎日"  // 頻度
}

// -------------------------------------------------------
// ProfileSettingView
// プロフィール設定画面
// -------------------------------------------------------

struct ProfileSettingView: View {

    // @State = 「この値が変わったら画面を自動で更新してね」という印
    @State private var height: String = ""        // 身長（cm）
    @State private var weight: String = ""        // 体重（kg）
    @State private var targetWeight: String = ""  // 目標体重（kg）
    @State private var age: String = ""           // 年齢

    // 買い出し曜日（複数選択できるようにSet<String>で管理）
    @State private var shoppingDays: Set<String> = []

    // お弁当を作るか
    @State private var makesBento: Bool = false

    // 苦手食材・アレルギー（自由入力）
    @State private var avoidFoods: String = ""

    // 必ず食べたいもの（複数登録できるようにリストで管理）
    @State private var mustEatItems: [MustEatItem] = [MustEatItem()]

    // 頻度の選択肢
    let frequencyOptions = ["毎日", "週2〜3回", "週1回"]

    // 活動量の選択肢
    @State private var activityLevel: String = "デスクワーク"
    let activityOptions = ["デスクワーク", "体を動かす仕事", "よく運動する"]

    // 曜日の選択肢
    let weekdays = ["月", "火", "水", "木", "金", "土", "日"]

    // 保存完了メッセージを表示するフラグ
    @State private var showSavedMessage: Bool = false

    var body: some View {
        // NavigationStack = 画面上部にタイトルが表示されるコンテナ
        NavigationStack {
            Form {

                // -----------------------------------------------
                // セクション1：基本情報
                // -----------------------------------------------
                Section(header: Text("基本情報")) {

                    // 身長入力
                    HStack {
                        Text("身長")
                        Spacer()
                        TextField("例：170", text: $height)
                            .keyboardType(.numberPad) // 数字キーボードを出す
                            .multilineTextAlignment(.trailing)
                        Text("cm")
                            .foregroundColor(.secondary)
                    }

                    // 体重入力
                    HStack {
                        Text("体重")
                        Spacer()
                        TextField("例：65", text: $weight)
                            .keyboardType(.decimalPad) // 小数点も入れられるキーボード
                            .multilineTextAlignment(.trailing)
                        Text("kg")
                            .foregroundColor(.secondary)
                    }

                    // 目標体重入力
                    HStack {
                        Text("目標体重")
                        Spacer()
                        TextField("例：60", text: $targetWeight)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("kg")
                            .foregroundColor(.secondary)
                    }

                    // 年齢入力
                    HStack {
                        Text("年齢")
                        Spacer()
                        TextField("例：30", text: $age)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                        Text("歳")
                            .foregroundColor(.secondary)
                    }

                    // 活動量（Picker = 選択式のUI）
                    Picker("活動量", selection: $activityLevel) {
                        ForEach(activityOptions, id: \.self) { option in
                            Text(option)
                        }
                    }
                }

                // -----------------------------------------------
                // セクション2：買い出し設定
                // -----------------------------------------------
                Section(header: Text("買い出し設定")) {

                    // 曜日を横に並べてタップで選択
                    VStack(alignment: .leading, spacing: 8) {
                        Text("買い出し曜日")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        HStack(spacing: 8) {
                            ForEach(weekdays, id: \.self) { day in
                                // 選択済みの曜日は色を変える
                                let isSelected = shoppingDays.contains(day)
                                Button(action: {
                                    if isSelected {
                                        shoppingDays.remove(day)
                                    } else {
                                        shoppingDays.insert(day)
                                    }
                                }) {
                                    Text(day)
                                        .font(.system(size: 14, weight: .medium))
                                        .frame(width: 36, height: 36)
                                        .background(isSelected ? Color(hex: "1D9E75") : Color(.systemGray6))
                                        .foregroundColor(isSelected ? .white : .primary)
                                        .clipShape(Circle())
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)

                    // お弁当スイッチ
                    Toggle("平日のお弁当を作る", isOn: $makesBento)
                        .tint(Color(hex: "1D9E75"))
                }

                // -----------------------------------------------
                // セクション3：食事の制限
                // -----------------------------------------------
                Section(header: Text("食事の制限"),
                        footer: Text("苦手なもの・アレルギーがあれば入力してください")) {
                    TextField("例：えび、納豆", text: $avoidFoods)
                }

                // -----------------------------------------------
                // セクション4：必ず食べたいもの
                // -----------------------------------------------
                Section(header: Text("必ず食べたいもの"),
                        footer: Text("献立を作るときに必ず組み込まれます")) {

                    // 登録済みのアイテムを一覧表示
                    ForEach($mustEatItems) { $item in
                        HStack(spacing: 8) {
                            // 食材名の入力欄
                            TextField("例：納豆", text: $item.food)

                            Divider()

                            // 頻度の選択（Picker）
                            Picker("", selection: $item.frequency) {
                                ForEach(frequencyOptions, id: \.self) { option in
                                    Text(option).tag(option)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(Color(hex: "1D9E75"))
                        }
                    }
                    // スワイプで削除できる
                    .onDelete { indexSet in
                        mustEatItems.remove(atOffsets: indexSet)
                    }

                    // 追加ボタン
                    Button(action: {
                        mustEatItems.append(MustEatItem())
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(Color(hex: "1D9E75"))
                            Text("追加する")
                                .foregroundColor(Color(hex: "1D9E75"))
                        }
                    }
                }

                // -----------------------------------------------
                // 保存ボタン
                // -----------------------------------------------
                Section {
                    Button(action: saveProfile) {
                        HStack {
                            Spacer()
                            Text("保存する")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowBackground(Color(hex: "1D9E75"))
                }
            }
            .navigationTitle("プロフィール設定")
            .navigationBarTitleDisplayMode(.large)
            // 保存完了のポップアップ
            .alert("保存しました", isPresented: $showSavedMessage) {
                Button("OK") {}
            } message: {
                Text("プロフィールを保存しました。")
            }
        }
    }

    // -------------------------------------------------------
    // 保存処理
    // UserDefaults = アプリ内にシンプルなデータを保存する仕組み
    // -------------------------------------------------------
    func saveProfile() {
        let defaults = UserDefaults.standard
        defaults.set(height, forKey: "height")
        defaults.set(weight, forKey: "weight")
        defaults.set(targetWeight, forKey: "targetWeight")
        defaults.set(age, forKey: "age")
        defaults.set(activityLevel, forKey: "activityLevel")
        defaults.set(Array(shoppingDays), forKey: "shoppingDays")
        defaults.set(makesBento, forKey: "makesBento")
        defaults.set(avoidFoods, forKey: "avoidFoods")

        // 必食アイテムはJSON形式に変換して保存
        if let encoded = try? JSONEncoder().encode(mustEatItems) {
            defaults.set(encoded, forKey: "mustEatItems")
        }

        showSavedMessage = true
    }
}

// -------------------------------------------------------
// Color(hex:) 拡張
// 16進数カラーコード（例："1D9E75"）をColorに変換するための
// 追加機能（extension）
// -------------------------------------------------------
extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >> 8) & 0xFF) / 255
        let b = Double(rgb & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

// -------------------------------------------------------
// プレビュー（Xcodeで見た目を確認するための設定）
// -------------------------------------------------------
#Preview {
    ProfileSettingView()
}
