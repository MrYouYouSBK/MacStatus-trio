import XCTest
@testable import StatusTrioCore

final class NetworkQualityTests: XCTestCase {
    func testAggregateReportsAverageLatencyAndProbeFailure() {
        let sample = NetworkQualitySample.aggregate(
            latencies: [20, nil, 40, 60],
            measuredAt: Date(timeIntervalSince1970: 1)
        )

        XCTAssertEqual(sample.attempts, 4)
        XCTAssertEqual(sample.successfulAttempts, 3)
        XCTAssertEqual(sample.latencyMilliseconds, 40)
        XCTAssertEqual(sample.probeFailurePercent, 25)
    }

    func testAllFailedProbesHaveNoLatency() {
        let sample = NetworkQualitySample.aggregate(latencies: [nil, nil])

        XCTAssertNil(sample.latencyMilliseconds)
        XCTAssertEqual(sample.probeFailurePercent, 100)
    }

    func testHighProbeFailureDegradesOtherwiseHealthyNetwork() {
        let health = NetworkHealth.derive(
            wifi: WiFiStatus(state: .connected, rssi: -45),
            connection: .wifi,
            latencyMilliseconds: 40,
            probeFailurePercent: 50
        )

        XCTAssertEqual(health.state, .degraded)
        XCTAssertTrue(health.requiresAttention)
    }

    func testHighLatencyDegradesOtherwiseHealthyNetwork() {
        let health = NetworkHealth.derive(
            wifi: WiFiStatus(state: .connected, rssi: -45),
            connection: .wifi,
            latencyMilliseconds: 900,
            probeFailurePercent: 0
        )

        XCTAssertEqual(health.state, .degraded)
    }

    func testEthernetDoesNotBecomeUnavailableJustBecauseWifiIsOff() {
        let health = NetworkHealth.derive(
            wifi: WiFiStatus(state: .off, rssi: nil),
            connection: .ethernet
        )

        XCTAssertEqual(health.state, .healthy)
        XCTAssertFalse(health.requiresAttention)
    }
}
