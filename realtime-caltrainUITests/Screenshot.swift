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

        // In UI tests it's important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.

        // Handle location permission dialog on fresh app installs
        addUIInterruptionMonitor(withDescription: "Location Permission") { alert in
            let allowButton = alert.buttons["Allow While Using App"]
            if allowButton.exists {
                allowButton.tap()
                return true
            }
            return false
        }
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    @MainActor
    func testFavoriteView() throws {
        let app = XCUIApplication()

        // Set simulated location before launch (San Francisco Caltrain Station)
        XCUIDevice.shared.location = XCUILocation(
            location: CLLocation(latitude: 37.7762, longitude: -122.3947)
        )

        // Force portrait orientation for consistent screenshots (especially iPad)
        XCUIDevice.shared.orientation = .portrait

        setupSnapshot(app)
        app.launch()
        
        let nearestStationButton = app.buttons["station.nearest"]
        
        // Button is expected to be there
        XCTAssert(nearestStationButton.waitForExistence(timeout: 5))
        
        nearestStationButton.tap()
        
        // Make station a favorite
        app.buttons["station.favorite.SF"].tap()
        app.buttons["station.favorite.22ND"].tap()
        sleep(2)
        app.navigationBars.buttons.element(boundBy: 0).tap()
        sleep(1)
        snapshot("001-MainScreenWithFavorites")
        sleep(1)
    }
    
    

    @MainActor
    func testMainScreen() throws {
        let app = XCUIApplication()

        // Set simulated location before launch (San Francisco Caltrain Station)
        XCUIDevice.shared.location = XCUILocation(
            location: CLLocation(latitude: 37.7762, longitude: -122.3947)
        )

        // Force portrait orientation for consistent screenshots (especially iPad)
        XCUIDevice.shared.orientation = .portrait

        setupSnapshot(app)
        app.launch()

        // Tap a safe area to trigger any pending interruption monitors (e.g. location permission dialog).
        // Use the navigation bar area (top of screen) to avoid accidentally tapping interactive content.
//        sleep(2)
//        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.05)).tap()
//        sleep(1)

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
        
        // Button is expected to be there
        XCTAssert(nearestStationButton.waitForExistence(timeout: 5))
        
        nearestStationButton.tap()
        let stationInfoButton = app.buttons["station.info.22ND"]
        XCTAssert(stationInfoButton.waitForExistence(timeout: 2))
        stationInfoButton.tap()
        sleep(5)
        snapshot("03-StationDetail")
        
        let stationInfoCloseButton = app.buttons["station.detail.close"]
        XCTAssert(stationInfoCloseButton.waitForExistence(timeout: 1))
        stationInfoCloseButton.tap()
        sleep(10)
        
        
//        if nearestStationButton.waitForExistence(timeout: 15) {
//            print("Found nearest station element, tapping...")
//            nearestStationButton.tap()
//            sleep(2)
//
//            // Screenshot 2: All stations list
//            snapshot("02-AllStations")
//
//            // Screenshot 3: Scroll to show more stations
//            app.swipeUp()
//            sleep(1)
//            snapshot("03-StationList")
//
//            // Return to main screen
//            if app.navigationBars.buttons.count > 0 {
//                app.navigationBars.buttons.firstMatch.tap()
//                sleep(1)
//            }
//        } else {
//            print("Nearest station element not found, skipping station list screenshots")
//        }
//
//        // Screenshot 4: Scroll to show more departure information on main screen
//        app.swipeUp()
//        sleep(1)
//        snapshot("04-DeparturesList")
    }

    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
