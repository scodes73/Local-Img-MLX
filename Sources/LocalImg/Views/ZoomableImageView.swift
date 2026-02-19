// Copyright © 2024 LocalImg. All rights reserved.

import SwiftUI
import AppKit

struct ZoomableImageView: NSViewRepresentable {
    let image: NSImage
    @Binding var scale: CGFloat

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.allowsMagnification = true
        scrollView.minMagnification = 0.25
        scrollView.maxMagnification = 4.0
        scrollView.hasVerticalScroller = false
        scrollView.hasHorizontalScroller = false
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false
        scrollView.backgroundColor = .clear

        // Use custom clip view for centering
        let clipView = CenteringClipView()
        clipView.drawsBackground = false
        scrollView.contentView = clipView

        let imageView = NSImageView()
        imageView.image = image
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.animates = true
        imageView.frame = NSRect(origin: .zero, size: image.size)
        
        scrollView.documentView = imageView
        
        // Identifying the scroll view to the coordinator if needed,
        // or just setting up observation here.
        context.coordinator.setupObservation(scrollView)
        
        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let imageView = nsView.documentView as? NSImageView else { return }

        if imageView.image != image {
            imageView.image = image
            // Reset frame when image changes
            imageView.frame = NSRect(origin: .zero, size: image.size)
        }
        
        // Sync external scale changes to the scroll view
        if abs(nsView.magnification - scale) > 0.01 {
            nsView.magnification = scale
        }
        
        // Ensure the image view frame is correct
        if let image = imageView.image {
             if imageView.frame.size != image.size {
                 imageView.frame = NSRect(origin: .zero, size: image.size)
             }
        }
    }
    
    class Coordinator: NSObject {
        var parent: ZoomableImageView
        var observation: NSKeyValueObservation?
        
        init(_ parent: ZoomableImageView) {
            self.parent = parent
        }
        
        func setupObservation(_ scrollView: NSScrollView) {
            observation = scrollView.observe(\.magnification, options: [.new]) { [weak self] scrollView, change in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    self.parent.scale = scrollView.magnification
                }
            }
        }
    }
}

// Custom clip view to center the document view
private class CenteringClipView: NSClipView {
    override func constrainBoundsRect(_ proposedBounds: NSRect) -> NSRect {
        var rect = super.constrainBoundsRect(proposedBounds)
        
        if let documentView = documentView {
            if rect.size.width > documentView.frame.size.width {
                rect.origin.x = (documentView.frame.size.width - rect.size.width) / 2
            }
            
            if rect.size.height > documentView.frame.size.height {
                rect.origin.y = (documentView.frame.size.height - rect.size.height) / 2
            }
        }
        
        return rect
    }
}
