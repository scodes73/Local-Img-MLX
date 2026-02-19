// Copyright © 2024 LocalImg. All rights reserved.

import CoreGraphics
import Foundation
import MLX
import StableDiffusion

/// MLX-based Stable Diffusion engine implementing the ImageGenerationEngine protocol.
/// Wraps the MLX StableDiffusion library for on-device image generation.
final class MLXDiffusionEngine: @unchecked Sendable {

    /// The Stable Diffusion configuration to use
    private var sdConfiguration: StableDiffusionConfiguration
    private var loadConfiguration: LoadConfiguration
    private let conserveMemory: Bool

    init(modelId: String = "stabilityai/sdxl-turbo") {
        // Select the configuration based on model ID
        switch modelId {
        case "stabilityai/sdxl-turbo":
            self.sdConfiguration = .presetSDXLTurbo
        case "stabilityai/stable-diffusion-2-1-base":
            self.sdConfiguration = .presetStableDiffusion21Base
        default:
            self.sdConfiguration = .presetSDXLTurbo
        }

        // Configure memory based on system RAM
        self.conserveMemory = Memory.memoryLimit < 8 * 1024 * 1024 * 1024
        self.loadConfiguration = LoadConfiguration(float16: true, quantize: conserveMemory)

        // Set memory limits
        if conserveMemory {
            Memory.cacheLimit = 1 * 1024 * 1024
            Memory.memoryLimit = 3 * 1024 * 1024 * 1024
        } else {
            Memory.cacheLimit = 256 * 1024 * 1024
        }
    }

    /// Download the model files if needed
    func downloadModel(
        onProgress: @escaping @Sendable (Double) -> Void
    ) async throws {
        try await sdConfiguration.download { progress in
            onProgress(progress.fractionCompleted)
        }
    }

    /// Check if the model is already downloaded
    func isModelDownloaded() -> Bool {
        // The HuggingFace Hub caches downloads. We attempt a quick check
        // by seeing if the configuration's local files exist.
        // A simple heuristic: try to create the model — if it fails with a
        // file-not-found type error, it's not downloaded.
        // For now, we rely on the download() call being a no-op if cached.
        return false  // Conservative: always check on launch
    }
}

// MARK: - ImageGenerationEngine

extension MLXDiffusionEngine: ImageGenerationEngine {

    func generate(
        parameters: GenerationParameters,
        onProgress: @escaping @Sendable (String, Double, Double) -> Void,
        onPreviewImage: @escaping @Sendable (CGImage) -> Void
    ) async throws -> CGImage {

        // Only download if the model is not already cached
        if !ModelManager.isModelCached(modelId: sdConfiguration.id) {
            try await downloadModel { fraction in
                if fraction < 0.99 {
                    onProgress("Downloading model", fraction * 100, 100)
                }
            }
        }

        // Create the model container
        let container = try ModelContainer<TextToImageGenerator>.createTextToImageGenerator(
            configuration: sdConfiguration, loadConfiguration: loadConfiguration)

        await container.setConserveMemory(conserveMemory)

        // Load model weights
        try await container.perform { model in
            onProgress("Loading model", 0, 1)
            if !self.conserveMemory {
                model.ensureLoaded()
            }
        }

        // Build the MLX EvaluateParameters from our app parameters
        var evalParams = sdConfiguration.defaultParameters()
        evalParams.prompt = parameters.prompt
        evalParams.negativePrompt = parameters.negativePrompt
        evalParams.steps = parameters.steps
        evalParams.cfgWeight = parameters.guidanceScale
        evalParams.seed = parameters.effectiveSeed
        evalParams.imageCount = parameters.imageCount
        evalParams.latentSize = [parameters.height / 8, parameters.width / 8]

        // Copy to a let for Sendable closure capture
        let capturedParams = evalParams

        // Determine preview intervals — show ~4 previews during generation
        let totalSteps = parameters.steps
        let previewInterval = max(1, totalSteps / 4)

        // Generate the image using the two-stage process
        let cgImage: CGImage = try await container.performTwoStage { generator in
            let latents = generator.generateLatents(parameters: capturedParams)
            return (generator.detachedDecoder(), latents)
        } second: { (pair: (ImageDecoder, DenoiseIterator)) in
            let (decoder, latents) = pair
            var lastXt: MLXArray?

            for (i, xt) in latents.enumerated() {
                lastXt = nil
                eval(xt)
                lastXt = xt
                let step = i + 1
                onProgress("Generating", Double(step), Double(totalSteps))

                // Decode intermediate latent for live preview at intervals
                // Skip the very last step since we'll decode it as the final image
                if step % previewInterval == 0 && step < totalSteps {
                    let preview = decoder(xt)
                    let raster = (preview * 255).asType(.uint8).squeezed()
                    let previewImage = MLXImage(raster).asCGImage()
                    onPreviewImage(previewImage)
                }
            }

            guard let finalXt = lastXt else {
                throw MLXDiffusionError.generationFailed
            }

            // Decode the latent to an image
            let decoded = decoder(finalXt)
            let raster = (decoded * 255).asType(.uint8).squeezed()
            let image = MLXImage(raster).asCGImage()
            return image
        }

        return cgImage
    }
}

// MARK: - Errors

enum MLXDiffusionError: LocalizedError {
    case generationFailed
    case imageConversionFailed
    case modelNotAvailable

    var errorDescription: String? {
        switch self {
        case .generationFailed:
            return "Image generation failed. No output was produced."
        case .imageConversionFailed:
            return "Failed to convert the generated data into an image."
        case .modelNotAvailable:
            return "The selected model is not available. Please download it first."
        }
    }
}
