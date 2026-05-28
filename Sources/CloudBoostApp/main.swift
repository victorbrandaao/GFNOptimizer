import AppKit
import CloudBoostLib

if CommandLine.arguments.contains("--self-test") {
    exit(CloudBoostSelfTest.run())
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
