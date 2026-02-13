//
//  Screenshot.swift
//  caltrainUITests
//
//  Created by Friedrich Ewald on 2/1/26.
//

import XCTest
import CoreLocation

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

        // Set simulated location before launch (San Francisco Caltrain Station)
        XCUIDevice.shared.location = XCUILocation(
            location: CLLocation(latitude: 37.7762, longitude: -122.3947)
        )

        setupSnapshot(app)
        app.launch()
        
        

        // Wait for app to load and show header
        let headerText = app.staticTexts["Baby Bullet"]
        XCTAssertTrue(headerText.waitForExistence(timeout: 20))

        // Wait for departures to load from API (adjust timing as needed)
        sleep(10)

        // Screenshot 1: Main screen with departures
        snapshot("01-MainScreen")

        // Try to tap nearest station if it appears (with timeout)
        // If location isn't available, skip this and continue with other screenshots
        let nearestStationButton = app.buttons["station.nearest"]
        if nearestStationButton.waitForExistence(timeout: 15) {
            print("Found nearest station element, tapping...")
            nearestStationButton.tap()
            sleep(2)

            // Screenshot 2: All stations list
            snapshot("02-AllStations")

            // Screenshot 3: Scroll to show more stations
            app.swipeUp()
            sleep(1)
            snapshot("03-StationList")

            // Return to main screen
            if app.navigationBars.buttons.count > 0 {
                app.navigationBars.buttons.firstMatch.tap()
                sleep(1)
            }
        } else {
            print("Nearest station element not found, skipping station list screenshots")
        }

        // Screenshot 4: Scroll to show more departure information on main screen
        app.swipeUp()
        sleep(1)
        snapshot("04-DeparturesList")
    }

    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
