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

        let networkHealth = NetworkHealth.derive(
            wifi: wifi,
            connection: connection
        )
        if bluetoothAudioOptions.prioritizesNetworkErrors,
           networkHealth.requiresAttention {
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

}
