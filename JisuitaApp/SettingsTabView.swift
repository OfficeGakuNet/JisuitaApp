import SwiftUI

struct SettingsTabView: View {
    var body: some View {
        NavigationStack {
            SettingsMenuList()
                .navigationTitle("設定")
                .navigationBarTitleDisplayMode(.large)
        }
    }
}

private struct SettingsMenuList: View {
    var body: some View {
        List {
            Section("食費・予算") {
                NavigationLink(destination: BudgetSettingView()) {
                    Label("月間食費予算", systemImage: "yensign.circle")
                }
            }

            Section("献立・食事") {
                NavigationLink(destination: FixedMenuSettingView()) {
                    Label("固定メニュー", systemImage: "pin")
                }
            }

            Section("アプリ情報") {
                HStack {
                    Label("バージョン", systemImage: "info.circle")
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "--")
                        .foregroundColor(.secondary)
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

struct BudgetSettingView: View {
    @AppStorage(AppDefaults.monthlyBudgetKey) private var monthlyBudget = AppDefaults.monthlyBudget
    @State private var inputText = ""
    @State private var showSavedBanner = false
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isFocused: Bool

    var body: some View {
        List {
            Section {
                HStack {
                    Text("現在の予算")
                    Spacer()
                    Text("¥\(monthlyBudget.formatted())")
                        .foregroundColor(.secondary)
                }
            }

            Section("新しい予算を入力") {
                HStack {
                    Text("¥")
                        .foregroundColor(.secondary)
                    TextField("例: 30000", text: $inputText)
                        .keyboardType(.numberPad)
                        .focused($isFocused)
                }
            }

            Section {
                Button {
                    saveBudget()
                } label: {
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
                .disabled(parsedInput == nil)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("月間食費予算")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            inputText = String(monthlyBudget)
            isFocused = true
        }
        .overlay(alignment: .bottom) {
            if showSavedBanner {
                SavedBanner()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 16)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showSavedBanner)
    }

    private var parsedInput: Int? {
        guard let value = Int(inputText), value > 0 else { return nil }
        return value
    }

    private func saveBudget() {
        guard let value = parsedInput else { return }
        monthlyBudget = value
        isFocused = false
        showSavedBanner = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showSavedBanner = false
        }
    }
}

private struct SavedBanner: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(Color(hex: "1D9E75"))
            Text("予算を保存しました")
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.regularMaterial)
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
    }
}
