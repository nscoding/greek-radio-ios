//
//  Greek_RadioTests.swift
//  Greek RadioTests
//
//  Created by Patrik Tomas Chamelo on 5/4/26.
//

import XCTest
@testable import Greek_Radio

final class Greek_RadioTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testCosmoradioGreekAndEnglishMatching() {
        let latinStation = RadioStation(
            id: 1,
            name: "Cosmoradio 95.1",
            shortName: "COSMO",
            frequency: "95.1 FM",
            region: "Thessaloniki",
            description: "No. 1 hit music radio station in Thessaloniki.",
            symbol: "dot.radiowaves.left.and.right",
            streamURL: URL(string: "https://stream.cosmoradio.gr")!,
            palette: [],
            categories: [.all, .music]
        )

        let greekStation = RadioStation(
            id: 2,
            name: "Κοσμοράδιο 95.1",
            shortName: "ΚΟΣΜΟ",
            frequency: "95.1 FM",
            region: "Θεσσαλονίκη",
            description: "Το νο1 ραδιόφωνο επιτυχιών στη Θεσσαλονίκη.",
            symbol: "dot.radiowaves.left.and.right",
            streamURL: URL(string: "https://stream.cosmoradio.gr")!,
            palette: [],
            categories: [.all, .music]
        )

        // Searching the Latin station with Greek queries
        XCTAssertTrue(latinStation.matchesSearch("Κοσμοραδιο"))
        XCTAssertTrue(latinStation.matchesSearch("Κοσμοράδιο"))
        XCTAssertTrue(latinStation.matchesSearch("κοσμο"))
        XCTAssertTrue(latinStation.matchesSearch("ραδιο"))
        XCTAssertTrue(latinStation.matchesSearch("cosmo"))
        XCTAssertTrue(latinStation.matchesSearch("kosmo"))
        XCTAssertTrue(latinStation.matchesSearch("radio"))

        // Searching the Greek station with Latin queries
        XCTAssertTrue(greekStation.matchesSearch("Cosmoradio"))
        XCTAssertTrue(greekStation.matchesSearch("cosmo"))
        XCTAssertTrue(greekStation.matchesSearch("kosmo"))
        XCTAssertTrue(greekStation.matchesSearch("radio"))
        XCTAssertTrue(greekStation.matchesSearch("ραδιο"))
        XCTAssertTrue(greekStation.matchesSearch("κοσμοραδιο"))
        XCTAssertTrue(greekStation.matchesSearch("κοσμοράδιο"))
    }

    func testGreeklishAndPhoneticVariations() {
        func makeStation(name: String, region: String = "Greece", frequency: String = "100.0 FM") -> RadioStation {
            RadioStation(
                id: Int64(abs(name.hashValue)),
                name: name,
                shortName: "TEST",
                frequency: frequency,
                region: region,
                description: "Test radio station",
                symbol: "dot.radiowaves.left.and.right",
                streamURL: URL(string: "https://example.com/stream")!,
                palette: [],
                categories: [.all]
            )
        }

        let thessaloniki = makeStation(name: "Thessaloniki Radio", region: "Thessaloniki")
        XCTAssertTrue(thessaloniki.matchesSearch("Θεσσαλονίκη"))
        XCTAssertTrue(thessaloniki.matchesSearch("θεσσ"))
        XCTAssertTrue(thessaloniki.matchesSearch("thess"))

        let rythmos = makeStation(name: "Ρυθμός 94.9")
        XCTAssertTrue(rythmos.matchesSearch("Rythmos"))
        XCTAssertTrue(rythmos.matchesSearch("rithmos"))
        XCTAssertTrue(rythmos.matchesSearch("rythm"))
        XCTAssertTrue(rythmos.matchesSearch("ρυθμος"))

        let melodia = makeStation(name: "Μελωδία 99.2")
        XCTAssertTrue(melodia.matchesSearch("Melodia"))
        XCTAssertTrue(melodia.matchesSearch("melwdia"))
        XCTAssertTrue(melodia.matchesSearch("μελωδια"))

        let sfera = makeStation(name: "Σφαίρα 102.2")
        XCTAssertTrue(sfera.matchesSearch("Sfera"))
        XCTAssertTrue(sfera.matchesSearch("sphera"))
        XCTAssertTrue(sfera.matchesSearch("σφαιρα"))

        let chania = makeStation(name: "Chania Radio", region: "Chania")
        XCTAssertTrue(chania.matchesSearch("Χανιά"))
        XCTAssertTrue(chania.matchesSearch("xania"))
        XCTAssertTrue(chania.matchesSearch("hania"))
        XCTAssertTrue(chania.matchesSearch("χανια"))

        let flash = makeStation(name: "Flash 96.0")
        XCTAssertTrue(flash.matchesSearch("Φλας"))
        XCTAssertTrue(flash.matchesSearch("flash"))

        let enLefko = makeStation(name: "En Lefko 87.7")
        XCTAssertTrue(enLefko.matchesSearch("Εν Λευκώ"))
        XCTAssertTrue(enLefko.matchesSearch("εν λευκο"))
        XCTAssertTrue(enLefko.matchesSearch("lefko"))

        let kiss = makeStation(name: "Kiss FM 92.9")
        XCTAssertTrue(kiss.matchesSearch("Κις"))
        XCTAssertTrue(kiss.matchesSearch("kiss"))

        let diesi = makeStation(name: "Δίεση 101.3")
        XCTAssertTrue(diesi.matchesSearch("diesi"))
        XCTAssertTrue(diesi.matchesSearch("διεση"))

        let dromos = makeStation(name: "Δρόμος 89.8")
        XCTAssertTrue(dromos.matchesSearch("dromos"))
        XCTAssertTrue(dromos.matchesSearch("δρομος"))

        let ellinikos = makeStation(name: "Ελληνικός 93.2")
        XCTAssertTrue(ellinikos.matchesSearch("ellinikos"))
        XCTAssertTrue(ellinikos.matchesSearch("elinikos"))

        let athensVoice = makeStation(name: "Athens Voice 102.5")
        XCTAssertTrue(athensVoice.matchesSearch("αθενς βοις"))
        XCTAssertTrue(athensVoice.matchesSearch("βοις"))

        let galaxy = makeStation(name: "Galaxy 92.0")
        XCTAssertTrue(galaxy.matchesSearch("γαλαξι"))

        let kriti = makeStation(name: "Kriti FM 87.5", region: "Crete")
        XCTAssertTrue(kriti.matchesSearch("κρητη"))
        XCTAssertTrue(kriti.matchesSearch("κριτη"))
    }

    func testMultiWordQueries() {
        let station = RadioStation(
            id: 10,
            name: "Cosmoradio 95.1",
            shortName: "COSMO",
            frequency: "95.1 FM",
            region: "Thessaloniki",
            description: "Hit music radio.",
            symbol: "dot.radiowaves.left.and.right",
            streamURL: URL(string: "https://example.com/stream")!,
            palette: [],
            categories: [.all]
        )

        XCTAssertTrue(station.matchesSearch("κοσμο 95.1"))
        XCTAssertTrue(station.matchesSearch("95.1 κοσμο"))
        XCTAssertTrue(station.matchesSearch("thess cosmo"))
        XCTAssertTrue(station.matchesSearch("θεσσ κοσμο"))
    }

    func testDiacriticInsensitivity() {
        XCTAssertEqual(
            GreekSearchMatcher.stripAccentsAndLowercase("Κοσμοράδιο"),
            "κοσμοραδιο"
        )
        XCTAssertEqual(
            GreekSearchMatcher.stripAccentsAndLowercase("Μελωδία"),
            "μελωδια"
        )
        XCTAssertEqual(
            GreekSearchMatcher.stripAccentsAndLowercase("Ρυθμός"),
            "ρυθμος"
        )
    }

    func testGreekSearchMatcherDirect() {
        XCTAssertEqual(GreekSearchMatcher.latinToGreek("cosmoradio"), "κοσμοραδιο")
        XCTAssertEqual(GreekSearchMatcher.greekToLatin("κοσμοραδιο"), "kosmoradio")
        XCTAssertTrue(GreekSearchMatcher.matches(query: "Κοσμοραδιο", in: "Cosmoradio 95.1"))
        XCTAssertTrue(GreekSearchMatcher.matches(query: "Cosmoradio", in: "Κοσμοράδιο 95.1"))
    }

    func testAudioInterruptionHandling() {
        let player = RadioPlayer.shared

        // Post simulated interruption began
        NotificationCenter.default.post(
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            userInfo: [
                AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.began.rawValue
            ]
        )

        // Post simulated interruption ended with shouldResume
        NotificationCenter.default.post(
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            userInfo: [
                AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.ended.rawValue,
                AVAudioSessionInterruptionOptionKey: AVAudioSession.InterruptionOptions.shouldResume.rawValue
            ]
        )

        // Post simulated interruption ended without options (e.g. CallKit/CarPlay phone call end)
        NotificationCenter.default.post(
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            userInfo: [
                AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.ended.rawValue
            ]
        )

        // Post simulated route change (old device unavailable)
        NotificationCenter.default.post(
            name: AVAudioSession.routeChangeNotification,
            object: AVAudioSession.sharedInstance(),
            userInfo: [
                AVAudioSessionRouteChangeReasonKey: AVAudioSession.RouteChangeReason.oldDeviceUnavailable.rawValue
            ]
        )

        XCTAssertNotNil(player)
    }

}
