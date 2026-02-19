// Copyright © 2024 LocalImg. All rights reserved.

import Foundation
import SwiftData

/// Manages CRUD operations for generation history via SwiftData
@Observable @MainActor
final class HistoryManager {

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// Save a generation record
    func save(
        parameters: GenerationParameters,
        imageData: Data,
        seed: UInt64,
        modelId: String
    ) {
        let record = GenerationRecord(
            prompt: parameters.prompt,
            negativePrompt: parameters.negativePrompt,
            steps: parameters.steps,
            guidanceScale: parameters.guidanceScale,
            seed: seed,
            width: parameters.width,
            height: parameters.height,
            imageData: imageData,
            modelId: modelId,
            outputFormat: parameters.outputFormat.rawValue
        )
        modelContext.insert(record)
        try? modelContext.save()
    }

    /// Fetch all records sorted by creation date (newest first)
    func fetchAll() -> [GenerationRecord] {
        let descriptor = FetchDescriptor<GenerationRecord>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    /// Delete a specific record
    func delete(_ record: GenerationRecord) {
        modelContext.delete(record)
        try? modelContext.save()
    }

    /// Delete all records
    func deleteAll() {
        let records = fetchAll()
        for record in records {
            modelContext.delete(record)
        }
        try? modelContext.save()
    }
}
