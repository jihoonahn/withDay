import SwiftUI

extension Color {
    init(hex: String, opacity: Double = 1.0) {
        var hexFormatted = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexFormatted = hexFormatted.replacingOccurrences(of: "#", with: "")
        
        var rgbValue: UInt64 = 0
        Scanner(string: hexFormatted).scanHexInt64(&rgbValue)
        
        let r, g, b: Double
        if hexFormatted.count == 6 {
            r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
            g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
            b = Double(rgbValue & 0x0000FF) / 255.0
        } else {
            r = 1.0; g = 1.0; b = 1.0
        }
        
        self.init(.sRGB, red: r, green: g, blue: b, opacity: opacity)
    }
}
