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
        continueAfterFailure = false
    }

    @MainActor
    func testScreenshots() throws {
        let app = XCUIApplication()

        // Set simulated location before launch (San Francisco Caltrain Station)
        XCUIDevice.shared.location = XCUILocation(
            location: CLLocation(latitude: 37.7762, longitude: -122.3947)
        )

        // Force portrait orientation for consistent screenshots (especially iPad)
        XCUIDevice.shared.orientation = .portrait

        setupSnapshot(app)
        app.launch()

        // Dismiss location permission dialog if it appears (via SpringBoard)
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let allowButton = springboard.buttons["Allow While Using App"]
        if allowButton.waitForExistence(timeout: 3) {
            allowButton.tap()
            sleep(1)
        }

        // Wait for app to load and show header
        let headerText = app.staticTexts["Baby Bullet"]
        XCTAssertTrue(headerText.waitForExistence(timeout: 20))

        // Wait for departures to load from API
        sleep(10)

        // Screenshot 1: Main screen with nearest station and departures
        snapshot("01-MainScreen")

        // Navigate to all stations list
        let nearestStationButton = app.buttons["station.nearest"]
        XCTAssert(nearestStationButton.waitForExistence(timeout: 5))
        nearestStationButton.tap()
        sleep(2)

        // Screenshot 2: All stations list grouped by zone
        snapshot("02-AllStations")

        // Open station detail for 22nd Street
        let stationInfoButton = app.buttons["station.info.22ND"]
        XCTAssert(stationInfoButton.waitForExistence(timeout: 2))
        stationInfoButton.tap()
        sleep(5)

        // Screenshot 3: Station detail with map, address, amenities
        snapshot("03-StationDetail")

        // Dismiss station detail sheet
        let stationInfoCloseButton = app.buttons["station.detail.close"]
        XCTAssert(stationInfoCloseButton.waitForExistence(timeout: 1))
        stationInfoCloseButton.tap()
        sleep(1)

        // Favorite SF and 22nd Street stations
        app.buttons["station.favorite.SF"].tap()
        app.buttons["station.favorite.22ND"].tap()
        sleep(1)

        // Navigate back to main screen
        app.navigationBars.buttons.element(boundBy: 0).tap()
        sleep(2)

        // Screenshot 4: Main screen with favorite station pills
        snapshot("04-MainScreenWithFavorites")
    }
}
