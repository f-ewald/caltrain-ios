//
//  Screenshot.swift
//  caltrainUITests
//
//  Created by Friedrich Ewald on 2/1/26.
//

import XCTest

final class Screenshot: XCTestCase {
    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        false
    }

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testMainScreen() throws {
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launch()

        // Wait for app to load and show header
        let headerText = app.staticTexts["Baby Bullet"]
        XCTAssertTrue(headerText.waitForExistence(timeout: 20))

        // Wait for departures to load from API (adjust timing as needed)
        sleep(10)

        // Screenshot 1: Main screen with departures
        snapshot("01-MainScreen")
        
        let nearestStationButton = app.buttons["station.nearest"]
        print(app.debugDescription)
        XCTAssert(nearestStationButton.waitForExistence(timeout: 5))
        nearestStationButton.tap()
//        app.descendants(matching: .any)["station.nearest"].tap()

        // Screenshot 2: Scroll to show more departure information
        app.swipeUp()
        sleep(1)
        snapshot("02-DeparturesList")

        // Screenshot 3: Navigate to all stations list
        // Tap on any button/link that navigates to station selection
        let buttons = app.buttons
        for i in 0..<buttons.count {
            let button = buttons.element(boundBy: i)
            if button.label.contains("Station") || button.label.contains("station") {
                button.tap()
                sleep(1)
                snapshot("03-AllStations")

                // Screenshot 4: Scroll to show station amenities
                app.swipeUp()
                sleep(1)
                snapshot("04-StationAmenities")

                // Return to main screen
                if app.navigationBars.buttons.count > 0 {
                    app.navigationBars.buttons.firstMatch.tap()
                    sleep(1)
                }
                break
            }
        }

        // Screenshot 5: Alternative view (scroll position)
        snapshot("05-AlternateView")
    }

    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
