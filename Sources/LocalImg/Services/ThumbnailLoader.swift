// Copyright © 2024 LocalImg. All rights reserved.

import AppKit
import Foundation
import ImageIO
import SwiftData

/// Handles asynchronous loading and caching of thumbnails
@MainActor
final class ThumbnailLoader: ObservableObject {
    
    static let shared = ThumbnailLoader()
    
    private let cache = NSCache<NSString, NSImage>()
    private let queue = DispatchQueue(label: "com.localimg.thumbnails", qos: .userInteractive)
    
    private init() {
        cache.countLimit = 100 // Keep up to 100 thumbnails in memory
        cache.totalCostLimit = 50 * 1024 * 1024 // 50 MB limit
    }
    
    func loadThumbnail(id: String, data: Data, size: CGSize) async -> NSImage? {
        let key = NSString(string: "\(id)_\(Int(size.width))x\(Int(size.height))")
        
        // 1. Check memory cache
        if let cached = cache.object(forKey: key) {
            return cached
        }
        
        // 2. Decode and resize in background
        return await withCheckedContinuation { continuation in
            queue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(returning: nil)
                    return
                }
                
                // Decode data
                guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
                    continuation.resume(returning: nil)
                    return
                }
                
                // Calculate target size (max dimension)
                let maxDimension = max(size.width, size.height)
                
                // Downsample options
                let options: [CFString: Any] = [
                    kCGImageSourceCreateThumbnailFromImageAlways: true,
                    kCGImageSourceThumbnailMaxPixelSize: maxDimension * 2 // *2 for Retina
                ]
                
                if let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) {
                    let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width / 2, height: cgImage.height / 2))
                    
                    // Cache the result
                    self.cache.setObject(nsImage, forKey: key)
                    
                    continuation.resume(returning: nsImage)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }
    
    func clearCache() {
        cache.removeAllObjects()
    }
}
