import SwiftUI

// -------------------------------------------------------
// ContentView
// アプリ全体のタブバーを管理する画面
// -------------------------------------------------------
struct ContentView: View {

    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {

            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("ホーム")
                }
                .tag(0)

            MealPlanView()
                .tabItem {
                    Image(systemName: "fork.knife")
                    Text("献立")
                }
                .tag(1)

            ShoppingTabView()
                .tabItem {
                    Image(systemName: "cart.fill")
                    Text("買い出し")
                }
                .tag(2)

            NavigationStack {
                RecordTopView()
            }
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("記録")
                }
                .tag(3)

            SettingsTabView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("設定")
                }
                .tag(4)
        }
        .tint(Color(hex: "1D9E75"))
    }
}

// -------------------------------------------------------
// ShoppingTabView
// 買い出しリストと食材トラッカーを切り替えるタブ画面
// -------------------------------------------------------
struct ShoppingTabView: View {

    @State private var selectedPage = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("ページ切り替え", selection: $selectedPage) {
                    Text("買い出しリスト").tag(0)
                    Text("食材トラッカー").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 12)
                .background(Color(.systemGroupedBackground))

                Divider()

                if selectedPage == 0 {
                    ShoppingListView()
                } else {
                    IngredientTrackerView()
                }
            }
            .navigationTitle(selectedPage == 0 ? "買い出しリスト" : "食材トラッカー")
            .navigationBarTitleDisplayMode(.large)
            .background(Color(.systemGroupedBackground))
        }
    }
}
