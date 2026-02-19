// Copyright © 2024 LocalImg. All rights reserved.

import Foundation
import SwiftUI

/// Centralized app settings backed by UserDefaults via @AppStorage
@Observable
final class AppSettings {

    // MARK: - Onboarding

    static let hasCompletedOnboardingKey = "hasCompletedOnboarding"

    var hasCompletedOnboarding: Bool {
        get { UserDefaults.standard.bool(forKey: Self.hasCompletedOnboardingKey) }
        set { UserDefaults.standard.set(newValue, forKey: Self.hasCompletedOnboardingKey) }
    }

    static let alwaysShowOnboardingKey = "alwaysShowOnboarding"

    var alwaysShowOnboarding: Bool {
        get { UserDefaults.standard.bool(forKey: Self.alwaysShowOnboardingKey) }
        set { UserDefaults.standard.set(newValue, forKey: Self.alwaysShowOnboardingKey) }
    }

    static let customModelPathKey = "customModelPath"

    var customModelPath: String {
        get { UserDefaults.standard.string(forKey: Self.customModelPathKey) ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: Self.customModelPathKey) }
    }

    // MARK: - Model

    static let selectedModelIdKey = "selectedModelId"

    var selectedModelId: String {
        get { UserDefaults.standard.string(forKey: Self.selectedModelIdKey) ?? ModelInfo.sdxlTurbo.id }
        set { UserDefaults.standard.set(newValue, forKey: Self.selectedModelIdKey) }
    }

    var selectedModel: ModelInfo {
        ModelInfo.availableModels.first { $0.id == selectedModelId } ?? .sdxlTurbo
    }

    // MARK: - Generation Defaults

    static let defaultStepsKey = "defaultSteps"
    static let defaultGuidanceKey = "defaultGuidance"
    static let defaultWidthKey = "defaultWidth"
    static let defaultHeightKey = "defaultHeight"
    static let defaultOutputFormatKey = "defaultOutputFormat"

    var defaultSteps: Int {
        get {
            let val = UserDefaults.standard.integer(forKey: Self.defaultStepsKey)
            return val > 0 ? val : selectedModel.defaultSteps
        }
        set { UserDefaults.standard.set(newValue, forKey: Self.defaultStepsKey) }
    }

    var defaultGuidance: Float {
        get {
            let exists = UserDefaults.standard.object(forKey: Self.defaultGuidanceKey) != nil
            return exists ? UserDefaults.standard.float(forKey: Self.defaultGuidanceKey) : selectedModel.defaultGuidanceScale
        }
        set { UserDefaults.standard.set(newValue, forKey: Self.defaultGuidanceKey) }
    }

    var defaultWidth: Int {
        get {
            let val = UserDefaults.standard.integer(forKey: Self.defaultWidthKey)
            return val > 0 ? val : ImageDimension.xlarge.rawValue
        }
        set { UserDefaults.standard.set(newValue, forKey: Self.defaultWidthKey) }
    }

    var defaultHeight: Int {
        get {
            let val = UserDefaults.standard.integer(forKey: Self.defaultHeightKey)
            return val > 0 ? val : ImageDimension.large.rawValue
        }
        set { UserDefaults.standard.set(newValue, forKey: Self.defaultHeightKey) }
    }

    var defaultOutputFormat: OutputFormat {
        get {
            let val = UserDefaults.standard.string(forKey: Self.defaultOutputFormatKey)
            return OutputFormat(rawValue: val ?? "") ?? .png
        }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: Self.defaultOutputFormatKey) }
    }

    // MARK: - Factory

    /// Create default generation parameters from settings
    func defaultParameters() -> GenerationParameters {
        GenerationParameters(
            prompt: "",
            negativePrompt: "",
            steps: defaultSteps,
            guidanceScale: defaultGuidance,
            seed: 0,
            width: defaultWidth,
            height: defaultHeight,
            imageCount: 1,
            outputFormat: defaultOutputFormat,
            useRandomSeed: true
        )
    }
}
