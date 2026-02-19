// Copyright © 2024 LocalImg. All rights reserved.

import SwiftUI
import SwiftData

struct HistoryThumbnailView: View {
    let record: GenerationRecord
    let size: CGFloat
    
    @State private var thumbnail: NSImage?
    @State private var opacity: Double = 0
    
    var body: some View {
        ZStack {
            // Background / Placeholder
            Rectangle()
                .fill(.quaternary)
                .frame(height: size)
                .overlay {
                    if thumbnail == nil {
                        Image(systemName: "photo")
                            .foregroundStyle(.tertiary)
                    }
                }
            
            // Loaded Image
            if let thumbnail = thumbnail {
                Image(nsImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: size)
                    .clipped()
                    .opacity(opacity)
            }
        }
        .cornerRadius(8)
        .onAppear {
            load()
        }
        .onChange(of: record) { _, _ in
            load()
        }
    }
    
    private func load() {
        // Reset state for new load
        thumbnail = nil
        opacity = 0
        
        Task {
            // Calculate target size (we only need height, width depends on aspect ratio)
            // But for thumbnails in LazyVGrid/Stack we want to bound both dimensions to avoid huge memory usage
            // The gallery view uses height: 120, so let's aim for that + some buffer
            let targetSize = CGSize(width: size * 2, height: size * 2)
            
            // Extract data on Main Actor to be safe
            let id = String(describing: record.persistentModelID)
            let data = record.imageData
            
            if let image = await ThumbnailLoader.shared.loadThumbnail(id: id, data: data, size: targetSize) {
                await MainActor.run {
                    self.thumbnail = image
                    withAnimation(.easeIn(duration: 0.2)) {
                        self.opacity = 1
                    }
                }
            }
        }
    }
}
