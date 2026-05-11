import Foundation

struct FixedMenu: Identifiable, Codable {
    var id: UUID
    var name: String
    var mealTime: String
    var days: [String]
    var isEnabled: Bool

    init(
        id: UUID = UUID(),
        name: String = "",
        mealTime: String = "朝",
        days: [String] = [],
        isEnabled: Bool = true
    ) {
        self.id = id
        self.name = name
        self.mealTime = mealTime
        self.days = days
        self.isEnabled = isEnabled
    }
}

enum FixedMenuStore {
    static let key = "fixedMenus"

    static func load() -> [FixedMenu] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let menus = try? JSONDecoder().decode([FixedMenu].self, from: data)
        else { return [] }
        return menus
    }

    static func save(_ menus: [FixedMenu]) {
        guard let data = try? JSONEncoder().encode(menus) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
