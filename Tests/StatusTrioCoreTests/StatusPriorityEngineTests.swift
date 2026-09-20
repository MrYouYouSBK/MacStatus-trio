import XCTest
@testable import StatusTrioCore

final class StatusPriorityEngineTests: XCTestCase {
    func testNetworkWinsWhenBluetoothReplacementIsDisabled() {
        let decision = StatusPriorityEngine.decide(
            currentDevice: bluetoothDevice(),
            wifi: WiFiStatus(state: .connected, rssi: -45),
            connection: .wifi,
            bluetoothAudioOptions: BluetoothAudioIconOptions(replacesNetworkIcon: false)
        )

        XCTAssertEqual(decision.centerSignal, .network)
        XCTAssertTrue(decision.networkHasPriority)
    }

    func testBluetoothWinsOnHealthyNetworkWhenEnabled() {
        let decision = StatusPriorityEngine.decide(
            currentDevice: bluetoothDevice(),
            wifi: WiFiStatus(state: .connected, rssi: -45),
            connection: .wifi,
            bluetoothAudioOptions: BluetoothAudioIconOptions(
                replacesNetworkIcon: true,
                prioritizesNetworkErrors: true
            )
        )

        XCTAssertEqual(decision.centerSignal, .bluetoothAudio)
        XCTAssertFalse(decision.networkHasPriority)
    }

    func testNetworkErrorPreemptsBluetoothWhenConfigured() {
        for state in [WiFiState.notAssociated, .noInternet, .off, .unavailable] {
            let decision = StatusPriorityEngine.decide(
                currentDevice: bluetoothDevice(),
                wifi: WiFiStatus(state: state, rssi: nil),
                connection: .wifi,
                bluetoothAudioOptions: BluetoothAudioIconOptions(
                    replacesNetworkIcon: true,
                    prioritizesNetworkErrors: true
                )
            )
            XCTAssertEqual(decision.centerSignal, .network)
        }
    }

    func testOfflineConnectionPreemptsBluetooth() {
        let decision = StatusPriorityEngine.decide(
            currentDevice: bluetoothDevice(),
            wifi: WiFiStatus(state: .connected, rssi: -45),
            connection: .offline,
            bluetoothAudioOptions: BluetoothAudioIconOptions(
                replacesNetworkIcon: true,
                prioritizesNetworkErrors: true
            )
        )

        XCTAssertEqual(decision.centerSignal, .network)
    }

    private func bluetoothDevice() -> AudioOutputDevice {
        AudioOutputDevice(
            id: 1,
            name: "AirPods",
            transport: .bluetooth,
            isCurrent: true
        )
    }
}
