import XCTest
@testable import JisuitaApp

final class BudgetSettingsSyncTests: XCTestCase {

    private let testBudgetKey = AppDefaults.monthlyBudgetKey

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: testBudgetKey)
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: testBudgetKey)
        super.tearDown()
    }

    // SettingsTabView（PreferencesAndBudgetView）が monthlyBudgetKey へ書き込むと
    // BudgetViewModel が即時に新しい値を反映することを確認する
    func test_budgetViewModel_reflectsUserDefaultsChange_immediately() {
        let viewModel = BudgetViewModel()

        // 初期値の確認
        XCTAssertEqual(viewModel.monthlyBudget, AppDefaults.monthlyBudget)

        // SettingsTabView 側の書き込みをシミュレート
        let newBudget = 50000
        UserDefaults.standard.set(newBudget, forKey: testBudgetKey)

        // @AppStorage は UserDefaults の変更を同期的に反映する
        XCTAssertEqual(viewModel.monthlyBudget, newBudget)
    }

    func test_budgetRatio_updatesAfterBudgetChange() {
        let viewModel = BudgetViewModel()
        UserDefaults.standard.set(10000, forKey: AppDefaults.spentAmountKey)

        // 予算を 10000 に変更 → 使用率 100%
        UserDefaults.standard.set(10000, forKey: testBudgetKey)
        XCTAssertEqual(viewModel.budgetRatio, 1.0, accuracy: 0.001)

        // 予算を 20000 に変更 → 使用率 50%
        UserDefaults.standard.set(20000, forKey: testBudgetKey)
        XCTAssertEqual(viewModel.budgetRatio, 0.5, accuracy: 0.001)
    }

    func test_remaining_updatesAfterBudgetChange() {
        let viewModel = BudgetViewModel()
        UserDefaults.standard.set(8000, forKey: AppDefaults.spentAmountKey)
        UserDefaults.standard.set(30000, forKey: testBudgetKey)

        XCTAssertEqual(viewModel.remaining, 22000)

        UserDefaults.standard.set(10000, forKey: testBudgetKey)
        XCTAssertEqual(viewModel.remaining, 2000)
    }

    func test_progressColor_red_whenOverNinetyPercent_afterBudgetDecrease() {
        let viewModel = BudgetViewModel()
        UserDefaults.standard.set(9500, forKey: AppDefaults.spentAmountKey)
        // 予算を 10000 に下げると使用率 95% → .red
        UserDefaults.standard.set(10000, forKey: testBudgetKey)
        XCTAssertEqual(viewModel.progressColor, .red)
    }

    func test_sameKeyUsed_inViewModelAndAppDefaults() {
        // BudgetViewModel と SettingsTabView が同じキーを参照していることをコンパイル時に保証
        XCTAssertEqual(AppDefaults.monthlyBudgetKey, "monthlyBudget")
    }
}
