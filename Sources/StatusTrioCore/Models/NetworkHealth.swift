import Foundation

enum NetworkHealthState: Equatable, Sendable {
    case healthy
    case degraded
    case offline
    case unavailable
    case unknown
}

struct NetworkHealth: Equatable, Sendable {
    let state: NetworkHealthState
    let connection: NetworkConnection
    let latencyMilliseconds: Double?
    let packetLossPercent: Double?

    var requiresAttention: Bool {
        switch state {
        case .healthy, .unknown:
            false
        case .degraded, .offline, .unavailable:
            true
        }
    }

    static func derive(
        wifi: WiFiStatus,
        connection: NetworkConnection,
        latencyMilliseconds: Double? = nil,
        packetLossPercent: Double? = nil
    ) -> NetworkHealth {
        let state: NetworkHealthState

        if connection == .offline {
            state = .offline
        } else {
            switch wifi.state {
            case .connected, .hotspot, .temporary, .shared:
                state = .healthy
            case .noInternet, .notAssociated:
                state = .degraded
            case .off, .unavailable:
                state = .unavailable
            }
        }

        return NetworkHealth(
            state: state,
            connection: connection,
            latencyMilliseconds: latencyMilliseconds,
            packetLossPercent: packetLossPercent
        )
    }
}
