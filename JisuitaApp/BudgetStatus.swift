import SwiftUI

enum BudgetStatus {
    case safe
    case caution
    case danger

    init(ratio: Double) {
        if ratio >= AppDefaults.BudgetThreshold.danger {
            self = .danger
        } else if ratio >= AppDefaults.BudgetThreshold.caution {
            self = .caution
        } else {
            self = .safe
        }
    }

    var color: Color {
        switch self {
        case .safe:    return Color(hex: "1D9E75")
        case .caution: return .orange
        case .danger:  return .red
        }
    }
}
