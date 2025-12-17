import UIKit

/// A manager for handling haptic feedback that gracefully handles simulator environments
public enum HapticManager {
    /// Triggers an impact haptic feedback
    /// - Parameter style: The style of impact feedback
    public static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        #if targetEnvironment(simulator)
        // Skip haptics in simulator to avoid console errors
        return
        #else
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
        #endif
    }
    
    /// Triggers a selection haptic feedback
    public static func selection() {
        #if targetEnvironment(simulator)
        // Skip haptics in simulator to avoid console errors
        return
        #else
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
        #endif
    }
    
    /// Triggers a notification haptic feedback
    /// - Parameter type: The type of notification feedback
    public static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        #if targetEnvironment(simulator)
        // Skip haptics in simulator to avoid console errors
        return
        #else
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
        #endif
    }
}

