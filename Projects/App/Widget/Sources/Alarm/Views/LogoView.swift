import SwiftUI

struct LogoView: View {
    
    let style: Style
    
    enum Style: CGFloat {
        case basic = 48
        case compact = 20
        case minimal = 16
    }
        
    var body: some View {
        HStack(alignment: .center) {
            Image("Logo")
                .resizable()
                .scaledToFit()
                .frame(width: style.rawValue, height: style.rawValue)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
