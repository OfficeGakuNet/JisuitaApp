import SwiftUI

struct ShoppingListView: View {
    @StateObject private var viewModel = ShoppingListViewModel.shared
    @EnvironmentObject private var mealPlanViewModel: MealPlanViewModel
    @AppStorage("fixedMenus") private var fixedMenusData: Data = Data()

    @State private var showAddSheet = false
    @State private var showClearConfirm = false
    @State private var showGenerateConfirm = false

    private var fixedMenus: [FixedMenu] {
        (try? JSONDecoder().decode([FixedMenu].self, from: fixedMenusData)) ?? []
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                generateBanner

                if viewModel.items.isEmpty && !viewModel.isGenerating {
                    emptyState
                } else {
                    itemList
                }
            }
        }
        .navigationTitle("買い出しリスト")
        .navigationBarTitleDisplayMode(.large)
        .toolbar { toolbarItems }
        .sheet(isPresented: $showAddSheet) {
            AddShoppingItemSheet { item in
                viewModel.addManualItem(item)
            }
        }
        .alert("リストをクリア", isPresented: $showClearConfirm) {
            Button("チェック済みを削除", role: .destructive) { viewModel.clearChecked() }
            Button("すべて削除", role: .destructive) { viewModel.clearAll() }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("どちらを削除しますか？")
        }
        .alert("買い出しリストを再生成", isPresented: $showGenerateConfirm) {
            Button("生成する", role: .destructive) {
                Task { await viewModel.generateFromMealPlan(
                    slots: mealPlanViewModel.slots,
                    fixedMenus: fixedMenus
                )}
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("現在のリスト（未チェック）は上書きされます")
        }
    }

    private var generateBanner: some View {
        Button {
            if viewModel.items.isEmpty {
                Task { await viewModel.generateFromMealPlan(
                    slots: mealPlanViewModel.slots,
                    fixedMenus: fixedMenus
                )}
            } else {
                showGenerateConfirm = true
            }
        } label: {
            HStack(spacing: 12) {
                if viewModel.isGenerating {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(0.9)
                } else {
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 18, weight: .semibold))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.isGenerating ? "食材を取得中..." : "献立から買い出しリストを生成")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    if let date = viewModel.lastGeneratedAt {
                        Text("最終生成: " + date.formatted(date: .omitted, time: .shortened))
                            .font(.caption)
                            .opacity(0.85)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .opacity(0.8)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(hex: "1D9E75"))
        }
        .disabled(viewModel.isGenerating)

        if let err = viewModel.errorMessage {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text(err)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground))
        }
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "買い出しリストが空です",
            systemImage: "cart",
            description: Text("上のボタンで献立から自動生成するか\n右上の＋で手動追加できます")
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var itemList: some View {
        List {
            if viewModel.uncheckedCount > 0 {
                Section {
                    HStack {
                        Image(systemName: "bag.fill")
                            .foregroundColor(Color(hex: "1D9E75"))
                        Text("残り \(viewModel.uncheckedCount) 品")
                            .fontWeight(.semibold)
                        Spacer()
                        Text("\(viewModel.items.count) 品合計")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            ForEach(viewModel.groupedItems, id: \.category) { group in
                Section {
                    ForEach(group.items) { item in
                        ShoppingItemRow(item: item) {
                            viewModel.toggleChecked(item: item)
                        }
                    }
                    .onDelete { offsets in
                        viewModel.deleteItems(at: offsets, in: group.category)
                    }
                } header: {
                    CategoryHeader(category: group.category)
                }
            }

            if viewModel.items.contains(where: { $0.isChecked }) {
                Section {
                    Button(role: .destructive) {
                        viewModel.clearChecked()
                    } label: {
                        Label("チェック済みを削除", systemImage: "trash")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            HStack(spacing: 16) {
                if !viewModel.items.isEmpty {
                    Button {
                        showClearConfirm = true
                    } label: {
                        Image(systemName: "trash")
                    }
                    .tint(.red)
                }
                Button {
                    showAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .tint(Color(hex: "1D9E75"))
            }
        }
    }
}

private struct CategoryHeader: View {
    let category: ShoppingCategory

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: category.icon)
                .foregroundColor(Color(hex: category.color))
                .font(.caption)
            Text(category.rawValue)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
    }
}

private struct ShoppingItemRow: View {
    let item: ShoppingItem
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(item.isChecked ? Color(hex: "1D9E75") : Color(.tertiaryLabel))

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(.body)
                        .strikethrough(item.isChecked)
                        .foregroundColor(item.isChecked ? .secondary : .primary)
                    Text(item.amount)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
        }
        .buttonStyle(.plain)
    }
}
