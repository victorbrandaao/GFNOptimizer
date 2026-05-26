import Testing
@testable import CloudBoost

@Test func presetDefaultsAreStable() async throws {
    let preset = Preferences.presetConfig()
    #expect(preset.name == .competitive)
}
