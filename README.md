# 🖼️ LocalImg

**Generate images with AI — entirely on your Mac. No cloud, no API keys, no subscriptions.**

LocalImg is a native macOS app that runs Stable Diffusion models locally on Apple Silicon using the incredible [MLX framework](https://github.com/ml-explore/mlx). Type a prompt, hit generate, and watch your image come to life — all without a single byte leaving your machine. This is made for fun, MVP stage, curious on local image generation project.

![localImg](./reference/LocalImg.gif)
---

## ✨ What It Does

- **Text-to-Image Generation** — Describe what you want, and LocalImg generates it right on your Mac.
- **100% Local & Private** — Everything runs on-device. No internet required after the initial model download. Your prompts never leave your computer.
- **Live Preview** — Watch the image progressively denoise in real-time as it generates.
- **Generation History** — Every image you create is saved with its full parameters (prompt, seed, steps, guidance, dimensions) via SwiftData, so you can browse, revisit, and reproduce any past generation.
- **Zoomable Image Preview** — Pinch-to-zoom and pan across your generated images with smooth controls.
- **Adjustable Parameters** — Fine-tune steps, guidance scale, seed, dimensions, and output format (PNG/JPEG) to your liking.
- **Multiple Models** — Ships with support for **SDXL Turbo**, with an architecture that makes adding more models straightforward. (Support for **Stable Diffusion 2.1 Base** is still baking)

---

## 🧠 Why MLX?

This project exists because of **Apple's MLX framework** — and honestly, it's kind of magic.

MLX is an array framework designed specifically for machine learning on Apple Silicon. It brings GPU-accelerated inference to the Mac in a way that feels native, efficient, and *fast*. The [mlx-swift-examples](https://github.com/ml-explore/mlx-swift-examples) repository provides a Swift-native Stable Diffusion implementation that this app wraps, meaning we get:

- **Unified Memory** — Apple Silicon shares memory between CPU and GPU, so there's no expensive data copying. The model just *runs*.
- **Float16 & Quantization** — MLX supports fp16 and quantized inference out of the box, keeping VRAM usage low even on machines with 8 GB of unified memory.
- **Lazy Evaluation** — Computations are only materialized when needed, which keeps the pipeline lean.
- **Swift-Native** — No Python bridge, no ONNX runtime, no Core ML conversion step. Pure Swift, directly calling into MLX's metal shaders.

Apple's investment in on-device ML is genuinely impressive, and MLX is the clearest expression of that vision. This project is a small love letter to that work. 💜

---

## 🏗️ Architecture & Design Decisions

### Why Swift Package Manager (not Xcode project)?

LocalImg is a pure **Swift Package** — no `.xcodeproj`, no `.xcworkspace`. You can build and run it with `swift run` from the terminal. This keeps the project lightweight, portable, and free from Xcode-specific cruft. The `NSApplication.setActivationPolicy(.regular)` call in the app entrypoint ensures it behaves as a proper foreground GUI app even when launched from the terminal.

### Why SwiftUI + SwiftData?

- **SwiftUI** because it's the modern, declarative way to build macOS interfaces, and it pairs beautifully with the `@Observable` pattern for reactive state management.
- **SwiftData** for history persistence because it's zero-config, built into the platform, and perfect for the simple schema of generation records.

### Why a Protocol for the Engine?

The `ImageGenerationEngine` protocol abstracts the generation backend. Today it's `MLXDiffusionEngine`, but this design means you could swap in a Core ML backend, a remote API, or anything else without touching the UI layer.

### Memory Management

The engine auto-detects available system RAM and adjusts its strategy:
- **< 8 GB**: Quantized weights, aggressive memory limits, conservative cache.
- **≥ 8 GB**: Full fp16 weights with a generous 256 MB cache for faster subsequent generations.

---

## 🚀 Getting Started

### Requirements

- **macOS 14 (Sonoma)** or later
- **Apple Silicon** (M1 / M2 / M3 / M4) — this will not run on Intel Macs
- ~**40 GB** of free disk space for the SDXL Turbo model

### Build & Run

```bash
git clone https://github.com/scodes73/local-img.git
cd local-img
swift run
```

On first launch, the onboarding screen will guide you through downloading your chosen model. After that, you're fully offline-capable.

I highly recommend to download the model using huggingface-cli (to not get rate limiting and higher download speeds):
```bash
brew install huggingface-cli
hf download stabilityai/sdxl-turbo
```

---

## ⚠️ MVP Disclaimer

**This is a Minimum Viable Product built for fun.** 🎉

LocalImg was made as a passion project to explore what's possible with MLX on Apple Silicon. It is **not** production-grade software. You may encounter:

- Rough edges in the UI
- Occasional generation failures on unusual dimension/step combos
- Limited model selection (just two presets today)
- No batch generation, img2img, inpainting, or ControlNet (yet?)

The code is written to be clear and hackable over bulletproof. If you want to experiment with on-device image generation on your Mac, this is a fun starting point — not a finished product.

**PRs, ideas, and vibes are welcome.** 🤙

---

## 📁 Project Structure

```
Sources/LocalImg/
├── LocalImgApp.swift          # App entry point
├── MLX/                       # MLX Stable Diffusion primitives
│   ├── Clip.swift             # CLIP text encoder
│   ├── Configuration.swift    # Model configurations
│   ├── Image.swift            # Image utilities
│   ├── Load.swift             # Weight loading
│   ├── Sampler.swift          # Noise sampling
│   ├── StableDiffusion.swift  # Pipeline orchestration
│   ├── Tokenizer.swift        # Text tokenization
│   ├── UNet.swift             # UNet denoiser
│   └── VAE.swift              # Variational autoencoder
├── Models/
│   ├── AppSettings.swift      # UserDefaults-backed settings
│   ├── GenerationParameters.swift  # Prompt, steps, seed, etc.
│   ├── GenerationRecord.swift # SwiftData history model
│   └── ModelInfo.swift        # Model metadata & presets
├── Services/
│   ├── HistoryManager.swift   # SwiftData CRUD
│   ├── ImageGenerationEngine.swift  # Engine protocol
│   ├── MLXDiffusionEngine.swift     # MLX backend
│   ├── ModelManager.swift     # Download & cache management
│   └── ThumbnailLoader.swift  # Async thumbnail loading
└── Views/
    ├── ContentView.swift      # Main layout
    ├── GenerationView.swift   # Prompt input & image display
    ├── HistoryGalleryView.swift    # History sidebar
    ├── HistoryThumbnailView.swift  # History thumbnails
    ├── ImagePreviewView.swift # Zoomable image preview
    ├── LiquidGlassView.swift  # Animated background effect
    ├── OnboardingView.swift   # First-launch setup
    ├── SettingsView.swift     # Preferences window
    └── ZoomableImageView.swift # Pinch/scroll zoom
```

---

## 🙏 Acknowledgments

- **[Apple MLX](https://github.com/ml-explore/mlx)** — For making on-device ML on Apple Silicon genuinely delightful.
- **[mlx-swift-examples](https://github.com/ml-explore/mlx-swift-examples)** — The Swift Stable Diffusion implementation that powers this app.
- **[Hugging Face](https://huggingface.co)** — For hosting the model weights and making them accessible.
- **[Stability AI](https://stability.ai)** — For the Stable Diffusion and SDXL model families.

