import XCTest
@testable import StatusTrioCore

final class NetworkHealthTests: XCTestCase {
    func testOfflineConnectionRequiresAttention() {
        let health = NetworkHealth.derive(
            wifi: WiFiStatus(state: .connected, rssi: -45),
            connection: .offline
        )
        XCTAssertEqual(health.state, .offline)
        XCTAssertTrue(health.requiresAttention)
    }

    func testNoInternetIsDegraded() {
        let health = NetworkHealth.derive(
            wifi: WiFiStatus(state: .noInternet, rssi: -45),
            connection: .wifi
        )
        XCTAssertEqual(health.state, .degraded)
        XCTAssertTrue(health.requiresAttention)
    }

    func testHealthyWifiDoesNotRequireAttention() {
        let health = NetworkHealth.derive(
            wifi: WiFiStatus(state: .connected, rssi: -45),
            connection: .wifi,
            latencyMilliseconds: 18,
            probeFailurePercent: 0
        )
        XCTAssertEqual(health.state, .healthy)
        XCTAssertFalse(health.requiresAttention)
        XCTAssertEqual(health.latencyMilliseconds, 18)
        XCTAssertEqual(health.probeFailurePercent, 0)
    }

    func testEthernetIsHealthyWhenWifiIsUnavailable() {
        let health = NetworkHealth.derive(
            wifi: WiFiStatus(state: .unavailable, rssi: nil),
            connection: .ethernet
        )
        XCTAssertEqual(health.state, .healthy)
        XCTAssertFalse(health.requiresAttention)
    }
}
