import SwiftUI

struct CompactMotionView: View {
    let motionCount: Int
    let requiredCount: Int
    
    var body: some View {
        let remaining = max(0, requiredCount - motionCount)
        Text("\(remaining)")
            .font(.system(size: 14, weight: .bold, design: .rounded))
            .foregroundStyle(
                LinearGradient(
                    colors: remaining > 0 ? [.white, .gray] : [.green, .mint],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .contentTransition(.numericText())
    }
}
