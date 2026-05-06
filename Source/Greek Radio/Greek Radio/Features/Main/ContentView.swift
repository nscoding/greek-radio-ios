import SwiftUI
import SwiftData
import StoreKit
import UIKit

private enum ReviewPromptStorage {
    static let hasCompleted = "reviewPrompt.hasCompleted"
    static let declineCount = "reviewPrompt.declineCount"
    static let nextEligibleDate = "reviewPrompt.nextEligibleDate"
}

struct ContentView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL
    @Environment(\.requestReview) private var requestReview
    @Query(sort: \FavoriteStation.createdAt) private var storedFavorites: [FavoriteStation]
    @AppStorage("accentThemeID") private var accentThemeID = AccentTheme.aegean.rawValue
    @AppStorage(AppLanguage.userDefaultsKey) private var selectedAppLanguageCode = AppLanguage.english.rawValue
    @AppStorage(ReviewPromptStorage.hasCompleted) private var hasCompletedReviewPrompt = false
    @AppStorage(ReviewPromptStorage.declineCount) private var reviewPromptDeclineCount = 0
    @AppStorage(ReviewPromptStorage.nextEligibleDate) private var reviewPromptNextEligibleDate = 0.0
    @StateObject private var player = RadioPlayer.shared
    @StateObject private var stationStore = RadioStationStore.shared
    @State private var selectedSection: AppSection = .stations
    @State private var selectedRegion = "All"
    @State private var searchText = ""
    @State private var selectedStation: RadioStation?
    @State private var isPlayerPresented = false
    @State private var featuredStationID: Int64?
    @State private var isReviewPromptPresented = false

    private var favoriteIDs: Set<Int64> {
        Set(storedFavorites.map(\.stationID))
    }

    private var accentTheme: AccentTheme {
        AccentTheme(rawValue: accentThemeID) ?? .sunset
    }

    private var selectedAppLanguage: AppLanguage {
        AppLanguage(rawValue: selectedAppLanguageCode) ?? .english
    }

    private func localized(_ key: String) -> String {
        selectedAppLanguage.localizedString(key)
    }

    private var pageGradientColors: [Color] {
        if colorScheme == .dark {
            return [
                Color(uiColor: .systemGray6),
                Color(uiColor: .black)
            ]
        }

        return [
            Color(red: 0.98, green: 0.96, blue: 0.94),
            Color(uiColor: .systemBackground)
        ]
    }

    private var searchFieldBackground: Color {
        Color(uiColor: colorScheme == .dark ? .secondarySystemBackground : .systemGray6)
    }

    private var cardBackground: Color {
        Color(uiColor: .secondarySystemBackground)
    }

    private var chipBackground: Color {
        Color(uiColor: colorScheme == .dark ? .tertiarySystemBackground : .systemGray6)
    }

    private var cardShadowColor: Color {
        colorScheme == .dark ? .black.opacity(0.22) : .black.opacity(0.05)
    }

    private var controlFill: Color {
        Color.primary.opacity(colorScheme == .dark ? 0.18 : 0.08)
    }

    private var supportEmailURL: URL? {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = "chamelo.patrik+greek-radio@gmail.com"
        components.queryItems = [
            URLQueryItem(name: "subject", value: localized("Greek Radio Support"))
        ]
        return components.url
    }

    private var filteredStations: [RadioStation] {
        stationStore.stations.filter { station in
            let matchesRegion = selectedRegion == "All" || station.region == selectedRegion
            let matchesSearch = searchText.isEmpty || station.searchableText.localizedCaseInsensitiveContains(searchText)

            switch selectedSection {
            case .home, .stations:
                return matchesRegion && matchesSearch
            case .favorites:
                return matchesRegion && matchesSearch && favoriteIDs.contains(station.id)
            case .settings:
                return false
            }
        }
    }

    private var availableRegions: [String] {
        let uniqueRegions = Set(
            stationStore.stations
                .map(\.region)
                .filter { !$0.isEmpty }
        )

        return ["All"] + uniqueRegions.sorted()
    }

    private func displayRegionName(_ region: String) -> String {
        region == "All" ? localized("All") : region
    }

    private var featuredStation: RadioStation? {
        let stations = stationStore.stations

        if let featuredStationID,
           let station = stations.first(where: { $0.id == featuredStationID }) {
            return station
        }

        return stations.randomElement()
    }

    private var popularStations: [RadioStation] {
        filteredStations
            .sorted { lhs, rhs in
                dailyPopularityKey(for: lhs) < dailyPopularityKey(for: rhs)
            }
            .prefix(5)
            .map(\.self)
    }

    var body: some View {
        TabView(selection: $selectedSection) {
            ForEach(AppSection.allCases) { section in
                NavigationStack {
                    rootContent(for: section)
                }
                .toolbar(.hidden, for: .navigationBar)
                .tabItem {
                    Label(section.tabTitle, systemImage: section.symbol)
                }
                .tag(section)
            }
        }
        .tint(accentTheme.primary)
        .safeAreaInset(edge: .bottom) {
            if let currentStation = player.currentStation {
                miniPlayer(for: currentStation)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 68)
            }
        }
        .sheet(isPresented: $isPlayerPresented) {
            if let station = selectedStation ?? player.currentStation {
                PlayerSheet(
                    station: station,
                    player: player,
                    accentTheme: accentTheme,
                    isFavorite: favoriteIDs.contains(station.id),
                    favoriteAction: { toggleFavorite(station) }
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
        }
        .task {
            await stationStore.loadStationsIfNeeded()
            refreshFeaturedStation()
        }
        .onChange(of: stationStore.stations.map(\.id)) { _, _ in
            refreshFeaturedStation()
        }
        .alert(appLocalized("Enjoying Greek Radio?"), isPresented: $isReviewPromptPresented) {
            Button(appLocalized("Not Now")) {
                recordReviewPromptDecline()
            }

            Button(appLocalized("Review Now")) {
                completeReviewPromptFlow()
            }
        } message: {
            Text(appLocalized("Would you like to leave a quick App Store review?"))
        }
    }

    private func refreshFeaturedStation() {
        let stations = stationStore.stations

        guard !stations.isEmpty else {
            featuredStationID = nil
            return
        }

        if let featuredStationID,
           stations.contains(where: { $0.id == featuredStationID }) {
            return
        }

        featuredStationID = stations.randomElement()?.id
    }

    private func dailyPopularityKey(for station: RadioStation) -> UInt64 {
        let dayKey = Calendar.current.startOfDay(for: .now).formatted(.iso8601.year().month().day())
        let seed = "\(station.id)-\(dayKey)"
        var hash: UInt64 = 14_695_981_039_346_656_037

        for byte in seed.utf8 {
            hash ^= UInt64(byte)
            hash &*= 1_099_511_628_211
        }

        return hash
    }

    @ViewBuilder
    private func rootContent(for section: AppSection) -> some View {
        ZStack {
            LinearGradient(
                colors: pageGradientColors,
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    header

                    if section != .settings {
                        searchBar
                        categoryStrip
                    }

                    switch section {
                    case .home:
                        if featuredStation != nil {
                            featuredCard
                        }
                        stationSection(title: localized("Popular Right Now"), stations: popularStations)
                    case .stations:
                        stationSection(title: localized("Top Stations"), stations: filteredStations)
                    case .favorites:
                        favoritesSection
                    case .settings:
                        settingsSection
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 120)
            }
            .refreshable {
                guard section != .settings else { return }
                await stationStore.loadStations()
            }
        }
    }

    private var header: some View {
        HStack {
            Text(appLocalized("Greek Radio"))
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(.primary)

            Spacer()

            if stationStore.isLoading {
                ProgressView()
                    .controlSize(.small)
                    .tint(accentTheme.primary)
            }
        }
    }

    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField(appLocalized("Search stations, genres, or cities..."), text: $searchText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 15)
        .background(searchFieldBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var categoryStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(availableRegions, id: \.self) { region in
                    Button {
                        selectedRegion = region
                    } label: {
                        Text(displayRegionName(region))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(selectedRegion == region ? Color.white : Color.primary.opacity(0.72))
                            .padding(.horizontal, 18)
                            .padding(.vertical, 11)
                            .background {
                                Capsule()
                                    .fill(
                                        selectedRegion == region
                                        ? AnyShapeStyle(
                                            LinearGradient(
                                                colors: accentTheme.gradientColors,
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        : AnyShapeStyle(chipBackground)
                                    )
                            }
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }

    private var featuredCard: some View {
        Group {
            if let featuredStation {
                Button {
                    openStation(featuredStation)
                } label: {
                    VStack(alignment: .leading, spacing: 18) {
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(appLocalized("Editor Pick"))
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.white.opacity(0.82))

                                Text(featuredStation.name)
                                    .font(.title.weight(.bold))
                                    .foregroundStyle(.white)

                                Text("\(featuredStation.frequency) • \(featuredStation.region)")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(.white.opacity(0.82))
                            }

                            Spacer()

                            Image(systemName: "dot.radiowaves.left.and.right")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(.white.opacity(0.9))
                        }

                        HStack(spacing: 10) {
                            Label(featuredStation.genreLabel, systemImage: "music.note")
                            Label(appLocalized("Background audio"), systemImage: "iphone.radiowaves.left.and.right")
                        }
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.88))
                    }
                    .padding(22)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        LinearGradient(
                            colors: accentTheme.cardGradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: RoundedRectangle(cornerRadius: 30, style: .continuous)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func stationSection(title: String, stations: [RadioStation]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(title)
                    .font(.title2.weight(.bold))

                Spacer()

                Text("\(stations.count) \(appLocalized("live"))")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(accentTheme.primary)
            }

            if stationStore.isLoading && stations.isEmpty {
                loadingState
            } else if stations.isEmpty {
                emptyState(title: localized("No stations found"), message: stationStore.errorMessage ?? localized("Try another search or choose a different category."))
            } else {
                LazyVStack(spacing: 14) {
                    ForEach(stations) { station in
                        StationRow(
                            station: station,
                            accentTheme: accentTheme,
                            isFavorite: favoriteIDs.contains(station.id),
                            isPlaying: player.currentStation?.id == station.id && player.isPlaying,
                            rowAction: { openStation(station) },
                            playAction: { openStation(station) },
                            favoriteAction: { toggleFavorite(station) }
                        )
                    }
                }
            }
        }
    }

    private var favoritesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(appLocalized("Favorites"))
                .font(.title2.weight(.bold))

            if stationStore.isLoading && filteredStations.isEmpty {
                loadingState
            } else if filteredStations.isEmpty {
                emptyState(title: localized("No favorites yet"), message: localized("Tap the heart on a station to keep it here."))
            } else {
                LazyVStack(spacing: 14) {
                    ForEach(filteredStations) { station in
                        StationRow(
                            station: station,
                            accentTheme: accentTheme,
                            isFavorite: true,
                            isPlaying: player.currentStation?.id == station.id && player.isPlaying,
                            rowAction: { openStation(station) },
                            playAction: { openStation(station) },
                            favoriteAction: { toggleFavorite(station) }
                        )
                    }
                }
            }
        }
    }

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(appLocalized("Accent Color"))
                .font(.title2.weight(.bold))

            Text(appLocalized("Choose a predefined color theme for the app interface."))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(spacing: 14) {
                ForEach(AccentTheme.allCases) { theme in
                    Button {
                        accentThemeID = theme.rawValue
                    } label: {
                        HStack(spacing: 14) {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: theme.gradientColors,
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 28, height: 28)

                            Text(theme.label)
                                .font(.headline)
                                .foregroundStyle(.primary)

                            Spacer()

                            if accentTheme == theme {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(theme.primary)
                            }
                        }
                        .padding(18)
                        .background(cardBackground, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(theme == accentTheme ? theme.primary.opacity(0.5) : Color.primary.opacity(0.08), lineWidth: theme == accentTheme ? 2 : 1)
                        }
                        .shadow(color: cardShadowColor, radius: 18, y: 10)
                    }
                    .buttonStyle(.plain)
                }
            }

            Text(appLocalized("Language"))
                .font(.title2.weight(.bold))
                .padding(.top, 8)

            Text(appLocalized("Supported languages for the app. Tap a language to switch immediately."))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(spacing: 14) {
                ForEach(SupportedLanguage.allCases) { language in
                    Button {
                        selectedAppLanguageCode = language.rawValue
                    } label: {
                        HStack(spacing: 14) {
                            Text(language.flag)
                                .font(.title2)
                                .frame(width: 28, height: 28)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(language.localizedName)
                                    .font(.headline)
                                    .foregroundStyle(.primary)

                                if language.rawValue == selectedAppLanguageCode {
                                    Text(appLocalized("Current app language"))
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Spacer()

                            if language.rawValue == selectedAppLanguageCode {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(accentTheme.primary)
                            }
                        }
                        .padding(18)
                        .background(cardBackground, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(language.rawValue == selectedAppLanguageCode ? accentTheme.primary.opacity(0.5) : Color.primary.opacity(0.08), lineWidth: language.rawValue == selectedAppLanguageCode ? 2 : 1)
                        }
                        .shadow(color: cardShadowColor, radius: 18, y: 10)
                    }
                    .buttonStyle(.plain)
                }
            }

            Text(appLocalized("Support"))
                .font(.title2.weight(.bold))
                .padding(.top, 8)

            Button {
                guard let supportEmailURL else { return }
                openURL(supportEmailURL)
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: "envelope.fill")
                        .font(.title3)
                        .foregroundStyle(accentTheme.primary)
                        .frame(width: 28, height: 28)

                    Text(appLocalized("Email Support"))
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Spacer()

                    Image(systemName: "arrow.up.right.square")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(18)
                .background(cardBackground, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .shadow(color: cardShadowColor, radius: 18, y: 10)
            }
            .buttonStyle(.plain)
        }
    }

    private func emptyState(title: String, message: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: "radio")
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(accentTheme.primary)

            Text(title)
                .font(.headline)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .padding(.horizontal, 20)
        .background(cardBackground, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var loadingState: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(accentTheme.primary)

            Text(appLocalized("Loading stations..."))
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .padding(.horizontal, 20)
        .background(cardBackground, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func miniPlayer(for station: RadioStation) -> some View {
        Button {
            selectedStation = station
            isPlayerPresented = true
        } label: {
            HStack(spacing: 14) {
                StationArtwork(station: station, accentTheme: accentTheme, size: 44)

                VStack(alignment: .leading, spacing: 4) {
                    Text(station.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text(player.isPlaying ? localized("PLAYING NOW") : localized("PAUSED"))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    player.skipBackward()
                } label: {
                    Image(systemName: "backward.fill")
                        .font(.headline)
                        .frame(width: 34, height: 34)
                        .background(controlFill, in: Circle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(.primary)

                Button {
                    player.togglePlayback()
                } label: {
                    Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                        .frame(width: 38, height: 38)
                        .background(
                            LinearGradient(
                                colors: accentTheme.gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            in: Circle()
                        )
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white)

                Button {
                    player.skipForward()
                } label: {
                    Image(systemName: "forward.fill")
                        .font(.headline)
                        .frame(width: 34, height: 34)
                        .background(controlFill, in: Circle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(.primary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .background {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(cardBackground.opacity(colorScheme == .dark ? 0.42 : 0.18))
                    .overlay {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(colorScheme == .dark ? 0.08 : 0.24),
                                        Color.white.opacity(colorScheme == .dark ? 0.02 : 0.08)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .strokeBorder(Color.white.opacity(colorScheme == .dark ? 0.12 : 0.35), lineWidth: 1)
                    }
                    .glassEffect(.regular.tint(accentTheme.primary.opacity(0.14)).interactive(), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            }
            .shadow(color: .white.opacity(colorScheme == .dark ? 0.04 : 0.14), radius: 1, y: -1)
            .shadow(color: .black.opacity(colorScheme == .dark ? 0.28 : 0.12), radius: 18, y: 8)
        }
        .buttonStyle(.plain)
    }

    private func openStation(_ station: RadioStation) {
        selectedStation = station
        player.play(station: station)
        isPlayerPresented = true
    }

    private func toggleFavorite(_ station: RadioStation) {
        let wasAddingFavorite = storedFavorites.contains(where: { $0.stationID == station.id }) == false

        if let storedFavorite = storedFavorites.first(where: { $0.stationID == station.id }) {
            modelContext.delete(storedFavorite)
            UISelectionFeedbackGenerator().selectionChanged()
        } else {
            modelContext.insert(FavoriteStation(stationID: station.id))
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }

        do {
            try modelContext.save()
            if wasAddingFavorite {
                scheduleReviewPromptIfNeeded()
            }
        } catch {
            assertionFailure("Failed to save favorites: \(error.localizedDescription)")
        }
    }

    private func scheduleReviewPromptIfNeeded() {
        guard shouldPromptForReview else { return }

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.5))

            guard shouldPromptForReview else { return }
            isReviewPromptPresented = true
        }
    }

    private var shouldPromptForReview: Bool {
        guard !hasCompletedReviewPrompt else { return false }
        guard reviewPromptDeclineCount < 2 else { return false }

        if reviewPromptDeclineCount == 0 {
            return true
        }

        return Date().timeIntervalSince1970 >= reviewPromptNextEligibleDate
    }

    private func recordReviewPromptDecline() {
        reviewPromptDeclineCount += 1

        if reviewPromptDeclineCount >= 2 {
            hasCompletedReviewPrompt = true
            reviewPromptNextEligibleDate = 0
        } else {
            reviewPromptNextEligibleDate = Date().addingTimeInterval(30 * 24 * 60 * 60).timeIntervalSince1970
        }
    }

    private func completeReviewPromptFlow() {
        hasCompletedReviewPrompt = true
        reviewPromptNextEligibleDate = 0

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.75))
            requestReview()
        }
    }
}

private struct StationRow: View {
    let station: RadioStation
    let accentTheme: AccentTheme
    let isFavorite: Bool
    let isPlaying: Bool
    let rowAction: () -> Void
    let playAction: () -> Void
    let favoriteAction: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Button(action: rowAction) {
                HStack(spacing: 14) {
                    StationArtwork(station: station, accentTheme: accentTheme, size: 58)

                    VStack(alignment: .leading, spacing: 6) {
                        Text(station.name)
                            .font(.headline)
                            .foregroundStyle(.primary)

                        Text(station.frequency)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(accentTheme.primary)

                        Text(station.region)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button(action: favoriteAction) {
                Image(systemName: isFavorite ? "heart.fill" : "heart")
                    .font(.title3)
                    .foregroundStyle(isFavorite ? accentTheme.primary : Color.secondary.opacity(0.75))
            }
            .buttonStyle(.plain)

            Button(action: playAction) {
                VStack(spacing: 4) {
                    Image(systemName: isPlaying ? "speaker.wave.2.fill" : "play.circle")
                        .font(.title3.weight(.semibold))
                    Text(isPlaying ? appLocalized("LIVE") : appLocalized("PLAY"))
                        .font(.caption2.weight(.bold))
                }
                .foregroundStyle(isPlaying ? accentTheme.primary : Color.primary.opacity(0.75))
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 18, y: 10)
    }
}

private struct PlayerSheet: View {
    let station: RadioStation
    @ObservedObject var player: RadioPlayer
    let accentTheme: AccentTheme
    let isFavorite: Bool
    let favoriteAction: () -> Void
    @Environment(\.dismiss) private var dismiss

    private var displayedStation: RadioStation {
        player.currentStation ?? station
    }

    private var isDisplayingCurrentStation: Bool {
        player.currentStation?.id == displayedStation.id
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: accentTheme.playerGradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 22) {
                HStack {
                    Button(appLocalized("Close")) {
                        dismiss()
                    }
                    .foregroundStyle(.white.opacity(0.82))

                    Spacer()

                    Button(action: favoriteAction) {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                            .font(.title3)
                            .foregroundStyle(.white)
                    }
                }
                .padding(.top, 12)

                Spacer(minLength: 0)

                StationArtwork(station: displayedStation, accentTheme: accentTheme, size: 180)
                    .shadow(color: .black.opacity(0.24), radius: 30, y: 16)

                VStack(spacing: 8) {
                    Text(displayedStation.name)
                        .font(.system(size: 34, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    Text("\(displayedStation.frequency) • \(displayedStation.region)")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.82))

                    Text(displayedStation.description)
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.72))
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                }

                HStack(spacing: 28) {
                    Button {
                        player.skipBackward()
                    } label: {
                        Image(systemName: "backward.end.fill")
                            .font(.title2)
                            .frame(width: 58, height: 58)
                            .background(Color.white.opacity(0.14), in: Circle())
                    }

                    Button {
                        if !isDisplayingCurrentStation {
                            player.play(station: displayedStation)
                        } else {
                            player.togglePlayback()
                        }
                    } label: {
                        ZStack {
                            Image(systemName: "play.fill")
                                .opacity(isDisplayingCurrentStation && player.isPlaying ? 0 : 1)

                            Image(systemName: "pause.fill")
                                .opacity(isDisplayingCurrentStation && player.isPlaying ? 1 : 0)
                        }
                        .font(.system(size: 30, weight: .bold))
                        .frame(width: 30, height: 30)
                        .frame(width: 86, height: 86)
                        .background(Color.white, in: Circle())
                        .foregroundStyle(Color.black)
                    }

                    Button {
                        player.skipForward()
                    } label: {
                        Image(systemName: "forward.end.fill")
                            .font(.title2)
                            .frame(width: 58, height: 58)
                            .background(Color.white.opacity(0.14), in: Circle())
                    }
                }
                .foregroundStyle(.white)
                .padding(.top, 8)

                statusPanel

                Spacer()
            }
            .padding(24)
        }
    }

    private var statusPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                if player.isBuffering {
                    ProgressView()
                        .tint(.white)
                        .controlSize(.small)
                } else {
                    Image(systemName: player.isPlaying ? "waveform" : "pause.circle")
                        .padding(.top, 2)
                }

                Text(player.isBuffering ? appLocalized("Buffering stream...") : (player.isPlaying ? appLocalized("Streaming live in the background") : appLocalized("Ready to resume playback")))
                    .font(.headline)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(player.isBuffering ? appLocalized("Fetching data") : appLocalized("Stream rate"))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.88))
                        .multilineTextAlignment(.leading)

                    Text("\(player.currentKilobytesPerSecond, format: .number.precision(.fractionLength(1))) KB/s")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.72))
                }

                ThroughputGraph(samples: player.throughputSamples)
                    .frame(height: 34)
            }
            .frame(height: 72, alignment: .top)
            .opacity(player.isPlaying || player.isBuffering ? 1 : 0)

            Text(player.isBuffering
                 ? appLocalized("The app is pulling audio data from the stream and filling the playback buffer.")
                 : appLocalized("The audio session is configured for background playback, so the stream can continue when the app is locked or moved behind another app."))
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.72))
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

private struct ThroughputGraph: View {
    let samples: [Double]

    private var normalizedSamples: [Double] {
        let maxValue = max(samples.max() ?? 0, 1)
        return samples.map { max(0.08, $0 / maxValue) }
    }

    var body: some View {
        GeometryReader { geometry in
            let points = normalizedSamples.enumerated().map { index, sample in
                CGPoint(
                    x: xPosition(for: index, width: geometry.size.width, count: normalizedSamples.count),
                    y: yPosition(for: sample, height: geometry.size.height)
                )
            }

            ZStack {
                Path { path in
                    guard let firstPoint = points.first else { return }
                    path.move(to: firstPoint)
                    for point in points.dropFirst() {
                        path.addLine(to: point)
                    }
                }
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.95), Color.white.opacity(0.55)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
                )

                Path { path in
                    guard let firstPoint = points.first, let lastPoint = points.last else { return }
                    path.move(to: CGPoint(x: firstPoint.x, y: geometry.size.height))
                    path.addLine(to: firstPoint)
                    for point in points.dropFirst() {
                        path.addLine(to: point)
                    }
                    path.addLine(to: CGPoint(x: lastPoint.x, y: geometry.size.height))
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.18), Color.white.opacity(0.02)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
        .padding(.vertical, 3)
    }

    private func xPosition(for index: Int, width: CGFloat, count: Int) -> CGFloat {
        guard count > 1 else { return width / 2 }
        return width * CGFloat(index) / CGFloat(count - 1)
    }

    private func yPosition(for sample: Double, height: CGFloat) -> CGFloat {
        let topInset: CGFloat = 2
        let bottomInset: CGFloat = 2
        let drawableHeight = height - topInset - bottomInset
        return height - bottomInset - (drawableHeight * sample)
    }
}

private struct StationArtwork: View {
    let station: RadioStation
    let accentTheme: AccentTheme
    let size: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
            .fill(
                LinearGradient(
                    colors: accentTheme.cardGradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: size, height: size)
            .overlay {
                VStack(spacing: size * 0.06) {
                    Text(station.artworkBadgeTitle)
                        .font(.system(size: size * 0.28, weight: .black, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)

                    Text(station.artworkBadgeSubtitle)
                        .font(.system(size: size * 0.14, weight: .bold, design: .rounded))
                        .tracking(0.8)
                        .opacity(0.86)
                }
                .foregroundStyle(.white)
            }
    }
}

private enum AccentTheme: String, CaseIterable, Identifiable {
    case sunset
    case aegean
    case olive
    case berry
    case graphite

    var id: String { rawValue }

    var label: String {
        switch self {
        case .sunset:
            return appLocalized("Sunset")
        case .aegean:
            return appLocalized("Aegean")
        case .olive:
            return appLocalized("Olive")
        case .berry:
            return appLocalized("Berry")
        case .graphite:
            return appLocalized("Graphite")
        }
    }

    var primary: Color {
        gradientColors[0]
    }

    var gradientColors: [Color] {
        switch self {
        case .sunset:
            return [Color(red: 0.90, green: 0.49, blue: 0.16), Color(red: 0.73, green: 0.35, blue: 0.10)]
        case .aegean:
            return [Color(red: 0.10, green: 0.54, blue: 0.83), Color(red: 0.05, green: 0.31, blue: 0.62)]
        case .olive:
            return [Color(red: 0.42, green: 0.60, blue: 0.20), Color(red: 0.26, green: 0.42, blue: 0.12)]
        case .berry:
            return [Color(red: 0.78, green: 0.24, blue: 0.41), Color(red: 0.50, green: 0.12, blue: 0.31)]
        case .graphite:
            return [Color(red: 0.34, green: 0.39, blue: 0.47), Color(red: 0.17, green: 0.20, blue: 0.26)]
        }
    }

    var cardGradientColors: [Color] {
        [gradientColors[0], gradientColors[1], gradientColors[1].opacity(0.82)]
    }

    var playerGradientColors: [Color] {
        [gradientColors[0].opacity(0.94), gradientColors[1].opacity(0.98), Color.black.opacity(0.94)]
    }
}

private enum SupportedLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case greek = "el"

    var id: String { rawValue }

    var flag: String {
        switch self {
        case .english:
            return "🇬🇧"
        case .greek:
            return "🇬🇷"
        }
    }

    var localizedName: String {
        switch self {
        case .english:
            return "English"
        case .greek:
            return "Ελληνικά"
        }
    }
}

private enum AppSection: CaseIterable, Identifiable {
    case home
    case stations
    case favorites
    case settings

    var id: String { title }

    var title: String {
        switch self {
        case .home: return appLocalized("HOME")
        case .stations: return appLocalized("STATIONS")
        case .favorites: return appLocalized("FAVORITES")
        case .settings: return appLocalized("SETTINGS")
        }
    }

    var tabTitle: String {
        switch self {
        case .home: return appLocalized("Home")
        case .stations: return appLocalized("Stations")
        case .favorites: return appLocalized("Favorites")
        case .settings: return appLocalized("Settings")
        }
    }

    var symbol: String {
        switch self {
        case .home: return "house"
        case .stations: return "radio"
        case .favorites: return "heart"
        case .settings: return "gearshape"
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [FavoriteStation.self], inMemory: true)
}
