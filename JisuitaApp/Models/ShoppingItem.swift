import Foundation

struct ShoppingItem: Identifiable, Codable {
    var id = UUID()
    var name: String
    var amount: String
    var category: ShoppingCategory
    var isChecked: Bool = false
    var sourceMeals: [String] = []
}

enum ShoppingCategory: String, Codable, CaseIterable {
    case vegetable = "野菜"
    case meat = "肉類"
    case fish = "魚介類"
    case dairy = "乳製品・卵"
    case seasoning = "調味料"
    case grain = "穀物・米"
    case other = "その他"

    var icon: String {
        switch self {
        case .vegetable: return "leaf.fill"
        case .meat: return "fork.knife"
        case .fish: return "water.waves"
        case .dairy: return "cup.and.saucer.fill"
        case .seasoning: return "shaker.vertical.fill"
        case .grain: return "grain"
        case .other: return "bag.fill"
        }
    }

    var color: String {
        switch self {
        case .vegetable: return "34A853"
        case .meat: return "EA4335"
        case .fish: return "4285F4"
        case .dairy: return "FBBC05"
        case .seasoning: return "FF6D00"
        case .grain: return "795548"
        case .other: return "9E9E9E"
        }
    }
}
