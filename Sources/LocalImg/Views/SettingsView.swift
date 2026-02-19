// Copyright © 2024 LocalImg. All rights reserved.

import SwiftUI

/// macOS Settings window with tabs for General, Model, Generation, and About
struct SettingsView: View {

    @Environment(AppSettings.self) private var settings
    @Environment(ModelManager.self) private var modelManager

    var body: some View {
        TabView {
            generalTab
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            modelTab
                .tabItem {
                    Label("Model", systemImage: "cpu")
                }

            generationTab
                .tabItem {
                    Label("Generation", systemImage: "paintbrush")
                }

            aboutTab
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 480, height: 360)
    }

    // MARK: - General Tab

    @ViewBuilder
    private var generalTab: some View {
        Form {
            Section("Output") {
                Picker("Default Format", selection: Binding(
                    get: { settings.defaultOutputFormat },
                    set: { settings.defaultOutputFormat = $0 }
                )) {
                    ForEach(OutputFormat.allCases) { format in
                        Text(format.rawValue).tag(format)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("Data") {
                Toggle("Always Show Onboarding", isOn: Binding(
                    get: { settings.alwaysShowOnboarding },
                    set: { settings.alwaysShowOnboarding = $0 }
                ))

                Button("Reset Onboarding") {
                    settings.hasCompletedOnboarding = false
                }
                .foregroundStyle(.red)

                Text("This will show the model download screen on next launch.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Model Cache Path") {
                HStack {
                    if settings.customModelPath.isEmpty {
                        Text("Default (~/.cache/huggingface/hub)")
                            .foregroundStyle(.secondary)
                    } else {
                        Text(settings.customModelPath)
                            .lineLimit(1)
                            .truncationMode(.middle)
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
                        }
                    }
                    if !settings.customModelPath.isEmpty {
                        Button("Reset") {
                            settings.customModelPath = ""
                        }
                        .foregroundStyle(.red)
                    }
                }

                Text("Point to a folder containing Hugging Face model directories (e.g. models--stabilityai--sdxl-turbo).")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    // MARK: - Model Tab

    @ViewBuilder
    private var modelTab: some View {
        Form {
            Section("Current Model") {
                LabeledContent("Name") {
                    Text(settings.selectedModel.name)
                }

                LabeledContent("ID") {
                    Text(settings.selectedModelId)
                        .font(.caption.monospaced())
                        .textSelection(.enabled)
                }

                LabeledContent("Size") {
                    Text("~\(String(format: "%.1f", settings.selectedModel.estimatedSizeGB)) GB")
                }

                LabeledContent("Negative Prompt") {
                    Text(settings.selectedModel.supportsNegativePrompt ? "Supported" : "Not supported")
                        .foregroundStyle(
                            settings.selectedModel.supportsNegativePrompt ? .green : .secondary
                        )
                }
            }

            Section("Change Model") {
                Picker("Model", selection: Binding(
                    get: { settings.selectedModelId },
                    set: { settings.selectedModelId = $0 }
                )) {
                    ForEach(ModelInfo.availableModels) { model in
                        Text(model.name).tag(model.id)
                    }
                }

                // Download button for the selected model
                Button("Download Selected Model") {
                    Task {
                        await modelManager.downloadModel(modelId: settings.selectedModelId)
                    }
                }
                .disabled(modelManager.downloadStatus == .downloading(progress: 0))

                if case .downloading(let progress) = modelManager.downloadStatus {
                    ProgressView(value: progress)
                        .progressViewStyle(.linear)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    // MARK: - Generation Tab

    @ViewBuilder
    private var generationTab: some View {
        Form {
            Section("Default Parameters") {
                HStack {
                    Text("Steps")
                    Spacer()
                    Stepper(
                        "\(settings.defaultSteps)",
                        value: Binding(
                            get: { settings.defaultSteps },
                            set: { settings.defaultSteps = $0 }
                        ),
                        in: 1...50
                    )
                }

                HStack {
                    Text("Guidance Scale")
                    Spacer()
                    Text(String(format: "%.1f", settings.defaultGuidance))
                        .font(.body.monospacedDigit())
                    Slider(
                        value: Binding(
                            get: { settings.defaultGuidance },
                            set: { settings.defaultGuidance = $0 }
                        ),
                        in: 0...20,
                        step: 0.5
                    )
                    .frame(maxWidth: 200)
                }
            }

            Section("Default Image Size") {
                Picker("Width", selection: Binding(
                    get: { settings.defaultWidth },
                    set: { settings.defaultWidth = $0 }
                )) {
                    ForEach(ImageDimension.allCases) { dim in
                        Text(dim.label).tag(dim.rawValue)
                    }
                }

                Picker("Height", selection: Binding(
                    get: { settings.defaultHeight },
                    set: { settings.defaultHeight = $0 }
                )) {
                    ForEach(ImageDimension.allCases) { dim in
                        Text(dim.label).tag(dim.rawValue)
                    }
                }
            }

            Section {
                Button("Reset to Model Defaults") {
                    settings.defaultSteps = settings.selectedModel.defaultSteps
                    settings.defaultGuidance = settings.selectedModel.defaultGuidanceScale
                    settings.defaultWidth = ImageDimension.medium.rawValue
                    settings.defaultHeight = ImageDimension.medium.rawValue
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    // MARK: - About Tab

    @ViewBuilder
    private var aboutTab: some View {
        VStack(spacing: 20) {
            Image(systemName: "paintbrush.pointed.fill")
                .font(.system(size: 48))
                .foregroundStyle(
                    .linearGradient(
                        colors: [.purple, .blue, .cyan],
                        startPoint: UnitPoint.topLeading,
                        endPoint: UnitPoint.bottomTrailing
                    )
                )

            Text("LocalImg")
                .font(.title.bold())

            Text("Version 1.0.0")
                .font(.caption)
                .foregroundStyle(.secondary)

            Divider()
                .frame(maxWidth: 200)

            VStack(spacing: 8) {
                Text("Generate images locally using AI")
                    .font(.body)
                Text("Powered by MLX on Apple Silicon")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("No cloud. No API keys. 100% private.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Spacer()
        }
        .padding(30)
    }
}
