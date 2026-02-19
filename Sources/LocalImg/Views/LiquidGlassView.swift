// Copyright © 2024 LocalImg. All rights reserved.

import SwiftUI

/// A native "Liquid Glass" background effect using Canvas and blurred colorful blobs.
/// Features smooth, continuous animation that pauses when not visible to save energy.
struct LiquidGlassView: View {
    
    // Configuration properties
    var colors: [Color] = [
        .purple, .blue, .cyan, .indigo, .mint
    ]
    var speed: Double = 1.0
    var blurRadius: CGFloat = 60
    var opacity: Double = 0.5
    
    @State private var start = Date.now
    
    var body: some View {
        ZStack {
            // Fluid animated background
            TimelineView(.animation) { timeline in
                let time = start.distance(to: timeline.date) * speed
                
                Canvas { context, size in
                    // Draw blobs
                    let w = size.width
                    let h = size.height
                    let minDim = min(w, h)
                    
                    // Blob 1: Moving circular path
                    context.drawLayer { ctx in
                        let x = w * (0.5 + 0.3 * sin(time * 0.4))
                        let y = h * (0.5 + 0.2 * cos(time * 0.5))
                        let rect = CGRect(
                            x: x - minDim * 0.3,
                            y: y - minDim * 0.3,
                            width: minDim * 0.6,
                            height: minDim * 0.6
                        )
                        ctx.fill(
                            Path(ellipseIn: rect),
                            with: .color(colors[0].opacity(opacity))
                        )
                    }
                    
                    // Blob 2: Counter-movement
                    context.drawLayer { ctx in
                        let x = w * (0.5 + 0.2 * sin(time * 0.6 + 2.0))
                        let y = h * (0.5 + 0.3 * cos(time * 0.4 + 1.0))
                        let rect = CGRect(
                            x: x - minDim * 0.35,
                            y: y - minDim * 0.35,
                            width: minDim * 0.7,
                            height: minDim * 0.7
                        )
                        ctx.fill(
                            Path(ellipseIn: rect),
                            with: .color(colors[1].opacity(opacity))
                        )
                    }
                    
                    // Blob 3: Slower, larger background blob
                    context.drawLayer { ctx in
                        let x = w * (0.5 + 0.1 * sin(time * 0.2 + 4.0))
                        let y = h * (0.5 + 0.1 * cos(time * 0.3 + 3.0))
                        let rect = CGRect(
                            x: x - minDim * 0.4,
                            y: y - minDim * 0.4,
                            width: minDim * 0.8,
                            height: minDim * 0.8
                        )
                        ctx.fill(
                            Path(ellipseIn: rect),
                            with: .color(colors[2].opacity(opacity * 0.6))
                        )
                    }
                    
                    // Add more complexity if we have more colors
                    if colors.count > 3 {
                         context.drawLayer { ctx in
                             let x = w * (0.2 + 0.6 * abs(sin(time * 0.3)))
                             let y = h * (0.2 + 0.6 * abs(cos(time * 0.3)))
                             let rect = CGRect(
                                 x: x - minDim * 0.25,
                                 y: y - minDim * 0.25,
                                 width: minDim * 0.5,
                                 height: minDim * 0.5
                             )
                             ctx.fill(
                                 Path(ellipseIn: rect),
                                 with: .color(colors[3].opacity(opacity * 0.8))
                             )
                         }
                    }
                }
            }
            .drawingGroup() // Offload to GPU for performance
            .blur(radius: blurRadius)
            
            // Glass overlay
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(0.4) // Adjust for glassiness strength
        }
        .ignoresSafeArea()
        .background(Color.black.opacity(0.05)) // Base layer
    }
}

#Preview {
    LiquidGlassView()
        .frame(width: 800, height: 600)
}
