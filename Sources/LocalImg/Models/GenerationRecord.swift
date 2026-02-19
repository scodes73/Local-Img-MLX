// Copyright © 2024 LocalImg. All rights reserved.

import Foundation
import SwiftData

/// Persistent record of a generated image
@Model
final class GenerationRecord {
    var prompt: String
    var negativePrompt: String
    var steps: Int
    var guidanceScale: Float
    var seed: UInt64
    var width: Int
    var height: Int
    @Attribute(.externalStorage) var imageData: Data
    var createdAt: Date
    var modelId: String
    var outputFormat: String

    init(
        prompt: String,
        negativePrompt: String = "",
        steps: Int,
        guidanceScale: Float,
        seed: UInt64,
        width: Int,
        height: Int,
        imageData: Data,
        createdAt: Date = .now,
        modelId: String,
        outputFormat: String = "png"
    ) {
        self.prompt = prompt
        self.negativePrompt = negativePrompt
        self.steps = steps
        self.guidanceScale = guidanceScale
        self.seed = seed
        self.width = width
        self.height = height
        self.imageData = imageData
        self.createdAt = createdAt
        self.modelId = modelId
        self.outputFormat = outputFormat
    }
}
