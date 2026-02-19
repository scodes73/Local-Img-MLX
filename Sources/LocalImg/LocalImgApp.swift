// Copyright © 2024 LocalImg. All rights reserved.

import SwiftData
import SwiftUI

/// Main app entry point
@main
struct LocalImgApp: App {

    @State private var appSettings = AppSettings()
    @State private var modelManager = ModelManager()

    init() {
        // When running via `swift run` (not as a .app bundle), macOS treats the
        // process as an accessory/background app. This causes focus to split
        // between the terminal and the app window. Setting .regular makes macOS
        // treat it as a normal foreground GUI application.
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appSettings)
                .environment(modelManager)
                .frame(minWidth: 900, minHeight: 600)
        }
        .modelContainer(for: GenerationRecord.self)
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: true))

        Settings {
            SettingsView()
                .environment(appSettings)
                .environment(modelManager)
        }
    }
}
