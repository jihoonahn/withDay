import SwiftUI

public enum JShadow {
    public static let small = ShadowStyle(radius: 4, opacity: 0.1)
    public static let medium = ShadowStyle(radius: 8, opacity: 0.15)
    public static let large = ShadowStyle(radius: 16, opacity: 0.2)
}

public struct ShadowStyle {
    let radius: CGFloat
    let opacity: Double
}
