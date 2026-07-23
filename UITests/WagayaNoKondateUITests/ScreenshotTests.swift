import XCTest

final class ScreenshotTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testCaptureAllScreens() throws {
        let app = XCUIApplication()
        app.launchArguments += ["UI_TESTING"]
        app.launch()

        _ = app.tabBars.buttons["レシピ"].waitForExistence(timeout: 10)
        _ = app.staticTexts["鶏肉の甘辛カレー"].waitForExistence(timeout: 10)
        attachScreenshot(app: app, name: "01_Recipes")

        if app.staticTexts["鶏肉の甘辛カレー"].exists {
            app.staticTexts["鶏肉の甘辛カレー"].tap()
            _ = app.staticTexts["あなたの評価"].waitForExistence(timeout: 5)
            attachScreenshot(app: app, name: "02_RecipeDetail")
            app.navigationBars.buttons.element(boundBy: 0).tap()
        }

        app.tabBars.buttons["冷蔵庫"].tap()
        _ = app.navigationBars["冷蔵庫"].waitForExistence(timeout: 5)
        attachScreenshot(app: app, name: "03_Fridge")

        app.tabBars.buttons["投票"].tap()
        _ = app.navigationBars["今日の投票"].waitForExistence(timeout: 5)
        attachScreenshot(app: app, name: "04_Voting")

        app.tabBars.buttons["今週"].tap()
        _ = app.navigationBars["今週"].waitForExistence(timeout: 5)
        attachScreenshot(app: app, name: "05_Weekly")

        app.tabBars.buttons["設定"].tap()
        _ = app.navigationBars["設定"].waitForExistence(timeout: 5)
        attachScreenshot(app: app, name: "06_Settings")
    }

    private func attachScreenshot(app: XCUIApplication, name: String) {
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
