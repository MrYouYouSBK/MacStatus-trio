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
            packetLossPercent: 0
        )
        XCTAssertEqual(health.state, .healthy)
        XCTAssertFalse(health.requiresAttention)
        XCTAssertEqual(health.latencyMilliseconds, 18)
        XCTAssertEqual(health.packetLossPercent, 0)
    }

    func testUnavailableWifiKeepsNetworkPriorityForCompatibility() {
        let health = NetworkHealth.derive(
            wifi: WiFiStatus(state: .unavailable, rssi: nil),
            connection: .ethernet
        )
        XCTAssertEqual(health.state, .unavailable)
        XCTAssertTrue(health.requiresAttention)
    }
}
