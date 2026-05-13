import SwiftUI

@main
struct JisuitaAppApp: App {

    init() {
        AppDefaults.registerDefaults()
        AppDefaults.migrateIfNeeded()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
