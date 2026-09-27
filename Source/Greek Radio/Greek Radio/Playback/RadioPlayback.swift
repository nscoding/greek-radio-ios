import AVFoundation
import Combine
import Foundation
import MediaPlayer
import Supabase
import SwiftUI

private enum SupabaseConfig {
    static let client = SupabaseClient(
        supabaseURL: URL(string: "https://hjnvsdxxxjyvynlfutvf.supabase.co")!,
        supabaseKey: "sb_publishable_mSpOYF6vbLkhyAtH-Hyr1w_lJ_oYs76",
        options: SupabaseClientOptions(
            auth: .init(emitLocalSessionAsInitialSession: true)
        )
    )
}

private enum StationCacheConfig {
    static let refreshInterval: TimeInterval = 5 * 60
    static let initialFailureBackoff: TimeInterval = 60
    static let maxFailureBackoff: TimeInterval = 60 * 60
}

private enum StationCacheKeys {
    static let lastSuccessfulRefresh = "stationCache.lastSuccessfulRefresh"
    static let lastRefreshAttempt = "stationCache.lastRefreshAttempt"
    static let consecutiveFailures = "stationCache.consecutiveFailures"
}

@MainActor
final class RadioStationStore: ObservableObject {
    static let shared = RadioStationStore()

    @Published private(set) var stations: [RadioStation] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let userDefaults = UserDefaults.standard
    private let cacheURL: URL

    private init() {
        cacheURL = Self.makeCacheURL()
        stations = Self.loadCachedStations(from: cacheURL)

        Task { [weak self] in
            await self?.loadStationsIfNeeded()
        }
    }

    func loadStationsIfNeeded() async {
        guard !isLoading else { return }
        guard shouldRefreshStations else { return }
        await loadStations()
    }

    func loadStations() async {
        isLoading = true
        errorMessage = nil
        userDefaults.set(Date(), forKey: StationCacheKeys.lastRefreshAttempt)

        do {
            let rows: [SupabaseStationRow] = try await SupabaseConfig.client.database
                .schema("radio")
                .from("station")
                .select("id,name,frequency,stream_url,region:region_id(name)")
                .execute()
                .value

            stations = rows
                .compactMap(\.radioStation)
                .sorted(using: KeyPathComparator(\.name, order: .forward))

            Self.saveCachedStations(stations, to: cacheURL)
            userDefaults.set(Date(), forKey: StationCacheKeys.lastSuccessfulRefresh)
            userDefaults.set(0, forKey: StationCacheKeys.consecutiveFailures)
        } catch {
            let message = error.localizedDescription
            if message.contains("PGRST106") || message.contains("Invalid schema: radio") {
                errorMessage = "The Supabase 'radio' schema is not exposed to the REST API. Expose the schema in Supabase API settings or move this table/view to 'public'."
            } else {
                errorMessage = message
            }

            if stations.isEmpty {
                stations = Self.loadCachedStations(from: cacheURL)
            }

            let failureCount = userDefaults.integer(forKey: StationCacheKeys.consecutiveFailures) + 1
            userDefaults.set(failureCount, forKey: StationCacheKeys.consecutiveFailures)
        }

        isLoading = false
    }

    private var shouldRefreshStations: Bool {
        if stations.isEmpty {
            return true
        }

        let now = Date()
        let failureCount = userDefaults.integer(forKey: StationCacheKeys.consecutiveFailures)

        if failureCount > 0 {
            let attemptDate = userDefaults.object(forKey: StationCacheKeys.lastRefreshAttempt) as? Date ?? .distantPast
            let exponent = min(failureCount - 1, 6)
            let interval = min(
                StationCacheConfig.initialFailureBackoff * pow(2, Double(exponent)),
                StationCacheConfig.maxFailureBackoff
            )
            return now.timeIntervalSince(attemptDate) >= interval
        }

        let successDate = userDefaults.object(forKey: StationCacheKeys.lastSuccessfulRefresh) as? Date ?? .distantPast
        return now.timeIntervalSince(successDate) >= StationCacheConfig.refreshInterval
    }

    private static func makeCacheURL() -> URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let directoryURL = baseURL.appendingPathComponent("StationCache", isDirectory: true)

        if !FileManager.default.fileExists(atPath: directoryURL.path) {
            try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        }

        return directoryURL.appendingPathComponent("stations.json")
    }

    private static func loadCachedStations(from url: URL) -> [RadioStation] {
        guard let data = try? Data(contentsOf: url),
              let cachedStations = try? JSONDecoder().decode([CachedRadioStation].self, from: data) else {
            return []
        }

        return cachedStations
            .compactMap(\.radioStation)
            .sorted(using: KeyPathComparator(\.name, order: .forward))
    }

    private static func saveCachedStations(_ stations: [RadioStation], to url: URL) {
        let cachedStations = stations.map(CachedRadioStation.init)

        guard let data = try? JSONEncoder().encode(cachedStations) else { return }
        try? data.write(to: url, options: .atomic)
    }
}

final class RadioPlayer: NSObject, ObservableObject {
    static let shared = RadioPlayer()

    @Published private(set) var currentStation: RadioStation?
    @Published private(set) var isPlaying = false
    @Published private(set) var isBuffering = false
    @Published private(set) var currentKilobytesPerSecond: Double = 0
    @Published private(set) var throughputSamples: [Double] = Array(repeating: 0, count: 20)

    private let player = AVPlayer()
    private var playerStatusObservation: NSKeyValueObservation?
    private var itemStatusObservation: NSKeyValueObservation?
    private var bufferEmptyObservation: NSKeyValueObservation?
    private var likelyToKeepUpObservation: NSKeyValueObservation?
    private var wasPlayingBeforeInterruption = false
    private var userWantsPlayback = false
    private var interruptionResumeWorkItem: DispatchWorkItem?
    private var accessLogTimer: Timer?
    private var transferStartDate: Date?
    private var lastObservedBitrate: Double = 128_000
    private var lastTransferredBytes: Int64 = 0
    private let stationStore = RadioStationStore.shared

    private override init() {
        super.init()
        configureAudioSession()
        configureRemoteCommands()
        observePlayerState()
        observeAudioSessionInterruptions()
        observeAudioSessionRouteChanges()
        observeMediaServicesReset()
    }

    func play(station: RadioStation) {
        interruptionResumeWorkItem?.cancel()
        interruptionResumeWorkItem = nil
        userWantsPlayback = true
        wasPlayingBeforeInterruption = false
        currentStation = station
        isPlaying = true
        isBuffering = true
        currentKilobytesPerSecond = 0
        throughputSamples = Array(repeating: 0, count: 20)
        transferStartDate = Date()
        lastObservedBitrate = 128_000
        lastTransferredBytes = 0
        activateSession()

        let item = AVPlayerItem(url: station.streamURL)
        item.preferredForwardBufferDuration = 8
        itemStatusObservation = item.observe(\.status, options: [.initial, .new]) { [weak self] item, _ in
            guard let self else { return }
            if item.status == .readyToPlay {
                self.player.play()
                DispatchQueue.main.async {
                    self.isBuffering = !item.isPlaybackLikelyToKeepUp
                }
                self.updateNowPlaying()
            } else if item.status == .failed {
                DispatchQueue.main.async {
                    self.isPlaying = false
                    self.isBuffering = false
                    self.updateNowPlaying()
                }
            }
        }
        bufferEmptyObservation = item.observe(\.isPlaybackBufferEmpty, options: [.initial, .new]) { [weak self] item, _ in
            DispatchQueue.main.async {
                self?.isBuffering = item.isPlaybackBufferEmpty || !(self?.player.timeControlStatus == .playing && item.isPlaybackLikelyToKeepUp)
            }
        }
        likelyToKeepUpObservation = item.observe(\.isPlaybackLikelyToKeepUp, options: [.initial, .new]) { [weak self] item, _ in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isBuffering = !item.isPlaybackLikelyToKeepUp && self.isPlaying
            }
        }

        player.replaceCurrentItem(with: item)
        player.play()
        startAccessLogPolling(for: item)
        updateNowPlaying()
    }

    func togglePlayback() {
        interruptionResumeWorkItem?.cancel()
        interruptionResumeWorkItem = nil

        if isPlaying {
            userWantsPlayback = false
            wasPlayingBeforeInterruption = false
            player.pause()
            isPlaying = false
            isBuffering = false
            currentKilobytesPerSecond = 0
        } else {
            userWantsPlayback = true
            wasPlayingBeforeInterruption = false
            activateSession()
            if let currentStation, player.currentItem == nil || player.currentItem?.status == .failed {
                play(station: currentStation)
            } else {
                player.play()
                isPlaying = true
                isBuffering = player.currentItem?.isPlaybackLikelyToKeepUp == false
            }
        }
        updateNowPlaying()
    }

    func skipForward() {
        guard let currentStation,
              let index = stations.firstIndex(where: { $0.id == currentStation.id }) else { return }

        let nextIndex = stations.index(after: index)
        let station = stations[nextIndex == stations.endIndex ? stations.startIndex : nextIndex]
        play(station: station)
    }

    func skipBackward() {
        guard let currentStation,
              let index = stations.firstIndex(where: { $0.id == currentStation.id }) else { return }

        let previousIndex = index == stations.startIndex ? stations.index(before: stations.endIndex) : stations.index(before: index)
        play(station: stations[previousIndex])
    }

    func isCurrentStation(_ station: RadioStation) -> Bool {
        currentStation?.id == station.id
    }

    private var stations: [RadioStation] {
        stationStore.stations
    }

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, policy: .longFormAudio)
        } catch {
            print("Audio session category error: \(error.localizedDescription)")
        }
    }

    private func activateSession() {
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio session activation error: \(error.localizedDescription)")
        }
    }

    private func observeAudioSessionInterruptions() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioSessionInterruption),
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance()
        )
    }

    private func observeAudioSessionRouteChanges() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioSessionRouteChange),
            name: AVAudioSession.routeChangeNotification,
            object: AVAudioSession.sharedInstance()
        )
    }

    private func observeMediaServicesReset() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMediaServicesReset),
            name: AVAudioSession.mediaServicesWereResetNotification,
            object: nil
        )
    }

    @objc func handleAudioSessionInterruption(_ notification: Notification) {
        guard
            let info = notification.userInfo,
            let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: typeValue)
        else { return }

        if type == .began {
            interruptionResumeWorkItem?.cancel()
            interruptionResumeWorkItem = nil

            // Check if playback was active or intended before the interruption began.
            // (iOS might halt the player before this notification arrives, so check userWantsPlayback too)
            wasPlayingBeforeInterruption = isPlaying || userWantsPlayback

            if wasPlayingBeforeInterruption {
                player.pause()
                DispatchQueue.main.async { [weak self] in
                    self?.isBuffering = false
                    self?.updateNowPlaying()
                }
            }
        } else if type == .ended {
            let optionsValue = info[AVAudioSessionInterruptionOptionKey] as? UInt
            let shouldResumeOption = optionsValue.map { AVAudioSession.InterruptionOptions(rawValue: $0).contains(.shouldResume) }

            // In CarPlay and phone calls, CallKit often omits .shouldResume or provides 0 even when the user
            // was actively listening to radio. If the user was playing before the call, resume unless explicitly prohibited.
            let shouldResume = shouldResumeOption ?? true

            guard shouldResume, wasPlayingBeforeInterruption, let currentStation else { return }

            interruptionResumeWorkItem?.cancel()

            // Delay slightly (0.3s) to allow CarPlay and in-car Bluetooth hardware to finish
            // switching audio routing from the call profile (HFP/telephony) back to media playback (CarPlay/A2DP).
            let workItem = DispatchWorkItem { [weak self] in
                guard let self, self.wasPlayingBeforeInterruption, let station = self.currentStation else { return }

                // Do not resume if another audio app (e.g. Spotify) took over audio during the interruption
                guard !AVAudioSession.sharedInstance().isOtherAudioPlaying else {
                    self.wasPlayingBeforeInterruption = false
                    self.userWantsPlayback = false
                    self.isPlaying = false
                    self.updateNowPlaying()
                    return
                }

                self.wasPlayingBeforeInterruption = false
                self.resumeOrRestartPlayback(for: station)
            }

            interruptionResumeWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: workItem)
        }
    }

    private func resumeOrRestartPlayback(for station: RadioStation, retryCount: Int = 0) {
        do {
            try AVAudioSession.sharedInstance().setActive(true)
            // For live streams, re-connecting to the station ensures a fresh TCP socket and live buffer
            // rather than stalling on a dead socket from a multi-minute call.
            play(station: station)
        } catch {
            if retryCount < 3 {
                let delay = 0.35 * Double(retryCount + 1)
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                    self?.resumeOrRestartPlayback(for: station, retryCount: retryCount + 1)
                }
            } else {
                print("Audio session reactivation failed after interruption: \(error.localizedDescription)")
                isPlaying = false
                isBuffering = false
                userWantsPlayback = false
                updateNowPlaying()
            }
        }
    }

    @objc private func handleAudioSessionRouteChange(_ notification: Notification) {
        guard
            let info = notification.userInfo,
            let reasonValue = info[AVAudioSessionRouteChangeReasonKey] as? UInt,
            let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue)
        else { return }

        switch reason {
        case .oldDeviceUnavailable:
            // CarPlay disconnected, car turned off, or headphones unplugged: pause immediately
            DispatchQueue.main.async { [weak self] in
                guard let self, self.isPlaying else { return }
                self.interruptionResumeWorkItem?.cancel()
                self.interruptionResumeWorkItem = nil
                self.userWantsPlayback = false
                self.wasPlayingBeforeInterruption = false
                self.player.pause()
                self.isPlaying = false
                self.isBuffering = false
                self.updateNowPlaying()
            }
        default:
            break
        }
    }

    @objc private func handleMediaServicesReset() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.configureAudioSession()
            if self.userWantsPlayback, let station = self.currentStation {
                self.play(station: station)
            }
        }
    }

    private func observePlayerState() {
        playerStatusObservation = player.observe(\.timeControlStatus, options: [.initial, .new]) { [weak self] player, _ in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isPlaying = player.timeControlStatus != .paused
                let waitingForData = player.timeControlStatus == .waitingToPlayAtSpecifiedRate
                let likelyToKeepUp = player.currentItem?.isPlaybackLikelyToKeepUp ?? true
                self.isBuffering = waitingForData || (self.isPlaying && !likelyToKeepUp)
                self.updateNowPlaying()
            }
        }
    }

    private func startAccessLogPolling(for item: AVPlayerItem) {
        accessLogTimer?.invalidate()
        accessLogTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self, weak item] timer in
            guard let self, let item else { return }
            let transferredBytes = self.transferredBytes(from: item.accessLog()?.events.last)
            let deltaBytes = max(0, transferredBytes - self.lastTransferredBytes)
            self.lastTransferredBytes = transferredBytes
            let kilobytesPerSecond = (Double(deltaBytes) / 1024) / timer.timeInterval
            DispatchQueue.main.async {
                self.currentKilobytesPerSecond = kilobytesPerSecond
                self.throughputSamples.append(kilobytesPerSecond)
                if self.throughputSamples.count > 20 {
                    self.throughputSamples.removeFirst(self.throughputSamples.count - 20)
                }
            }
        }
    }

    private func transferredBytes(from event: AVPlayerItemAccessLogEvent?) -> Int64 {
        if let event {
            if event.numberOfBytesTransferred > 0 {
                return event.numberOfBytesTransferred
            }

            let bitrate = [event.observedBitrate, event.indicatedAverageBitrate, event.indicatedBitrate]
                .first(where: { $0 > 0 }) ?? 0
            let transferDuration = max(0, event.transferDuration)

            if bitrate > 0 {
                lastObservedBitrate = bitrate
            }

            if bitrate > 0, transferDuration > 0 {
                return Int64((bitrate * transferDuration) / 8)
            }
        }

        guard let transferStartDate else { return 0 }
        let elapsed = Date().timeIntervalSince(transferStartDate)
        guard elapsed > 0 else { return 0 }
        return Int64((lastObservedBitrate * elapsed) / 8)
    }

    private func configureRemoteCommands() {
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.playCommand.isEnabled = true
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.nextTrackCommand.isEnabled = true
        commandCenter.previousTrackCommand.isEnabled = true

        commandCenter.playCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            self.interruptionResumeWorkItem?.cancel()
            self.interruptionResumeWorkItem = nil
            self.userWantsPlayback = true
            self.wasPlayingBeforeInterruption = false
            self.activateSession()
            if let currentStation = self.currentStation, self.player.currentItem == nil || self.player.currentItem?.status == .failed {
                self.play(station: currentStation)
            } else {
                self.player.play()
            }
            self.updateNowPlaying()
            return .success
        }

        commandCenter.pauseCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            self.interruptionResumeWorkItem?.cancel()
            self.interruptionResumeWorkItem = nil
            self.userWantsPlayback = false
            self.wasPlayingBeforeInterruption = false
            self.player.pause()
            self.updateNowPlaying()
            return .success
        }

        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            self?.skipForward()
            return .success
        }

        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            self?.skipBackward()
            return .success
        }
    }

    private func updateNowPlaying() {
        guard let currentStation else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            MPNowPlayingInfoCenter.default().playbackState = .stopped
            return
        }

        var nowPlayingInfo: [String: Any] = [
            MPMediaItemPropertyTitle: currentStation.name,
            MPMediaItemPropertyArtist: "\(currentStation.frequency) • \(currentStation.region)",
            MPNowPlayingInfoPropertyIsLiveStream: true,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0
        ]

        if let artwork = currentStation.nowPlayingArtwork {
            nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
        }

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        MPNowPlayingInfoCenter.default().playbackState = isPlaying ? .playing : .paused
    }
}

struct RadioStation: Identifiable, Hashable {
    let id: Int64
    let name: String
    let shortName: String
    let frequency: String
    let region: String
    let description: String
    let symbol: String
    let streamURL: URL
    let palette: [Color]
    let categories: [StationCategory]
    let searchCorpus: [String]

    init(
        id: Int64,
        name: String,
        shortName: String,
        frequency: String,
        region: String,
        description: String,
        symbol: String,
        streamURL: URL,
        palette: [Color],
        categories: [StationCategory],
        searchCorpus: [String]? = nil
    ) {
        self.id = id
        self.name = name
        self.shortName = shortName
        self.frequency = frequency
        self.region = region
        self.description = description
        self.symbol = symbol
        self.streamURL = streamURL
        self.palette = palette
        self.categories = categories

        if let searchCorpus {
            self.searchCorpus = searchCorpus
        } else {
            let searchable = [name, frequency, region, description, categories.map(\.title).joined(separator: " ")].joined(separator: " ")
            self.searchCorpus = GreekSearchMatcher.searchCorpus(for: searchable)
        }
    }

    var searchableText: String {
        [name, frequency, region, description, categories.map(\.title).joined(separator: " ")].joined(separator: " ")
    }

    func matchesSearch(_ query: String) -> Bool {
        GreekSearchMatcher.matches(query: query, inCorpus: searchCorpus)
    }

    var genreLabel: String {
        categories.first(where: { $0 != .all })?.title ?? appLocalized("Live Radio")
    }

    var artworkBadgeTitle: String {
        let trimmedFrequency = frequency.trimmingCharacters(in: .whitespacesAndNewlines)

        if let numericFrequency = trimmedFrequency.numericFrequencyComponent {
            return numericFrequency
        }

        return "WEB"
    }

    var artworkBadgeSubtitle: String {
        let trimmedFrequency = frequency.trimmingCharacters(in: .whitespacesAndNewlines)
        let uppercasedFrequency = trimmedFrequency.uppercased()

        if trimmedFrequency.numericFrequencyComponent != nil {
            if uppercasedFrequency.contains("AM") {
                return "AM"
            }

            return "FM"
        }

        if uppercasedFrequency.contains("WEB") {
            return appLocalized("STREAM")
        }

        return appLocalized("LIVE")
    }

    var nowPlayingArtwork: MPMediaItemArtwork? {
        let size = CGSize(width: 512, height: 512)
        let image = renderNowPlayingImage(size: size)

        return MPMediaItemArtwork(boundsSize: size) { _ in
            image
        }
    }

    private func renderNowPlayingImage(size: CGSize) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.opaque = true

        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            let cgContext = context.cgContext
            let rect = CGRect(origin: .zero, size: size)
            let colors = palette.map { UIColor($0).cgColor }
            let gradientColors = colors.isEmpty ? [UIColor.systemBlue.cgColor, UIColor.systemTeal.cgColor] : colors
            let colorSpace = CGColorSpaceCreateDeviceRGB()

            if let gradient = CGGradient(colorsSpace: colorSpace, colors: gradientColors as CFArray, locations: nil) {
                cgContext.drawLinearGradient(
                    gradient,
                    start: CGPoint(x: rect.minX, y: rect.minY),
                    end: CGPoint(x: rect.maxX, y: rect.maxY),
                    options: []
                )
            } else {
                UIColor.systemBlue.setFill()
                cgContext.fill(rect)
            }

            UIColor.white.withAlphaComponent(0.16).setFill()
            cgContext.fillEllipse(in: CGRect(x: size.width * 0.58, y: -size.height * 0.12, width: size.width * 0.5, height: size.height * 0.5))
            UIColor.black.withAlphaComponent(0.16).setFill()
            cgContext.fillEllipse(in: CGRect(x: -size.width * 0.18, y: size.height * 0.62, width: size.width * 0.48, height: size.height * 0.48))

            let badgeRect = rect.insetBy(dx: 56, dy: 56)
            let badgePath = UIBezierPath(roundedRect: badgeRect, cornerRadius: 84)
            UIColor.white.withAlphaComponent(0.18).setFill()
            badgePath.fill()
            UIColor.white.withAlphaComponent(0.28).setStroke()
            badgePath.lineWidth = 2
            badgePath.stroke()

            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 112, weight: .black),
                .foregroundColor: UIColor.white
            ]
            let subtitleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 46, weight: .heavy),
                .foregroundColor: UIColor.white.withAlphaComponent(0.82)
            ]
            let title = artworkBadgeTitle as NSString
            let subtitle = artworkBadgeSubtitle as NSString
            let titleSize = title.size(withAttributes: titleAttributes)
            let subtitleSize = subtitle.size(withAttributes: subtitleAttributes)
            let totalHeight = titleSize.height + 12 + subtitleSize.height
            let titleRect = CGRect(
                x: (size.width - titleSize.width) / 2,
                y: (size.height - totalHeight) / 2,
                width: titleSize.width,
                height: titleSize.height
            )
            let subtitleRect = CGRect(
                x: (size.width - subtitleSize.width) / 2,
                y: titleRect.maxY + 12,
                width: subtitleSize.width,
                height: subtitleSize.height
            )

            title.draw(in: titleRect, withAttributes: titleAttributes)
            subtitle.draw(in: subtitleRect, withAttributes: subtitleAttributes)
        }
    }
}

enum StationCategory: String, CaseIterable, Identifiable {
    case all
    case music
    case news
    case folk
    case jazz
    case athens
    case thessaloniki
    case crete

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return appLocalized("All")
        case .music: return appLocalized("Music")
        case .news: return appLocalized("News")
        case .folk: return appLocalized("Folk")
        case .jazz: return appLocalized("Jazz")
        case .athens: return appLocalized("Athens")
        case .thessaloniki: return appLocalized("Thess")
        case .crete: return appLocalized("Crete")
        }
    }

    var carPlayTitle: String {
        switch self {
        case .thessaloniki:
            return appLocalized("Thessaloniki")
        default:
            return title
        }
    }
}

private struct SupabaseStationRow: Decodable {
    let id: Int64?
    let name: String
    let shortName: String?
    let frequency: String?
    let region: SupabaseRegion?
    let streamURLString: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case shortName = "short_name"
        case frequency
        case region
        case streamURL = "stream_url"
        case streamURLAlt = "streamURL"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(Int64.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        shortName = try container.decodeIfPresent(String.self, forKey: .shortName)
        frequency = try container.decodeIfPresent(String.self, forKey: .frequency)
        region = try container.decodeIfPresent(SupabaseRegion.self, forKey: .region)
        streamURLString = try container.decodeIfPresent(String.self, forKey: .streamURL)
            ?? container.decodeIfPresent(String.self, forKey: .streamURLAlt)
    }

    var radioStation: RadioStation? {
        guard let streamURLString,
              let streamURL = URL(string: streamURLString) else {
            return nil
        }

        let stationCategories: [StationCategory] = [.all]
        return RadioStation(
            id: id ?? 0,
            name: name,
            shortName: shortName?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty ?? compactShortName(from: name),
            frequency: frequency?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty ?? appLocalized("Live"),
            region: region?.name?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty ?? appLocalized("Greece"),
            description: appLocalized("Live Greek radio streaming."),
            symbol: fallbackSymbol(for: stationCategories),
            streamURL: streamURL,
            palette: fallbackPalette,
            categories: stationCategories
        )
    }

    private var fallbackPalette: [Color] {
        [Color(red: 0.08, green: 0.25, blue: 0.37), Color(red: 0.77, green: 0.33, blue: 0.18)]
    }

    private func compactShortName(from name: String) -> String {
        let pieces = name
            .split(whereSeparator: { $0 == " " || $0 == "-" || $0 == "/" })
            .prefix(2)
            .map { String($0.prefix(4)).uppercased() }

        return pieces.joined()
    }

    private func fallbackSymbol(for categories: [StationCategory]) -> String {
        switch categories.first(where: { $0 != .all }) {
        case .news: return "newspaper.fill"
        case .folk: return "guitars.fill"
        case .jazz: return "music.quarternote.3"
        case .crete: return "sun.max.fill"
        case .athens, .thessaloniki: return "building.2.crop.circle"
        case .music, .all, .none: return "dot.radiowaves.left.and.right"
        }
    }
}

private struct SupabaseRegion: Decodable {
    let name: String?
}

private struct CachedRadioStation: Codable {
    let id: Int64
    let name: String
    let shortName: String
    let frequency: String
    let region: String
    let description: String
    let symbol: String
    let streamURLString: String

    init(station: RadioStation) {
        id = station.id
        name = station.name
        shortName = station.shortName
        frequency = station.frequency
        region = station.region
        description = station.description
        symbol = station.symbol
        streamURLString = station.streamURL.absoluteString
    }

    var radioStation: RadioStation? {
        guard let streamURL = URL(string: streamURLString) else {
            return nil
        }

        return RadioStation(
            id: id,
            name: name,
            shortName: shortName,
            frequency: frequency,
            region: region,
            description: description,
            symbol: symbol,
            streamURL: streamURL,
            palette: [Color(red: 0.08, green: 0.25, blue: 0.37), Color(red: 0.77, green: 0.33, blue: 0.18)],
            categories: [.all]
        )
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }

    var numericFrequencyComponent: String? {
        let filtered = unicodeScalars.filter { CharacterSet(charactersIn: "0123456789.").contains($0) }
        let value = String(String.UnicodeScalarView(filtered))
        return value.isEmpty ? nil : value
    }
}
