// Copyright © 2024 LocalImg. All rights reserved.

import Foundation
import Observation
import MLX
import StableDiffusion

enum DownloadStatus: Equatable {
    case idle
    case downloading(progress: Double)
    case completed
    case failed(Error)
    
    static func == (lhs: DownloadStatus, rhs: DownloadStatus) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle): return true
        case (.completed, .completed): return true
        case let (.downloading(p1), .downloading(p2)): return p1 == p2
        // Simple error equality check based on type
        case (.failed, .failed): return true 
        default: return false
        }
    }
}

@Observable
final class ModelManager {
    var downloadStatus: DownloadStatus = .idle
    var lastError: String?
    
    var isModelReady: Bool {
        if case .completed = downloadStatus { return true }
        return false
    }
    
    /// Default Hugging Face cache directory: ~/.cache/huggingface/hub
    static var defaultHFCacheDir: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".cache")
            .appendingPathComponent("huggingface")
            .appendingPathComponent("hub")
    }

    /// Check if model exists locally in the HF cache or an optional custom path.
    static func isModelCached(modelId: String, customPath: String? = nil) -> Bool {
        let repoId = modelId.replacingOccurrences(of: "/", with: "--")
        let folderName = "models--\(repoId)"

        // 1. Check standard HF cache (~/.cache/huggingface/hub/)
        let defaultDir = defaultHFCacheDir.appendingPathComponent(folderName)
        if FileManager.default.fileExists(atPath: defaultDir.path) {
            return true
        }

        // 2. Check custom path if provided
        if let custom = customPath, !custom.isEmpty {
            let customDir = URL(fileURLWithPath: custom)
                .appendingPathComponent(folderName)
            if FileManager.default.fileExists(atPath: customDir.path) {
                return true
            }
        }

        return false
    }

    @MainActor
    func downloadModel(modelId: String) async {
        guard downloadStatus != .downloading(progress: 0) else { return }
        
        downloadStatus = .downloading(progress: 0)
        lastError = nil
        
        do {
            // Initiate download via MLX StableDiffusionConfiguration
            let config: StableDiffusionConfiguration
            if modelId == "stabilityai/sdxl-turbo" {
                config = .presetSDXLTurbo
            } else if modelId == "stabilityai/stable-diffusion-2-1-base" {
                config = .presetStableDiffusion21Base
            } else {
                 config = .presetSDXLTurbo
            }
            
            try await config.download { progress in
                Task { @MainActor in
                    self.downloadStatus = .downloading(progress: progress.fractionCompleted)
                }
            }
            
            self.downloadStatus = .completed
            
        } catch {
            self.lastError = error.localizedDescription
            self.downloadStatus = .failed(error)
        }
    }
}
