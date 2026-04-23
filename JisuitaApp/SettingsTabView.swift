import SwiftUI

struct SettingsTabView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("食事・プロフィール") {
                    NavigationLink(destination: ProfileSettingView()) {
                        Label("プロフィール設定", systemImage: "person.circle")
                    }
                    NavigationLink(destination: PreferenceAndBudgetView()) {
                        Label("食の好みと予算", systemImage: "heart.text.square")
                    }
                    NavigationLink(destination: FixedMenuSettingView()) {
                        Label("固定メニュー設定", systemImage: "pin.circle")
                    }
                }

                Section("アラート・通知") {
                    NavigationLink(destination: SkipAlertView()) {
                        Label("スキップアラート", systemImage: "bell.badge")
                    }
                    NavigationLink(destination: ExpiryAlertView()) {
                        Label("賞味期限アラート", systemImage: "clock.badge.exclamationmark")
                    }
                }

                Section("その他") {
                    NavigationLink(destination: ScheduleInputView()) {
                        Label("スケジュール入力", systemImage: "calendar")
                    }
                }
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    SettingsTabView()
}
