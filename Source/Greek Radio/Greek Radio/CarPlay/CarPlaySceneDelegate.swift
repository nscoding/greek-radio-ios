import CarPlay
import Combine

@MainActor
final class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {

    private var interfaceController: CPInterfaceController?
    private let player = RadioPlayer.shared
    private let stationStore = RadioStationStore.shared
    private var cancellables: Set<AnyCancellable> = []

    // nonisolated so the ObjC runtime can see these selectors during respondsToSelector: checks.
    // @MainActor on the class otherwise wraps them in actor-isolation thunks that become invisible.
    nonisolated func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didConnect interfaceController: CPInterfaceController
    ) {
        Task { @MainActor [weak self] in
            self?.connect(to: interfaceController)
        }
    }

    nonisolated func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didDisconnect interfaceController: CPInterfaceController
    ) {
        Task { @MainActor [weak self] in
            self?.disconnect()
        }
    }

    // MARK: - Lifecycle

    private func connect(to interfaceController: CPInterfaceController) {
        self.interfaceController = interfaceController
        interfaceController.setRootTemplate(makeTabBarTemplate(), animated: false, completion: nil)

        stationStore.$stations
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.refreshStationTemplates() }
            .store(in: &cancellables)

        player.$currentStation
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.refreshStationTemplates() }
            .store(in: &cancellables)

        player.$isPlaying
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.refreshStationTemplates() }
            .store(in: &cancellables)

        Task { await stationStore.loadStationsIfNeeded() }
    }

    private func disconnect() {
        interfaceController = nil
        cancellables.removeAll()
    }

    // MARK: - Templates

    private func makeTabBarTemplate() -> CPTabBarTemplate {
        CPTabBarTemplate(templates: [makeStationsTemplate(), makeFavoritesTemplate()])
    }

    private func makeStationsTemplate() -> CPListTemplate {
        let template = CPListTemplate(
            title: String(localized: "Stations"),
            sections: stationSections(from: stationStore.stations)
        )
        template.tabImage = UIImage(systemName: "radio")
        template.emptyViewTitleVariants = [String(localized: "Loading Stations")]
        template.emptyViewSubtitleVariants = [String(localized: "Please wait…")]
        return template
    }

    private func makeFavoritesTemplate() -> CPListTemplate {
        let favoriteIDs = CarPlayFavorites.load()
        let stations = stationStore.stations.filter { favoriteIDs.contains($0.id) }
        let template = CPListTemplate(
            title: String(localized: "Favorites"),
            sections: stationSections(from: stations)
        )
        template.tabImage = UIImage(systemName: "heart")
        template.emptyViewTitleVariants = [String(localized: "No Favorites")]
        template.emptyViewSubtitleVariants = [String(localized: "Add favorites in the Greek Radio app.")]
        return template
    }

    private func stationSections(from stations: [RadioStation]) -> [CPListSection] {
        let grouped = Dictionary(grouping: stations, by: \.region)
        return grouped.keys.sorted().map { region in
            let items = grouped[region]!
                .sorted { $0.name < $1.name }
                .map(makeListItem)
            return CPListSection(
                items: items,
                header: region,
                sectionIndexTitle: String(region.prefix(1))
            )
        }
    }

    private func makeListItem(for station: RadioStation) -> CPListItem {
        let item = CPListItem(
            text: station.name,
            detailText: "\(station.frequency) • \(station.region)"
        )
        item.isPlaying = player.currentStation?.id == station.id && player.isPlaying
        item.playingIndicatorLocation = .trailing
        item.handler = { [weak self] _, completion in
            Task { @MainActor [weak self] in
                guard let self else { completion(); return }
                self.player.play(station: station)
                self.interfaceController?.pushTemplate(
                    CPNowPlayingTemplate.shared,
                    animated: true,
                    completion: nil
                )
                completion()
            }
        }
        return item
    }

    private func refreshStationTemplates() {
        guard let tabBar = interfaceController?.rootTemplate as? CPTabBarTemplate else { return }
        tabBar.updateTemplates([makeStationsTemplate(), makeFavoritesTemplate()])
    }
}

// MARK: - Favorites sync bridge (SwiftData → UserDefaults for CarPlay)

enum CarPlayFavorites {
    private static let key = "carplay.favoriteStationIDs"

    static func load() -> Set<Int64> {
        let ids = UserDefaults.standard.array(forKey: key) as? [Int64] ?? []
        return Set(ids)
    }

    static func save(_ ids: Set<Int64>) {
        UserDefaults.standard.set(Array(ids), forKey: key)
    }
}
