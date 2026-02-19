// Copyright © 2024 LocalImg. All rights reserved.

import Foundation

/// Output image format options
enum OutputFormat: String, Codable, CaseIterable, Identifiable {
    case png = "PNG"
    case jpeg = "JPEG"

    var id: String { rawValue }

    var fileExtension: String {
        switch self {
        case .png: return "png"
        case .jpeg: return "jpg"
        }
    }

    var utType: String {
        switch self {
        case .png: return "public.png"
        case .jpeg: return "public.jpeg"
        }
    }
}

/// Image dimension presets
enum ImageDimension: Int, Codable, CaseIterable, Identifiable {
    case small = 256
    case medium = 512
    case large = 768
    case xlarge = 1024

    var id: Int { rawValue }

    var label: String {
        "\(rawValue)"
    }

    /// The latent size for this dimension (image size / 8)
    var latentSize: Int {
        rawValue / 8
    }
}

/// App-level parameters for image generation
struct GenerationParameters: Codable, Equatable {
    var prompt: String = ""
    var negativePrompt: String = ""
    var steps: Int = 4
    var guidanceScale: Float = 0.0
    var seed: UInt64 = 0
    var width: Int = 1024
    var height: Int = 768
    var imageCount: Int = 1
    var outputFormat: OutputFormat = .png

    /// Whether to use a random seed
    var useRandomSeed: Bool = true

    /// Generate the actual seed to use (random if useRandomSeed is true)
    var effectiveSeed: UInt64 {
        useRandomSeed ? UInt64.random(in: 0...UInt64.max) : seed
    }
}
