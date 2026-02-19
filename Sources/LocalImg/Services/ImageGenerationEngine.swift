// Copyright © 2024 LocalImg. All rights reserved.

import CoreGraphics
import Foundation

/// Protocol abstracting the image generation engine.
/// Enables swapping backends (MLX, Core ML, etc.) in the future.
protocol ImageGenerationEngine: Sendable {
    /// Generate an image from the given parameters.
    /// - Parameters:
    ///   - parameters: The generation parameters
    ///   - onProgress: Callback for progress updates (title, currentStep, totalSteps)
    ///   - onPreviewImage: Callback with an intermediate decoded CGImage for live preview
    /// - Returns: The generated CGImage
    func generate(
        parameters: GenerationParameters,
        onProgress: @escaping @Sendable (String, Double, Double) -> Void,
        onPreviewImage: @escaping @Sendable (CGImage) -> Void
    ) async throws -> CGImage
}

extension ImageGenerationEngine {
    /// Backward-compatible overload without preview callback
    func generate(
        parameters: GenerationParameters,
        onProgress: @escaping @Sendable (String, Double, Double) -> Void
    ) async throws -> CGImage {
        try await generate(parameters: parameters, onProgress: onProgress, onPreviewImage: { _ in })
    }
}
