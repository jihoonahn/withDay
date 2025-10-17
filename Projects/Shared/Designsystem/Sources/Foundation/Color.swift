import SwiftUI

public enum JColor {
    public static let background = Color(hex: "#0A0A0A")
    public static let surface = Color(hex: "#1C1C1E")
    public static let card = Color(hex: "#2C2C2E")

    public static let textPrimary = Color(hex: "#FFFFFF")
    public static let textSecondary = Color(hex: "#A1A1A6")
    public static let textDisabled = Color(hex: "#5E5E5E")

    public static let primary = Color(hex: "#3182F6")
    public static let primaryVariant = Color(hex: "#2B73DB")

    public static let success = Color(hex: "#30D158")
    public static let warning = Color(hex: "#FFD60A")
    public static let error = Color(hex: "#FF453A")

    public static let divider = Color(hex: "#2C2C2E")
    public static let border = Color(hex: "#4D4D4D")
    
    public static func dynamic(light: Color, dark: Color) -> Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
    }
}
