// Copyright © 2024 LocalImg. All rights reserved.

import AppKit
import SwiftUI

/// Core generation workspace — prompt input, controls, image preview
struct GenerationView: View {

    @Environment(AppSettings.self) private var settings
    @Environment(ModelManager.self) private var modelManager

    var historyManager: HistoryManager?
    @Binding var selectedRecord: GenerationRecord?

    @State private var parameters = GenerationParameters()
    @State private var generatedImage: CGImage?
    @State private var isGenerating = false
    @State private var progressTitle = ""
    @State private var progressCurrent: Double = 0
    @State private var progressTotal: Double = 1
    @State private var errorMessage: String?
    @State private var showAdvanced = false
    @State private var lastUsedSeed: UInt64 = 0
    @State private var previewImage: CGImage?

    private let engine = MLXDiffusionEngine()

    var body: some View {
        VStack(spacing: 0) {
            // Image preview area
            imagePreview
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            // Controls area
            controlsArea
                .padding(16)
        }
        .onAppear {
            parameters = settings.defaultParameters()
        }
        .onChange(of: selectedRecord) { _, newValue in
            if newValue != nil {
                generatedImage = nil
                previewImage = nil
            }
        }
    }

    // MARK: - Image Preview

    @ViewBuilder
    private var imagePreview: some View {
        ZStack {
            // Background
            Rectangle()
                .fill(.black.opacity(0.03))

            if let record = selectedRecord {
                // History detail view
                historyDetailView(record)
            } else if let image = generatedImage {
                ImagePreviewView(image: image, seed: lastUsedSeed, parameters: parameters)
            } else if isGenerating {
                generatingOverlay
            } else {
                emptyState
            }
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        ZStack {
            LiquidGlassView(opacity: 0.4)
            
            VStack(spacing: 20) {
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 64))
                    .foregroundStyle(.white)
                    .shadow(color: .purple.opacity(0.5), radius: 10)
                
                Text("Type a prompt and hit Generate")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                    .shadow(radius: 2)
                
                Text("⌘↵ to generate")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial, in: Capsule())
            }
            .padding()
        }
        .drawingGroup() // Composite the liquid glass + text layers
    }

    // MARK: - Generating Overlay (Rich Animation)

    @ViewBuilder
    private var generatingOverlay: some View {
        let progress = progressTotal > 0 ? progressCurrent / progressTotal : 0

        ZStack {
            // Live preview image (progressive denoising)
            if let preview = previewImage {
                SwiftUI.Image(preview, scale: 1.0, label: Text("Preview"))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .opacity(0.6)
                    .blur(radius: 2)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.5), value: previewImage == nil)
            }

            VStack(spacing: 30) {
                // Simple Progress Bar
                ProgressView(value: progressCurrent, total: progressTotal)
                    .progressViewStyle(.linear)
                    .padding(.horizontal, 20)
                
                // Status text
                VStack(spacing: 6) {
                    Text(progressTitle.isEmpty ? "Loading..." : progressTitle)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    
                    Text("\(Int(progress * 100))% — Step \(Int(progressCurrent)) of \(Int(progressTotal))")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .frame(width: 200) // Fixed width for text stability
                }
            }
            .padding(40)
            .frame(width: 300) // Fixed width to prevent jitter
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - History Detail View

    @ViewBuilder
    private func historyDetailView(_ record: GenerationRecord) -> some View {
        VStack(spacing: 0) {
            // Image
                if let nsImage = NSImage(data: record.imageData),
                   let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) {
                    
                    // Reconstruct parameters for the preview view
                    let params = GenerationParameters(
                        prompt: record.prompt,
                        negativePrompt: record.negativePrompt,
                        steps: record.steps,
                        guidanceScale: record.guidanceScale,
                        seed: record.seed,

                        width: record.width,
                        height: record.height,
                        outputFormat: OutputFormat(rawValue: record.outputFormat) ?? .png,
                        useRandomSeed: false
                    )

                    ImagePreviewView(
                        image: cgImage,
                        seed: record.seed,
                        parameters: params,
                        creationDate: record.createdAt
                    )
                } else {
                emptyState
            }

            Divider()

            // Detail info panel
            historyInfoPanel(record)
        }
    }

    @ViewBuilder
    private func historyInfoPanel(_ record: GenerationRecord) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 10) {
                // Header with back button
                HStack {
                    Label("Generation Details", systemImage: "info.circle.fill")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button {
                        withAnimation(.spring(duration: 0.25)) {
                            selectedRecord = nil
                        }
                    } label: {
                        Label("Back", systemImage: "xmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }

                // Prompt
                detailRow(label: "Prompt", value: record.prompt, isMultiline: true)

                // Negative prompt
                if !record.negativePrompt.isEmpty {
                    detailRow(label: "Negative", value: record.negativePrompt, isMultiline: true)
                }

                Divider()

                // Parameters grid
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12),
                ], spacing: 8) {
                    detailChip(label: "Model", value: shortModelName(record.modelId))
                    detailChip(label: "Steps", value: "\(record.steps)")
                    detailChip(label: "Guidance", value: String(format: "%.1f", record.guidanceScale))
                    detailChip(label: "Seed", value: "\(record.seed)")
                    detailChip(label: "Size", value: "\(record.width)×\(record.height)")
                    detailChip(label: "Format", value: record.outputFormat.uppercased())
                }

                // Date
                HStack {
                    Spacer()
                    Text(record.createdAt.formatted(.dateTime.year().month().day().hour().minute()))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(12)
        }
        .frame(maxHeight: 180)
        .background(.bar)
    }

    @ViewBuilder
    private func detailRow(label: String, value: String, isMultiline: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2.bold())
                .foregroundStyle(.tertiary)
            Text(value)
                .font(.caption)
                .foregroundStyle(.primary)
                .textSelection(.enabled)
                .lineLimit(isMultiline ? nil : 1)
        }
    }

    @ViewBuilder
    private func detailChip(label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.tertiary)
                .textCase(.uppercase)
            Text(value)
                .font(.caption.monospacedDigit())
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 6))
    }

    private func shortModelName(_ modelId: String) -> String {
        // Extract a short name from model ID like "mlx-community/stable-diffusion..."
        let parts = modelId.split(separator: "/")
        return String(parts.last ?? Substring(modelId)).replacingOccurrences(of: "-mlx", with: "")
    }

    // MARK: - Controls

    @ViewBuilder
    private var controlsArea: some View {
        VStack(spacing: 12) {
            // Prompt input
            HStack(spacing: 10) {
                TextField("Describe the image you want to create…", text: $parameters.prompt, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(.body)
                    .lineLimit(1...3)
                    .padding(10)
                    .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 10))
                    .onSubmit {
                        if NSEvent.modifierFlags.contains(.command) {
                            generate()
                        }
                    }

                Button(action: generate) {
                    Image(systemName: "paintbrush.fill")
                        .font(.title3)
                        .frame(width: 40, height: 36)
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .disabled(parameters.prompt.isEmpty || isGenerating)
                .keyboardShortcut(.return, modifiers: .command)
            }

            // Advanced toggle + settings
            HStack {
                Button {
                    withAnimation(.spring(duration: 0.25)) {
                        showAdvanced.toggle()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: showAdvanced ? "chevron.down" : "chevron.right")
                            .font(.caption2.bold())
                        Text("Advanced")
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)

                Spacer()

                if let errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.red)
                        .lineLimit(1)
                }

                // if generatedImage != nil {
                //     Button("Save Image…") {
                //         saveImage()
                //     }
                //     .controlSize(.small)
                // }
            }

            // Advanced controls
            if showAdvanced {
                advancedControls
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    @ViewBuilder
    private var advancedControls: some View {
        GroupBox {
            VStack(spacing: 10) {
                // Negative prompt
                if settings.selectedModel.supportsNegativePrompt {
                    HStack {
                        Text("Negative Prompt")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(width: 110, alignment: .trailing)
                        TextField("Things to avoid…", text: $parameters.negativePrompt)
                            .textFieldStyle(.roundedBorder)
                            .font(.caption)
                    }
                }

                HStack(spacing: 20) {
                    // Steps
                    HStack {
                        Text("Steps")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(width: 110, alignment: .trailing)
                        Slider(value: .init(
                            get: { Double(parameters.steps) },
                            set: { parameters.steps = Int($0) }
                        ), in: 1...50, step: 1) 
                        .frame(maxWidth: 150)
                        Text("\(parameters.steps)")
                            .font(.caption.monospacedDigit())
                            .frame(width: 30)
                    }

                    // Guidance Scale
                    HStack {
                        Text("Guidance")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Slider(value: $parameters.guidanceScale, in: 0...20, step: 0.5) {

                        }
                        .frame(maxWidth: 150)
                        Text(String(format: "%.1f", parameters.guidanceScale))
                            .font(.caption.monospacedDigit())
                            .frame(width: 35)
                    }
                }

                HStack(spacing: 20) {
                    // Seed
                    HStack {
						Text("Seed")
							.font(.caption)
							.foregroundStyle(.secondary)
							.frame(width: 110, alignment: .trailing)

						if parameters.useRandomSeed {
							Button(action: {
								parameters.useRandomSeed = false
								parameters.seed = UInt64.random(in: 0...UInt64.max)
							}) {
								HStack {
									Image(systemName: "dice.fill")
									Text("Random")
								}
								.font(.caption)
								.foregroundColor(.secondary)
								.padding(4)
								.background(
									RoundedRectangle(cornerRadius: 6)
										.fill(Color.secondary.opacity(0.1))
								)
							}
							.buttonStyle(.plain)
							.help("Click to use a fixed seed")
						} else {
							HStack(spacing: 8) {
								TextField(
									"Seed",
									value: $parameters.seed,
									format: .number.grouping(.never)
								)
								.textFieldStyle(.roundedBorder)
								.font(.caption.monospacedDigit())
								.frame(width: 100)

								Button(action: {
									parameters.seed = UInt64.random(in: 0...UInt64.max)
								}) {
									Image(systemName: "dice")
										.font(.caption)
								}
								.buttonStyle(.plain)
								.help("Generate new random seed")

								Button(action: {
									parameters.useRandomSeed = true
								}) {
									Image(systemName: "arrow.uturn.backward.circle")
										.font(.caption)
										.foregroundStyle(.secondary)
								}
								.buttonStyle(.plain)
								.help("Switch back to random seed")
							}
						}
                    }

                    // Dimensions
                    HStack {
                        Text("Size")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        TextField("W", value: $parameters.width, format: .number.grouping(.never))
                            .textFieldStyle(.roundedBorder)
                            .font(.caption.monospacedDigit())
                            .frame(width: 50)

                        Text("×")
                            .foregroundStyle(.secondary)
                            .font(.caption)

                        TextField("H", value: $parameters.height, format: .number.grouping(.never))
                            .textFieldStyle(.roundedBorder)
                            .font(.caption.monospacedDigit())
                            .frame(width: 50)
                        
                        Menu {
                            ForEach(ImageDimension.allCases) { dim in
                                Button("\(dim.label) (\(dim.rawValue)×\(dim.rawValue))") {
                                    parameters.width = dim.rawValue
                                    parameters.height = dim.rawValue
                                }
                            }
                        } label: {
                            Image(systemName: "list.bullet")
                                .font(.caption)
                        }
                        .menuStyle(.borderlessButton)
                        .frame(width: 20)
                    }
                }

                // Output format
                HStack {
                    Text("Format")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 110, alignment: .trailing)
                    Picker("Format", selection: $parameters.outputFormat) {
                        ForEach(OutputFormat.allCases) { format in
                            Text(format.rawValue).tag(format)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 150)
                    Spacer()
                }
            }
            .padding(4)
        }
    }

    // MARK: - Actions

    private func generate() {
        guard !parameters.prompt.isEmpty, !isGenerating else { return }

        // Clear history selection when starting new generation
        selectedRecord = nil

        isGenerating = true
        errorMessage = nil
        previewImage = nil
        generatedImage = nil
        progressTitle = "Preparing…"
        progressCurrent = 0
        progressTotal = Double(parameters.steps)

        let currentParams = parameters
        
        // Ensure dimensions are multiples of 64 to prevent MLX shape errors
        var correctedParams = currentParams
        correctedParams.width = (max(64, correctedParams.width) / 64) * 64
        correctedParams.height = (max(64, correctedParams.height) / 64) * 64
        
        // Update UI if changed
        if correctedParams.width != parameters.width || correctedParams.height != parameters.height {
            parameters.width = correctedParams.width
            parameters.height = correctedParams.height
        }

        Task {
            do {
                let engine = MLXDiffusionEngine(modelId: settings.selectedModelId)
                let seed = correctedParams.effectiveSeed
                lastUsedSeed = seed
                
                var genParams = correctedParams
                genParams.seed = seed
                genParams.useRandomSeed = false  // Use the locked seed

                let image = try await engine.generate(
                    parameters: genParams,
                    onProgress: { title, current, total in
                        Task { @MainActor in
                            progressTitle = title
                            progressCurrent = current
                            progressTotal = total
                        }
                    },
                    onPreviewImage: { preview in
                        Task { @MainActor in
                            withAnimation(.easeInOut(duration: 0.4)) {
                                previewImage = preview
                            }
                        }
                    }
                )

                await MainActor.run {
                    generatedImage = image
                    isGenerating = false

                    // Save to history
                    if let imageData = cgImageToData(image, format: currentParams.outputFormat) {
                        historyManager?.save(
                            parameters: currentParams,
                            imageData: imageData,
                            seed: seed,
                            modelId: settings.selectedModelId
                        )
                    }
                }
            } catch {
                await MainActor.run {
                    isGenerating = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func saveImage() {
        guard let image = generatedImage else { return }

        let panel = NSSavePanel()
        panel.allowedContentTypes = [
            parameters.outputFormat == .png
                ? .png
                : .jpeg
        ]
        panel.nameFieldStringValue = "localimg_\(Date.now.formatted(.dateTime.year().month().day().hour().minute().second()))"
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
            + ".\(parameters.outputFormat.fileExtension)"
        panel.canCreateDirectories = true

        panel.begin { response in
            if response == .OK, let url = panel.url {
                if let data = cgImageToData(image, format: parameters.outputFormat) {
                    try? data.write(to: url)
                }
            }
        }
    }

    private func saveRecordImage(_ record: GenerationRecord, image: NSImage) {
        let panel = NSSavePanel()
        
        // Determine file type from record or default to PNG
        let isPng = record.outputFormat == "png"
        panel.allowedContentTypes = [isPng ? .png : .jpeg]
        
        // Create filename from date
        let dateStr = record.createdAt.formatted(.dateTime.year().month().day().hour().minute().second())
        let filename = "localimg_\(dateStr)"
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
        
        panel.nameFieldStringValue = "\(filename).\(isPng ? "png" : "jpg")"
        panel.canCreateDirectories = true

        panel.begin { response in
            if response == .OK, let url = panel.url {
                 // Convert NSImage to Data
                guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return }
                let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
                let data: Data?
                
                if isPng {
                    data = bitmapRep.representation(using: .png, properties: [:])
                } else {
                    data = bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: 0.9])
                }
                
                if let data {
                    try? data.write(to: url)
                }
            }
        }
    }
}

// MARK: - Helpers

private func cgImageToData(_ image: CGImage, format: OutputFormat) -> Data? {
    let bitmapRep = NSBitmapImageRep(cgImage: image)

    switch format {
    case .png:
        return bitmapRep.representation(using: .png, properties: [:])
    case .jpeg:
        return bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: 0.9])
    }
}



// MARK: - Shimmer Effect

extension View {
    func shimmering(duration: Double = 1.5) -> some View {
        modifier(Shimmer(duration: duration))
    }
}

struct Shimmer: ViewModifier {
    let duration: Double
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .mask(
                LinearGradient(
                    stops: [
                        .init(color: .black.opacity(0.3), location: phase),
                        .init(color: .black, location: phase + 0.1),
                        .init(color: .black.opacity(0.3), location: phase + 0.2)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .onAppear {
                withAnimation(.linear(duration: duration).repeatForever(autoreverses: false)) {
                    phase = 1.2
                }
            }
    }
}
