// Copyright © 2024 LocalImg. All rights reserved.

import SwiftUI

/// Onboarding view shown on first launch for model download
struct OnboardingView: View {

    @Environment(AppSettings.self) private var settings
    @Environment(ModelManager.self) private var modelManager

    @State private var selectedModelInfo: ModelInfo = .sdxlTurbo
    @State private var showModelPicker = false
    @State private var isSelectedModelCached = false

    var onComplete: (() -> Void)? = nil

    var body: some View {
        @Bindable var settings = settings
        ZStack {
            LiquidGlassView(speed: 0.5, opacity: 0.6)
                .allowsHitTesting(false)
            
            VStack(spacing: 0) {
            Spacer()

            // App icon / hero
            VStack(spacing: 16) {
                Image(systemName: "paintbrush.pointed.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.white)
                    .shadow(color: .purple.opacity(0.3), radius: 20, y: 10)

                Text("LocalImg")
                    .font(.system(size: 36, weight: .bold, design: .rounded))

                Text("Generate images locally with AI on your Mac")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            Spacer()
                .frame(height: 48)

            // Model info card
            VStack(spacing: 16) {
                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(selectedModelInfo.name)
                                    .font(.headline)
                                Text(selectedModelInfo.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                            Spacer()

                            if isSelectedModelCached {
                                Label("Downloaded", systemImage: "checkmark.circle.fill")
                                    .font(.caption.bold())
                                    .foregroundStyle(.green)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(.green.opacity(0.1), in: Capsule())
                            } else {
                                Text("~\(String(format: "%.1f", selectedModelInfo.estimatedSizeGB)) GB")
                                    .font(.callout)
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(.quaternary, in: Capsule())
                            }
                        }

                        // Model picker
                        if showModelPicker {
                            Divider()
                            ForEach(ModelInfo.availableModels) { model in
                                Button {
                                    selectedModelInfo = model
                                    showModelPicker = false
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(model.name).font(.subheadline.bold())
                                            Text(model.description).font(.caption).foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        if model.id == selectedModelInfo.id {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(.blue)
                                        }
                                    }
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        Button {
                            withAnimation(.spring(duration: 0.3)) {
                                showModelPicker.toggle()
                            }
                        } label: {
                            HStack {
                                Text(showModelPicker ? "Hide Models" : "Choose Different Model")
                                    .font(.caption)
                                Image(systemName: showModelPicker ? "chevron.up" : "chevron.down")
                                    .font(.caption2)
                            }
                            .foregroundStyle(.blue)
                        }
                        .buttonStyle(.plain)

                        Divider()

                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Model Cache Path")
                                    .font(.caption.bold())
                                if settings.customModelPath.isEmpty {
                                    Text("Default (~/.cache/huggingface/hub)")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                } else {
                                    Text(settings.customModelPath)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                }
                            }
                            Spacer()
                            Button("Choose…") {
                                let panel = NSOpenPanel()
                                panel.canChooseDirectories = true
                                panel.canChooseFiles = false
                                panel.allowsMultipleSelection = false
                                panel.message = "Select the folder containing your Hugging Face models"
                                if panel.runModal() == .OK, let url = panel.url {
                                    settings.customModelPath = url.path
                                    checkCache()
                                }
                            }
                            .controlSize(.small)
                            if !settings.customModelPath.isEmpty {
                                Button("Reset") {
                                    settings.customModelPath = ""
                                    checkCache()
                                }
                                .controlSize(.small)
                                .foregroundStyle(.red)
                            }
                        }
                    }
                    .padding(4)
                }

                // Download progress
                if case .downloading(let progress) = modelManager.downloadStatus {
                    VStack(spacing: 8) {
                        ProgressView(value: progress) {
                            Text("Downloading model…")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .progressViewStyle(.linear)

                        Text("\(Int(progress * 100))%")
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.tertiary)
                    }
                }

                if case .failed(let message) = modelManager.downloadStatus {
                    Label(message.localizedDescription, systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            .frame(maxWidth: 440)

            Spacer()
                .frame(height: 32)

            // Action buttons
            VStack(spacing: 12) {
                Button {
                    startDownload()
                } label: {
                    HStack(spacing: 8) {
                        if case .downloading = modelManager.downloadStatus {
                            ProgressView()
                                .controlSize(.small)
                            Text("Downloading…")
                        } else if isSelectedModelCached {
                            Image(systemName: "sparkles")
                            Text("Get Started")
                        } else {
                            Image(systemName: "arrow.down.circle.fill")
                            Text("Download & Get Started")
                        }
                    }
                    .frame(minWidth: 200)
                    .padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(isDownloading)
                .tint(isSelectedModelCached ? .green : .blue)

                if isSelectedModelCached {
                    Text("Model already downloaded — ready to go!")
                        .font(.caption2)
                        .foregroundStyle(.green.opacity(0.8))
                } else {
                    Text("The model will be stored locally on your Mac.\nNo internet needed after initial download.")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }
            }

            Spacer()
        }
        .padding(40)
        .frame(minWidth: 600, minHeight: 500)
    }
        .onAppear {
            checkCache()
        }
        .onChange(of: selectedModelInfo.id) {
            checkCache()
        }
    }

    private func checkCache() {
        isSelectedModelCached = ModelManager.isModelCached(
            modelId: selectedModelInfo.id,
            customPath: settings.customModelPath
        )
    }

    private var isDownloading: Bool {
        if case .downloading = modelManager.downloadStatus { return true }
        return false
    }

    private func startDownload() {
        settings.selectedModelId = selectedModelInfo.id

        // If already cached, skip straight to the app
        if isSelectedModelCached {
            withAnimation(.easeInOut(duration: 0.5)) {
                settings.hasCompletedOnboarding = true
                onComplete?()
            }
            return
        }

        Task {
            await modelManager.downloadModel(modelId: selectedModelInfo.id)
            if modelManager.isModelReady {
                withAnimation(.easeInOut(duration: 0.5)) {
                    settings.hasCompletedOnboarding = true
                    onComplete?()
                }
            }
        }
    }
}
