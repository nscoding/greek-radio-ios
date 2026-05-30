import CarPlay
import Combine
import MediaPlayer

final class CarPlaySceneDelegate: NSObject, CPTemplateApplicationSceneDelegate {
    private var interfaceController: CPInterfaceController?
    private var tabBarTemplate: CPTabBarTemplate?
    private var favoritesTemplate: CPListTemplate?
    private var allStationsTemplate: CPListTemplate?
    private var cancellables: Set<AnyCancellable> = []

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didConnect interfaceController: CPInterfaceController
    ) {
        self.interfaceController = interfaceController
        buildUI()

        RadioStationStore.shared.$stations
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.buildUI() }
            .store(in: &cancellables)

        RadioPlayer.shared.$currentStation
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.buildUI() }
            .store(in: &cancellables)

        RadioPlayer.shared.$isPlaying
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.buildUI() }
            .store(in: &cancellables)

        FavoritesStore.shared.$stationIDs
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.buildUI() }
            .store(in: &cancellables)
    }

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didDisconnectInterfaceController interfaceController: CPInterfaceController
    ) {
        cancellables.removeAll()
        self.interfaceController = nil
    }

    // MARK: - Template construction

    @MainActor
    private func buildUI() {
        let stations = RadioStationStore.shared.stations
        let player = RadioPlayer.shared
        let favoriteIDs = FavoritesStore.shared.stationIDs

        let favoriteSections = buildFavoriteSections(stations: stations, favoriteIDs: favoriteIDs, player: player)
        let allSections = buildAllStationsSections(stations: stations, player: player)

        if let favoritesTemplate, let allStationsTemplate {
            favoritesTemplate.updateSections(favoriteSections)
            allStationsTemplate.updateSections(allSections)
        } else {
            let favorites = CPListTemplate(
                title: appLocalized("Favorites"),
                sections: favoriteSections
            )
            favorites.tabTitle = appLocalized("Favorites")
            favorites.tabImage = UIImage(systemName: "star.fill")
            favoritesTemplate = favorites

            let all = CPListTemplate(
                title: appLocalized("All Stations"),
                sections: allSections
            )
            all.tabTitle = appLocalized("All Stations")
            all.tabImage = UIImage(systemName: "dot.radiowaves.left.and.right")
            allStationsTemplate = all

            let tabBar = CPTabBarTemplate(templates: [favorites, all])
            tabBarTemplate = tabBar
            interfaceController?.setRootTemplate(tabBar, animated: false, completion: nil)
        }
    }

    @MainActor
    private func buildFavoriteSections(
        stations: [RadioStation],
        favoriteIDs: Set<Int64>,
        player: RadioPlayer
    ) -> [CPListSection] {
        var sections: [CPListSection] = []

        if let current = player.currentStation {
            let nowPlayingItem = makeNowPlayingHeaderItem(station: current)
            sections.append(CPListSection(
                items: [nowPlayingItem],
                header: appLocalized("Now Playing"),
                sectionIndexTitle: nil
            ))
        }

        let favoriteStations = stations.filter { favoriteIDs.contains($0.id) }
        if favoriteStations.isEmpty {
            let empty = CPListItem(text: appLocalized("No favorites yet"), detailText: appLocalized("Add favorites in the app"))
            empty.isEnabled = false
            sections.append(CPListSection(items: [empty]))
        } else {
            sections.append(CPListSection(
                items: favoriteStations.map { makeStationItem($0, player: player) },
                header: appLocalized("Favorites"),
                sectionIndexTitle: nil
            ))
        }

        return sections
    }

    @MainActor
    private func buildAllStationsSections(
        stations: [RadioStation],
        player: RadioPlayer
    ) -> [CPListSection] {
        var sections: [CPListSection] = []

        if let current = player.currentStation {
            let nowPlayingItem = makeNowPlayingHeaderItem(station: current)
            sections.append(CPListSection(
                items: [nowPlayingItem],
                header: appLocalized("Now Playing"),
                sectionIndexTitle: nil
            ))
        }

        let regionGroups = Dictionary(grouping: stations, by: \.region)
        let sortedRegions = regionGroups.keys.sorted()

        for region in sortedRegions {
            sections.append(CPListSection(
                items: (regionGroups[region] ?? []).map { makeStationItem($0, player: player) },
                header: region,
                sectionIndexTitle: String(region.prefix(1))
            ))
        }

        return sections
    }

    @MainActor
    private func makeNowPlayingHeaderItem(station: RadioStation) -> CPListItem {
        let item = CPListItem(
            text: station.name,
            detailText: "\(station.frequency) • \(station.region)"
        )
        item.accessoryType = .disclosureIndicator
        item.handler = { [weak self] _, completion in
            completion()
            DispatchQueue.main.async { self?.showNowPlaying() }
        }
        return item
    }

    @MainActor
    private func makeStationItem(_ station: RadioStation, player: RadioPlayer) -> CPListItem {
        let item = CPListItem(text: station.name, detailText: station.frequency)
        let isPlaying = player.currentStation?.id == station.id && player.isPlaying
        item.accessoryType = isPlaying ? .none : .disclosureIndicator
        if isPlaying {
            item.playingIndicatorLocation = .trailing
            item.isPlaying = true
        }
        item.handler = { [weak self] _, completion in
            completion()
            DispatchQueue.main.async {
                RadioPlayer.shared.play(station: station)
                self?.showNowPlaying()
            }
        }
        return item
    }

    private func showNowPlaying() {
        let nowPlaying = CPNowPlayingTemplate.shared
        interfaceController?.pushTemplate(nowPlaying, animated: true, completion: nil)
    }
}
