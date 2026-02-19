// Copyright © 2024 LocalImg. All rights reserved.

import SwiftData
import SwiftUI

/// Main content view with NavigationSplitView layout
struct ContentView: View {

    @Environment(AppSettings.self) private var settings
    @Environment(ModelManager.self) private var modelManager
    @Environment(\.modelContext) private var modelContext

    @State private var selectedRecord: GenerationRecord?
    @State private var historyManager: HistoryManager?
    @State private var showOnboarding = true

    var body: some View {
        Group {
            if showOnboarding {
                OnboardingView(onComplete: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showOnboarding = false
                    }
                })
            } else {
                mainContent
            }
        }
        .onAppear {
            showOnboarding = !settings.hasCompletedOnboarding || settings.alwaysShowOnboarding
            historyManager = HistoryManager(modelContext: modelContext)
        }
    }

    @ViewBuilder
    private var mainContent: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            GenerationView(historyManager: historyManager, selectedRecord: $selectedRecord)
        }
    }

    @ViewBuilder
    private var sidebar: some View {
        VStack(spacing: 0) {
            HistoryGalleryView(
                historyManager: historyManager,
                selectedRecord: $selectedRecord
            )
        }
        .navigationSplitViewColumnWidth(min: 220, ideal: 260, max: 320)
        .toolbar {
            // ToolbarItem(placement: .automatic) {
            //     Text("History")
            //         .font(.headline)
            //         .foregroundStyle(.secondary)
            // }
        }
    }
}
