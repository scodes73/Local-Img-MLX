// Copyright © 2024 LocalImg. All rights reserved.

import SwiftUI
import AppKit

/// Zoomable image preview with context menu actions
struct ImagePreviewView: View {

    let image: CGImage
    var seed: UInt64 = 0
    var parameters: GenerationParameters = .init()
    var creationDate: Date? = nil

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0

    var body: some View {
        VStack(spacing: 0) {
            // Image
            ZoomableImageView(
                image: NSImage(cgImage: image, size: NSSize(width: CGFloat(image.width), height: CGFloat(image.height))),
                scale: $scale
            )
            .contextMenu {
                Button {
                    copyToClipboard()
                } label: {
                    Label("Copy Image", systemImage: "doc.on.doc")
                }
                
                Button {
                    saveAs()
                } label: {
                    Label("Save Image…", systemImage: "square.and.arrow.down")
                }
                
                Divider()
                
                if seed > 0 {
                    Button {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString("\(seed)", forType: .string)
                    } label: {
                        Label("Copy Seed: \(seed)", systemImage: "leaf")
                    }
                }
                
                if !parameters.prompt.isEmpty {
                    Button {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(parameters.prompt, forType: .string)
                    } label: {
                        Label("Copy Prompt", systemImage: "text.quote")
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Zoom controls
            HStack(spacing: 16) {
                Button {
                    withAnimation(.spring(duration: 0.2)) { scale = max(0.25, scale - 0.25) }
                } label: {
                    Image(systemName: "minus.magnifyingglass")
                }
                .buttonStyle(.plain)

                Text("\(Int(scale * 100))%")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .frame(width: 45)

                Button {
                    withAnimation(.spring(duration: 0.2)) { scale = min(4.0, scale + 0.25) }
                } label: {
                    Image(systemName: "plus.magnifyingglass")
                }
                .buttonStyle(.plain)

                Button {
                    withAnimation(.spring(duration: 0.2)) { scale = 1.0 }
                } label: {
                    Image(systemName: "1.magnifyingglass")
                }
                .buttonStyle(.plain)

                Spacer()

                // Image info
                Text("\(image.width)×\(image.height)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.bar)
            
            // Overlay Controls
            .overlay(alignment: .bottomTrailing) {
                HStack(spacing: 8) {
                    Button {
                        copyToClipboard()
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 14))
                            .frame(width: 32, height: 32)
                            .background(.thinMaterial, in: Circle())
                            .overlay(Circle().stroke(.white.opacity(0.2), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .help("Copy Image")

                    Button {
                        saveAs()
                    } label: {
                        Image(systemName: "square.and.arrow.down")
                            .font(.system(size: 14))
                            .frame(width: 32, height: 32)
                            .background(.thinMaterial, in: Circle())
                            .overlay(Circle().stroke(.white.opacity(0.2), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .help("Save Image")
                    
                    if !parameters.prompt.isEmpty {
                        Button {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(parameters.prompt, forType: .string)
                        } label: {
                            Image(systemName: "text.quote")
                                .font(.system(size: 14))
                                .frame(width: 32, height: 32)
                                .background(.thinMaterial, in: Circle())
                                .overlay(Circle().stroke(.white.opacity(0.2), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                        .help("Copy Prompt")
                    }
                }
                .padding(16)
                .padding(.bottom, 50) // Avoid overlapping zoom controls
            }
        }
    }

    private func copyToClipboard() {
        let nsImage = NSImage(cgImage: image, size: NSSize(width: CGFloat(image.width), height: CGFloat(image.height)))
        NSPasteboard.general.clearContents()
        NSPasteboard.general.writeObjects([nsImage])
    }

    private func saveAs() {
        let panel = NSSavePanel()
        
        // Determine file type (default to PNG if not specified in parameters)
        let isPng = parameters.outputFormat == .png
        panel.allowedContentTypes = [isPng ? .png : .jpeg]
        
        // Generate filename
        let dateToUse = creationDate ?? Date.now
        let dateStr = dateToUse.formatted(.dateTime.year().month().day().hour().minute().second())
        let filename = "localimg_\(dateStr)"
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
            
        panel.nameFieldStringValue = "\(filename).\(isPng ? "png" : "jpg")"
        panel.canCreateDirectories = true

        panel.begin { response in
            if response == .OK, let url = panel.url {
                let bitmapRep = NSBitmapImageRep(cgImage: image)
                let data = isPng
                    ? bitmapRep.representation(using: .png, properties: [:])
                    : bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: 0.9])
                try? data?.write(to: url)
            }
        }
    }
}
