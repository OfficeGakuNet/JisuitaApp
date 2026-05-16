import SwiftUI

struct SettingsTabView: View {
    var body: some View {
        NavigationStack {
            SettingsListView()
                .navigationTitle("設定")
                .navigationBarTitleDisplayMode(.large)
        }
    }
}

private struct SettingsListView: View {
    var body: some View {
        List {
            Section("プロフィール") {
                NavigationLink("プロフィール設定") {
                    ProfileSettingsView()
                }
            }

            Section("献立") {
                NavigationLink("固定メニューの登録") {
                    FixedMenuSettingsView()
                }
                NavigationLink("今週の自炊スケジュール") {
                    CookingScheduleView()
                }
            }

            Section("食材") {
                NavigationLink("調味料の管理") {
                    SeasoningManagementView()
                }
            }

            Section("好みと予算") {
                NavigationLink("好みと予算の設定") {
                    PreferencesAndBudgetView()
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

struct PreferencesAndBudgetView: View {
    @AppStorage(AppDefaults.monthlyBudgetKey) private var monthlyBudget: Int = AppDefaults.monthlyBudget
    @State private var budgetInput: String = ""
    @State private var showSavedBanner: Bool = false
    @FocusState private var isFocused: Bool

    var body: some View {
        List {
            Section("月の食費予算") {
                HStack {
                    Text("予算上限")
                    Spacer()
                    HStack(spacing: 2) {
                        Text("¥")
                            .foregroundColor(.secondary)
                        TextField("30000", text: $budgetInput)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .focused($isFocused)
                            .frame(width: 100)
                    }
                }

                Button(action: saveBudget) {
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

            Section("料理の好み") {
                NavigationLink("料理ジャンル") {
                    Text("料理ジャンル設定")
                }
                NavigationLink("味の好み") {
                    Text("味の好み設定")
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("好みと予算の設定")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            budgetInput = String(monthlyBudget)
        }
        .overlay(alignment: .top) {
            if showSavedBanner {
                savedBanner
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(1)
            }
        }
        .animation(.spring(response: 0.4), value: showSavedBanner)
    }

    private var savedBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(Color(hex: "1D9E75"))
            Text("予算を保存しました")
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.regularMaterial, in: Capsule())
        .padding(.top, 8)
    }

    private func saveBudget() {
        guard let value = Int(budgetInput), value > 0 else { return }
        monthlyBudget = value
        isFocused = false
        showSavedBanner = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showSavedBanner = false
        }
    }
}
