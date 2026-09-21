import Foundation

struct NetworkQualitySample: Equatable, Sendable {
    let latencyMilliseconds: Double?
    let probeFailurePercent: Double
    let attempts: Int
    let successfulAttempts: Int
    let measuredAt: Date

    static func aggregate(
        latencies: [Double?],
        measuredAt: Date = Date()
    ) -> NetworkQualitySample {
        let attempts = latencies.count
        let successes = latencies.compactMap { $0 }
        let latency = successes.isEmpty
            ? nil
            : successes.reduce(0, +) / Double(successes.count)
        let failurePercent = attempts == 0
            ? 0
            : Double(attempts - successes.count) / Double(attempts) * 100

        return NetworkQualitySample(
            latencyMilliseconds: latency,
            probeFailurePercent: failurePercent,
            attempts: attempts,
            successfulAttempts: successes.count,
            measuredAt: measuredAt
        )
    }
}

@MainActor
final class NetworkQualityMonitor: NetworkQualityMonitoring {
    let updates: AsyncStream<NetworkQualitySample>

    private enum Lifecycle {
        case idle
        case running
        case stopped
    }

    private let continuation: AsyncStream<NetworkQualitySample>.Continuation
    private let endpoint: URL
    private let attempts: Int
    private let minimumProbeInterval: TimeInterval
    private var lifecycle = Lifecycle.idle
    private var isDetailsVisible = false
    private var probeTask: Task<Void, Never>?
    private var lastProbeAt: Date?

    init(
        endpoint: URL = URL(string: "https://captive.apple.com/hotspot-detect.html")!,
        attempts: Int = 2,
        minimumProbeInterval: TimeInterval = 15
    ) {
        self.endpoint = endpoint
        self.attempts = max(1, attempts)
        self.minimumProbeInterval = max(5, minimumProbeInterval)
        (updates, continuation) = MonitorStream.make(of: NetworkQualitySample.self)
    }

    deinit {
        probeTask?.cancel()
        continuation.finish()
    }

    func start() {
        guard lifecycle == .idle else { return }
        lifecycle = .running
        if isDetailsVisible { refresh() }
    }

    func stop() {
        guard lifecycle != .stopped else { return }
        lifecycle = .stopped
        probeTask?.cancel()
        probeTask = nil
        continuation.finish()
    }

    func recover() {
        guard lifecycle == .running else { return }
        lastProbeAt = nil
        if isDetailsVisible { refresh() }
    }

    func setDetailsVisible(_ visible: Bool) {
        guard lifecycle != .stopped else { return }
        isDetailsVisible = visible
        if visible {
            refresh()
        } else {
            probeTask?.cancel()
            probeTask = nil
        }
    }

    func refresh() {
        guard lifecycle == .running, isDetailsVisible, probeTask == nil else { return }
        if let lastProbeAt,
           Date().timeIntervalSince(lastProbeAt) < minimumProbeInterval {
            return
        }

        lastProbeAt = Date()
        let endpoint = endpoint
        let attempts = attempts
        probeTask = Task { [weak self] in
            let sample = await Self.measure(endpoint: endpoint, attempts: attempts)
            guard !Task.isCancelled, let self else { return }
            self.probeTask = nil
            guard self.lifecycle == .running, self.isDetailsVisible else { return }
            self.continuation.yield(sample)
        }
    }

    private nonisolated static func measure(
        endpoint: URL,
        attempts: Int
    ) async -> NetworkQualitySample {
        var results: [Double?] = []
        results.reserveCapacity(attempts)

        for index in 0..<attempts {
            if Task.isCancelled { break }
            results.append(await probeOnce(endpoint: endpoint))
            if index + 1 < attempts {
                try? await Task.sleep(for: .milliseconds(120))
            }
        }

        return NetworkQualitySample.aggregate(latencies: results)
    }

    private nonisolated static func probeOnce(endpoint: URL) async -> Double? {
        var request = URLRequest(
            url: endpoint,
            cachePolicy: .reloadIgnoringLocalCacheData,
            timeoutInterval: 3
        )
        request.httpMethod = "GET"
        request.setValue("StatusTrio-NetworkQuality/1", forHTTPHeaderField: "User-Agent")

        let startedAt = Date()
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse,
                  (200..<400).contains(http.statusCode) else {
                return nil
            }
            return Date().timeIntervalSince(startedAt) * 1000
        } catch {
            return nil
        }
    }
}
