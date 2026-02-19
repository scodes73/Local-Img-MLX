// Copyright © 2024 LocalImg. All rights reserved.

import Foundation

/// Metadata for a specific Stable Diffusion model
struct ModelInfo: Identifiable, Hashable, Codable, Sendable {
    let id: String
    let name: String
    let description: String
    let estimatedSizeGB: Double
    let supportsNegativePrompt: Bool
    let defaultSteps: Int
    let defaultGuidanceScale: Float

    // Common presets
    static let sdxlTurbo = ModelInfo(
        id: "stabilityai/sdxl-turbo",
        name: "SDXL Turbo",
        description: "Fast generation (4 steps). High quality.",
        estimatedSizeGB: 6.0,
        supportsNegativePrompt: false,
        defaultSteps: 4,
        defaultGuidanceScale: 0.0
    )

    static let stableDiffusion21Base = ModelInfo(
        id: "stabilityai/stable-diffusion-2-1-base",
        name: "Stable Diffusion 2.1 Base",
        description: "Standard 512x512 model. Good balance.",
        estimatedSizeGB: 3.5,
        supportsNegativePrompt: true,
        defaultSteps: 25,
        defaultGuidanceScale: 7.5
    )

    static let availableModels: [ModelInfo] = [
        .sdxlTurbo,
        .stableDiffusion21Base
    ]
}
