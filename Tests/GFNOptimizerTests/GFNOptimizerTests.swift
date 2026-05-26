import Testing
@testable import CloudBoost

// MARK: - Presets

@Test func presetCompetitiveEnablesEverything() throws {
    Preferences.selectedPreset = .competitive
    let p = Preferences.presetConfig()
    #expect(p.disableAwdl        == true)
    #expect(p.flushDns           == true)
    #expect(p.disableTimeMachine == true)
    #expect(p.purgeMemory        == true)
    #expect(p.keepAwake          == true)
}

@Test func presetBalancedIsConservative() throws {
    Preferences.selectedPreset = .balanced
    let p = Preferences.presetConfig()
    #expect(p.disableAwdl        == true,  "Balanced should disable AWDL")
    #expect(p.flushDns           == true,  "Balanced should flush DNS")
    #expect(p.disableTimeMachine == false, "Balanced must not disable Time Machine")
    #expect(p.purgeMemory        == false, "Balanced must not purge RAM")
    #expect(p.keepAwake          == true)
}

@Test func presetStreamQualitySkipsPurge() throws {
    Preferences.selectedPreset = .streamQuality
    let p = Preferences.presetConfig()
    #expect(p.disableTimeMachine == true)
    #expect(p.purgeMemory        == false, "Stream Quality must not purge RAM — causes decoder hitches")
    #expect(p.keepAwake          == true)
}

@Test func presetDefaultIsCompetitive() throws {
    UserDefaults.standard.removeObject(forKey: "SelectedPreset")
    #expect(Preferences.selectedPreset == .competitive)
}

// MARK: - Preferences round-trip

@Test func preferencesRoundTrip() throws {
    Preferences.keepAliveEnabled         = true
    Preferences.keepAliveIntervalMinutes = 7
    Preferences.allowlist                = ["MyApp", "OtherApp"]
    Preferences.blocklist                = ["BadApp"]

    #expect(Preferences.keepAliveEnabled)
    #expect(Preferences.keepAliveIntervalMinutes == 7)
    #expect(Preferences.allowlist.contains("MyApp"))
    #expect(Preferences.blocklist.contains("BadApp"))

    // Cleanup
    Preferences.keepAliveEnabled         = false
    Preferences.keepAliveIntervalMinutes = 4
    Preferences.allowlist                = []
    Preferences.blocklist                = []
}

// MARK: - CloudPlatform

@Test func platformShortNamesAreUnique() throws {
    let names = CloudPlatform.allCases.map(\.shortName)
    #expect(Set(names).count == names.count)
}

@Test func platformProcessNamesAreNonEmpty() throws {
    UserDefaults.standard.set(false, forKey: "BoosteroidUseBrowser")
    for platform in CloudPlatform.allCases {
        #expect(!platform.processNames.isEmpty,
                "\(platform.rawValue) must have at least one process name")
    }
}

// MARK: - DiagnosticsManager

@Test func diagnosticsBuildReportDoesNotCrash() throws {
    DiagnosticsManager.shared.log("Unit test event A")
    DiagnosticsManager.shared.log("Unit test event B")
    let report = DiagnosticsManager.shared.buildReport(
        selectedPlatform: .geforceNow,
        targetProcessNames: ["NVIDIA GeForce NOW"]
    )
    #expect(report.contains("CloudBoost Diagnostics"))
    #expect(report.contains("GeForce NOW"))
}

// MARK: - SystemState encode/decode

@Test func systemStateRoundTrip() throws {
    let original = SystemState(
        awdlEnabled:        true,
        timeMachineEnabled: false,
        mouseScaling:       "2.5",
        timestamp:          Date()
    )
    let data    = try JSONEncoder().encode(original)
    let decoded = try JSONDecoder().decode(SystemState.self, from: data)

    #expect(decoded.awdlEnabled        == original.awdlEnabled)
    #expect(decoded.timeMachineEnabled == original.timeMachineEnabled)
    #expect(decoded.mouseScaling       == original.mouseScaling)
}
