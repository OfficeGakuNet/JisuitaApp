import SwiftUI

struct ContentView: View {

    @State private var selectedTab = 0
    @StateObject private var mealPlanViewModel = MealPlanViewModel.shared
    @StateObject private var userSettings = UserSettings.shared

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

            RecordTabView()
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
        .environmentObject(mealPlanViewModel)
        .environmentObject(userSettings)
    }
}

struct RecordTabView: View {
    var body: some View {
        NavigationStack {
            RecordTopView()
        }
    }
}

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

                if selectedPage == 0 {
                    ShoppingListView()
                        .transition(.opacity)
                } else {
                    IngredientTrackerView()
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut, value: selectedPage)
            .background(Color(.systemGroupedBackground))
            .navigationTitle(selectedPage == 0 ? "買い出しリスト" : "食材トラッカー")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}
