import Combine
import Charts
import Foundation
import SwiftUI

struct CrudeOilSnapshot: Codable, Equatable {
    let price: String
    let markerDateText: String
    let sourceURL: String
    let fetchedAt: Date
}

struct CrudeOilHistoryPoint: Codable, Equatable, Identifiable {
    let markerDate: Date
    let price: Double
    let markerDateText: String
    let fetchedAt: Date

    var id: TimeInterval { markerDate.timeIntervalSince1970 }
}

enum CrudeOilFetchReason {
    case startup
    case manual
    case scheduled
}

enum CrudeOilMonitorError: LocalizedError {
    case invalidResponse
    case unableToParse

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "無法取得 gulfmerc.com 的有效回應。"
        case .unableToParse:
            return "找不到 OQD Daily Marker Price。"
        }
    }
}

@MainActor
final class CrudeOilMonitor: ObservableObject {
    static let shared = CrudeOilMonitor()

    @Published private(set) var latestSnapshot: CrudeOilSnapshot?
    @Published private(set) var history: [CrudeOilHistoryPoint] = []
    @Published private(set) var isFetching = false
    @Published private(set) var nextFetchAt: Date?
    @Published private(set) var lastErrorMessage: String?

    private let sourceURL = URL(string: "https://www.gulfmerc.com/")!
    private let storageKey = "crudeOilSnapshot"
    private let historyStorageKey = "crudeOilSnapshotHistory"
    private var timer: Timer?
    private var hasStarted = false

    func start() {
        guard !hasStarted else { return }
        hasStarted = true

        loadPersistedSnapshot()
        loadPersistedHistory()
        scheduleNextFetch()

        Task {
            await fetchIfNeededOnLaunch()
        }
    }

    func fetchLatestPrice(reason: CrudeOilFetchReason = .manual) async {
        guard !isFetching else { return }
        isFetching = true
        defer {
            isFetching = false
            scheduleNextFetch()
        }

        do {
            let snapshot = try await requestSnapshot()
            latestSnapshot = snapshot
            appendHistoryIfNeeded(snapshot)
            lastErrorMessage = nil
            persist(snapshot)

            if reason == .scheduled {
                print("✅ Scheduled crude oil fetch succeeded: \(snapshot.price) on \(snapshot.markerDateText)")
            }
        } catch {
            lastErrorMessage = error.localizedDescription
            print("❌ Crude oil fetch failed: \(error.localizedDescription)")
        }
    }

    var latestPriceText: String {
        latestSnapshot?.price ?? "--"
    }

    var latestMarkerDateText: String {
        latestSnapshot?.markerDateText ?? "尚未取得"
    }

    var sourceLinkText: String {
        latestSnapshot?.sourceURL ?? sourceURL.absoluteString
    }

    var lastFetchedText: String {
        guard let fetchedAt = latestSnapshot?.fetchedAt else { return "尚未抓取" }
        return Self.timestampFormatter.string(from: fetchedAt)
    }

    var nextFetchText: String {
        guard let nextFetchAt else { return "未排程" }
        return Self.timestampFormatter.string(from: nextFetchAt)
    }

    var chartData: [CrudeOilHistoryPoint] {
        history.sorted { $0.markerDate < $1.markerDate }
    }

    var latestPriceDouble: Double? {
        latestSnapshot.flatMap { Double($0.price) }
    }

    private func fetchIfNeededOnLaunch(now: Date = Date()) async {
        if latestSnapshot == nil {
            await fetchLatestPrice(reason: .startup)
            return
        }

        let scheduledHour = 13
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = scheduledHour
        components.minute = 0
        components.second = 0

        guard let todayAtOne = calendar.date(from: components) else { return }
        guard let lastFetchedAt = latestSnapshot?.fetchedAt else { return }

        let fetchedSameDay = calendar.isDate(lastFetchedAt, inSameDayAs: now)
        if !fetchedSameDay && now >= todayAtOne {
            await fetchLatestPrice(reason: .startup)
        }
    }

    private func requestSnapshot() async throws -> CrudeOilSnapshot {
        var request = URLRequest(url: sourceURL)
        request.httpMethod = "GET"
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko)", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200 ... 299).contains(httpResponse.statusCode) else {
            throw CrudeOilMonitorError.invalidResponse
        }

        guard let html = String(data: data, encoding: .utf8) else {
            throw CrudeOilMonitorError.invalidResponse
        }

        let normalized = html
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&#8211;", with: "-")
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\r", with: " ")

        if let match = firstMatch(
            pattern: #"OQD\s+Marker\s+Price\s+([A-Za-z]+\s+\d{1,2},\s+\d{4})\s+is\s+([0-9]+(?:\.[0-9]+)?)"#,
            in: normalized
        ) {
            return CrudeOilSnapshot(
                price: match[2],
                markerDateText: match[1],
                sourceURL: sourceURL.absoluteString,
                fetchedAt: Date()
            )
        }

        let plainText = normalized
            .replacingOccurrences(of: #"<[^>]+>"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if let match = firstMatch(
            pattern: #"OQD\s+Daily\s+Marker\s+Price\s+([0-9]+(?:\.[0-9]+)?)\s+([0-9]{1,2}\s+[A-Za-z]{3}[,-]\s*[0-9]{4})"#,
            in: plainText
        ) {
            return CrudeOilSnapshot(
                price: match[1],
                markerDateText: match[2],
                sourceURL: sourceURL.absoluteString,
                fetchedAt: Date()
            )
        }

        throw CrudeOilMonitorError.unableToParse
    }

    private func appendHistoryIfNeeded(_ snapshot: CrudeOilSnapshot) {
        guard
            let markerDate = Self.primaryMarkerDateFormatter.date(from: snapshot.markerDateText)
            ?? Self.fallbackMarkerDateFormatter.date(from: snapshot.markerDateText),
            let price = Double(snapshot.price)
        else {
            return
        }

        let newPoint = CrudeOilHistoryPoint(
            markerDate: markerDate,
            price: price,
            markerDateText: snapshot.markerDateText,
            fetchedAt: snapshot.fetchedAt
        )

        if let existingIndex = history.firstIndex(where: { Calendar.current.isDate($0.markerDate, inSameDayAs: markerDate) }) {
            history[existingIndex] = newPoint
        } else {
            history.append(newPoint)
        }

        history.sort { $0.markerDate < $1.markerDate }
        persistHistory()
    }

    private func firstMatch(pattern: String, in text: String) -> [String]? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return nil
        }

        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: range) else {
            return nil
        }

        return (0 ..< match.numberOfRanges).compactMap { index in
            guard let range = Range(match.range(at: index), in: text) else { return nil }
            return String(text[range])
        }
    }

    private func scheduleNextFetch(now: Date = Date()) {
        timer?.invalidate()

        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = 13
        components.minute = 0
        components.second = 0

        guard let todayAtOne = calendar.date(from: components) else { return }

        let scheduledDate: Date
        if now < todayAtOne {
            scheduledDate = todayAtOne
        } else {
            scheduledDate = calendar.date(byAdding: .day, value: 1, to: todayAtOne) ?? todayAtOne.addingTimeInterval(24 * 60 * 60)
        }

        nextFetchAt = scheduledDate

        let interval = max(1, scheduledDate.timeIntervalSince(now))
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            Task { @MainActor in
                await self?.fetchLatestPrice(reason: .scheduled)
            }
        }
        timer?.tolerance = min(60, interval * 0.05)
    }

    private func loadPersistedSnapshot() {
        guard
            let data = UserDefaults.standard.data(forKey: storageKey),
            let snapshot = try? JSONDecoder().decode(CrudeOilSnapshot.self, from: data)
        else {
            return
        }

        latestSnapshot = snapshot
    }

    private func persist(_ snapshot: CrudeOilSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    private func loadPersistedHistory() {
        guard
            let data = UserDefaults.standard.data(forKey: historyStorageKey),
            let history = try? JSONDecoder().decode([CrudeOilHistoryPoint].self, from: data)
        else {
            return
        }

        self.history = history.sorted { $0.markerDate < $1.markerDate }
    }

    private func persistHistory() {
        guard let data = try? JSONEncoder().encode(history) else { return }
        UserDefaults.standard.set(data, forKey: historyStorageKey)
    }

    private static let timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    private static let primaryMarkerDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter
    }()

    private static let fallbackMarkerDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "d MMM, yyyy"
        return formatter
    }()
}

struct CrudeOilMonitorView: View {
    @EnvironmentObject private var crudeOilMonitor: CrudeOilMonitor

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.10, green: 0.07, blue: 0.03),
                    Color(red: 0.04, green: 0.03, blue: 0.02)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("原油監控")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)

                        Text("基於 gulfmerc.com 的 OQD Daily Marker Price，每天下午 1:00 自動抓取。")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.white.opacity(0.72))
                    }

                    HStack(alignment: .top, spacing: 18) {
                        monitorMetric(title: "最新價格", value: crudeOilMonitor.latestPriceText, accent: Color.orange)
                        monitorMetric(title: "Marker Date", value: crudeOilMonitor.latestMarkerDateText, accent: Color.yellow)
                    }

                    chartPanel

                    VStack(alignment: .leading, spacing: 10) {
                        detailRow(label: "上次抓取", value: crudeOilMonitor.lastFetchedText)
                        detailRow(label: "下次自動抓取", value: crudeOilMonitor.nextFetchText)
                        detailRow(label: "來源", value: crudeOilMonitor.sourceLinkText)

                        if let error = crudeOilMonitor.lastErrorMessage {
                            detailRow(label: "狀態", value: error)
                                .foregroundStyle(Color.red.opacity(0.88))
                        }
                    }

                    HStack(spacing: 12) {
                        Button {
                            Task {
                                await crudeOilMonitor.fetchLatestPrice(reason: .manual)
                            }
                        } label: {
                            Label(crudeOilMonitor.isFetching ? "抓取中..." : "立即抓取", systemImage: "arrow.trianglehead.clockwise")
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(crudeOilMonitor.isFetching)

                        Link("開啟來源網站", destination: URL(string: crudeOilMonitor.sourceLinkText)!)
                            .buttonStyle(.bordered)
                    }
                }
                .padding(28)
                .frame(maxWidth: 1100, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
        .frame(minWidth: 760, minHeight: 620)
    }

    @ViewBuilder
    private var chartPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("OQD 價格走勢")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Spacer()

                Text("歷史點數 \(crudeOilMonitor.chartData.count)")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.6))
            }

            if crudeOilMonitor.chartData.isEmpty {
                Text("目前還沒有歷史資料。從現在開始，每次成功抓取都會累積到圖表。")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.72))
                    .frame(maxWidth: .infinity, minHeight: 180, alignment: .center)
            } else {
                Chart(crudeOilMonitor.chartData) { point in
                    AreaMark(
                        x: .value("Date", point.markerDate),
                        y: .value("Price", point.price)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.orange.opacity(0.42), Color.orange.opacity(0.04)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    LineMark(
                        x: .value("Date", point.markerDate),
                        y: .value("Price", point.price)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(Color.orange)
                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))

                    PointMark(
                        x: .value("Date", point.markerDate),
                        y: .value("Price", point.price)
                    )
                    .foregroundStyle(Color.yellow)
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: min(6, max(2, crudeOilMonitor.chartData.count)))) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 1, dash: [3, 5]))
                            .foregroundStyle(Color.white.opacity(0.12))
                        AxisTick()
                            .foregroundStyle(Color.white.opacity(0.4))
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                            .foregroundStyle(Color.white.opacity(0.72))
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 1, dash: [4, 5]))
                            .foregroundStyle(Color.white.opacity(0.10))
                        AxisTick()
                            .foregroundStyle(Color.white.opacity(0.4))
                        AxisValueLabel()
                            .foregroundStyle(Color.white.opacity(0.72))
                    }
                }
                .chartYScale(domain: chartDomain)
                .frame(height: 220)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
        }
    }

    private var chartDomain: ClosedRange<Double> {
        let prices = crudeOilMonitor.chartData.map(\.price)
        let minPrice = prices.min() ?? 0
        let maxPrice = prices.max() ?? 1
        let padding = max(1, (maxPrice - minPrice) * 0.15)
        return (minPrice - padding)...(maxPrice + padding)
    }

    private func monitorMetric(title: String, value: String, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.66))
                .tracking(1.2)

            Text(value)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(accent.opacity(0.16), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
        }
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(label)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.58))
                .frame(width: 94, alignment: .leading)

            Text(value)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.9))
                .textSelection(.enabled)
        }
    }
}

struct OilMonitorMenuBarView: View {
    @EnvironmentObject private var navigationState: AppNavigationState
    @EnvironmentObject private var crudeOilMonitor: CrudeOilMonitor
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 6) {
                Text("原油監控")
                    .font(.headline)

                Text("OQD Daily Marker Price: \(crudeOilMonitor.latestPriceText)")
                    .font(.subheadline)

                Text("Marker Date: \(crudeOilMonitor.latestMarkerDateText)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("下次抓取: \(crudeOilMonitor.nextFetchText)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button("Open 原油監控") {
                navigationState.show(.oilMonitor)
            }

            Button("Open 原油監控視窗") {
                openWindow(id: "oil-monitor")
            }

            Button(crudeOilMonitor.isFetching ? "抓取中..." : "立即抓取 OQD 價格") {
                Task {
                    await crudeOilMonitor.fetchLatestPrice(reason: .manual)
                }
            }
            .disabled(crudeOilMonitor.isFetching)

            Link("Open gulfmerc.com", destination: URL(string: crudeOilMonitor.sourceLinkText)!)

            Divider()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(6)
        .frame(width: 300)
    }
}
