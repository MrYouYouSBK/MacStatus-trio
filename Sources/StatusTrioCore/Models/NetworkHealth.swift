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
    let probeFailurePercent: Double?

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
        probeFailurePercent: Double? = nil
    ) -> NetworkHealth {
        var state: NetworkHealthState

        if connection == .offline {
            state = .offline
        } else if connection == .ethernet || connection == .other {
            state = .healthy
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

        if state == .healthy {
            if let failure = probeFailurePercent, failure >= 50 {
                state = .degraded
            } else if let latency = latencyMilliseconds, latency >= 750 {
                state = .degraded
            }
        }

        return NetworkHealth(
            state: state,
            connection: connection,
            latencyMilliseconds: latencyMilliseconds,
            probeFailurePercent: probeFailurePercent
        )
    }
}
