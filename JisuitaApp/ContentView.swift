import SwiftUI

// -------------------------------------------------------
// ContentView
// アプリ全体のタブバーを管理する画面
// -------------------------------------------------------
struct ContentView: View {

    // 現在選ばれているタブを管理する
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {

            // -----------------------------------------------
            // タブ1：ホーム
            // -----------------------------------------------
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("ホーム")
                }
                .tag(0)

            // -----------------------------------------------
            // タブ2：献立
            // -----------------------------------------------
            MealPlanView()
                .tabItem {
                    Image(systemName: "fork.knife")
                    Text("献立")
                }
                .tag(1)

            // -----------------------------------------------
            // タブ3：買い出し
            // -----------------------------------------------
            ShoppingTabView()
                .tabItem {
                    Image(systemName: "cart.fill")
                    Text("買い出し")
                }
                .tag(2)

            // -----------------------------------------------
            // タブ4：記録
            // -----------------------------------------------
            NavigationStack {
                RecordTopView()
            }
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("記録")
                }
                .tag(3)

            // -----------------------------------------------
            // タブ5：設定
            // -----------------------------------------------
            SettingsTabView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("設定")
                }
                .tag(4)
        }
        .tint(Color(hex: "1D9E75")) // 選択中のタブの色
    }
}

// -------------------------------------------------------
// ShoppingTabView
// 買い出しタブ：買い出しリストと食材トラッカーを切り替え
// -------------------------------------------------------
struct ShoppingTabView: View {
    @State private var selectedPage = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                // 切り替えピッカー
                Picker("", selection: $selectedPage) {
                    Text("買い出し").tag(0)
                    Text("食材").tag(1)
                    Text("調味料").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)

                Divider()

                // 選択中の画面を表示
                if selectedPage == 0 {
                    ShoppingListView()
                } else if selectedPage == 1 {
                    IngredientTrackerView()
                } else {
                    SeasoningView()
                }
            }
            .navigationTitle("買い出し")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// -------------------------------------------------------
// HomeView
// ホーム画面（今日の概要）
// ※ 後で本格的に作る。今はプレースホルダー。
// -------------------------------------------------------
struct HomeView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "house.fill")
                    .font(.system(size: 50))
                    .foregroundColor(Color(hex: "1D9E75"))
                Text("ホーム画面")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("今日の体重・カロリー・献立などを\nここに表示します")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }
            .navigationTitle("今日")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// -------------------------------------------------------
// ShoppingView
// 買い出し画面
// ※ 後で本格的に作る。今はプレースホルダー。
// -------------------------------------------------------
struct ShoppingView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "cart.fill")
                    .font(.system(size: 50))
                    .foregroundColor(Color(hex: "1D9E75"))
                Text("買い出し画面")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("買い出しリスト・食材トラッカー・\nレシート読み取りをここに表示します")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }
            .navigationTitle("買い出し")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// -------------------------------------------------------
// RecordView
// 記録画面
// ※ 後で本格的に作る。今はプレースホルダー。
// -------------------------------------------------------
struct RecordView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 50))
                    .foregroundColor(Color(hex: "1D9E75"))
                Text("記録画面")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("体重グラフ・食事記録・歩数を\nここに表示します")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }
            .navigationTitle("記録")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// -------------------------------------------------------
// SettingsTabView
// 設定タブ：各設定画面へのナビゲーションリスト
// -------------------------------------------------------
struct SettingsTabView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("プロフィール") {
                    NavigationLink(destination: ProfileSettingView()) {
                        Label("プロフィール設定", systemImage: "person.circle")
                    }
                }
                Section("食事の設定") {
                    NavigationLink(destination: FixedMenuSettingView()) {
                        Label("固定メニューの登録", systemImage: "pin.fill")
                    }
                    NavigationLink(destination: PreferenceAndBudgetView()) {
                        Label("好みと予算の設定", systemImage: "slider.horizontal.3")
                    }
                    NavigationLink(destination: SeasoningView()) {
                        Label("調味料の管理", systemImage: "fork.knife.circle")
                    }
                }
                Section("アラート") {
                    NavigationLink(destination: ExpiryAlertView()) {
                        Label("賞味期限アラート", systemImage: "exclamationmark.triangle")
                    }
                }
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// -------------------------------------------------------
// プレビュー
// -------------------------------------------------------
#Preview {
    ContentView()
}
