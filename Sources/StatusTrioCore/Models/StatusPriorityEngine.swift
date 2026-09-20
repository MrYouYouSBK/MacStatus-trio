import Foundation

enum CenterStatusSignal: Equatable, Sendable {
    case network
    case bluetoothAudio
}

struct StatusPriorityDecision: Equatable, Sendable {
    let centerSignal: CenterStatusSignal
    let networkHasPriority: Bool

    static let network = StatusPriorityDecision(
        centerSignal: .network,
        networkHasPriority: true
    )
}

enum StatusPriorityEngine {
    static func decide(
        currentDevice: AudioOutputDevice?,
        wifi: WiFiStatus,
        connection: NetworkConnection,
        bluetoothAudioOptions: BluetoothAudioIconOptions
    ) -> StatusPriorityDecision {
        let isBluetoothOutput = currentDevice?.transport == .bluetooth
            || currentDevice?.transport == .bluetoothLowEnergy

        guard bluetoothAudioOptions.replacesNetworkIcon, isBluetoothOutput else {
            return .network
        }

        if bluetoothAudioOptions.prioritizesNetworkErrors,
           hasNetworkError(wifi: wifi, connection: connection) {
            return .network
        }

        return StatusPriorityDecision(
            centerSignal: .bluetoothAudio,
            networkHasPriority: false
        )
    }

    static func decide(
        status: MenuBarStatus,
        bluetoothAudioOptions: BluetoothAudioIconOptions
    ) -> StatusPriorityDecision {
        decide(
            currentDevice: status.volume.currentDevice,
            wifi: status.wifi,
            connection: status.connection,
            bluetoothAudioOptions: bluetoothAudioOptions
        )
    }

    private static func hasNetworkError(
        wifi: WiFiStatus,
        connection: NetworkConnection
    ) -> Bool {
        if connection == .offline { return true }

        switch wifi.state {
        case .notAssociated, .noInternet, .off, .unavailable:
            return true
        case .connected, .hotspot, .temporary, .shared:
            return false
        }
    }
}
