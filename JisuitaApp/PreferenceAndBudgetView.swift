import SwiftUI

struct PreferenceAndBudgetView: View {
    @AppStorage("cuisineGenre") private var cuisineGenre = "ミックス"
    @AppStorage("flavorStrength") private var flavorStrength = "ふつう"
    @AppStorage("richnessLevel") private var richnessLevel = "ふつう"
    @AppStorage("monthlyBudget") private var monthlyBudget = 30000

    let cuisineGenres = ["和食", "洋食", "アジア", "ミックス"]
    let flavorOptions = ["甘め", "ふつう", "辛め"]
    let richnessOptions = ["あっさり", "ふつう", "こってり"]

    var body: some View {
        Form {
            Section(header: Text("料理のジャンル")) {
                SegmentedPickerRow(options: cuisineGenres, selection: $cuisineGenre)
            }

            Section(header: Text("味の好み")) {
                SegmentedPickerRow(options: flavorOptions, selection: $flavorStrength)
            }

            Section(header: Text("こってり度")) {
                SegmentedPickerRow(options: richnessOptions, selection: $richnessLevel)
            }

            Section(header: Text("月の食費予算")) {
                HStack {
                    Text("¥")
                        .foregroundColor(.secondary)
                    TextField("30000", value: $monthlyBudget, format: .number)
                        .keyboardType(.numberPad)
                    Text("円 / 月")
                        .foregroundColor(.secondary)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("よく使われる予算")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    HStack(spacing: 10) {
                        ForEach([20000, 25000, 30000, 40000], id: \.self) { amount in
                            Button(action: { monthlyBudget = amount }) {
                                Text("¥\(amount / 1000)k")
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(monthlyBudget == amount
                                        ? Color(hex: "1D9E75")
                                        : Color(.systemFill))
                                    .foregroundColor(monthlyBudget == amount ? .white : .primary)
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("好みと予算の設定")
        .navigationBarTitleDisplayMode(.large)
    }
}

private struct SegmentedPickerRow: View {
    let options: [String]
    @Binding var selection: String

    var body: some View {
        Picker("", selection: $selection) {
            ForEach(options, id: \.self) { Text($0) }
        }
        .pickerStyle(.segmented)
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        PreferenceAndBudgetView()
    }
}
