import SwiftUI

struct StorageGuideIngredient: Identifiable {
    let id = UUID()
    let name: String
    let emoji: String
    let steps: [String]
}

struct StorageGuideView: View {
    let ingredients: [StorageGuideIngredient] = [
        StorageGuideIngredient(name: "鶏むね肉", emoji: "🍗", steps: [
            "100g × 3 に切り分ける",
            "ジッパー袋に入れて冷凍（使う分だけ解凍）",
            "保存期限：冷凍で約3週間"
        ]),
        StorageGuideIngredient(name: "ほうれん草", emoji: "🥬", steps: [
            "さっと茹でて水気を絞る",
            "1回分ずつラップで包んで冷凍",
            "保存期限：冷凍で約1ヶ月"
        ]),
        StorageGuideIngredient(name: "豆腐", emoji: "🫙", steps: [
            "水切りして使う分に切り分ける",
            "残りは水に浸けてタッパーで冷蔵",
            "保存期限：冷蔵で2〜3日。毎日水を替える"
        ]),
        StorageGuideIngredient(name: "にんじん", emoji: "🥕", steps: [
            "泥をよく洗い流す",
            "ペーパータオルで包んでビニール袋に入れ冷蔵",
            "保存期限：冷蔵で約2週間"
        ])
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(ingredients) { item in
                    StorageGuideCard(item: item)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("買い帰ったらすること")
        .navigationBarTitleDisplayMode(.large)
    }
}

private struct StorageGuideCard: View {
    let item: StorageGuideIngredient

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text(item.emoji)
                    .font(.title2)
                Text(item.name)
                    .font(.headline)
            }

            Divider()

            ForEach(Array(item.steps.enumerated()), id: \.offset) { idx, step in
                HStack(alignment: .top, spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "1D9E75"))
                            .frame(width: 22, height: 22)
                        Text("\(idx + 1)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    Text(step)
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

#Preview {
    NavigationStack {
        StorageGuideView()
    }
}
