import SwiftUI
import RefineUIIcons

struct CompactWakeUpView: View {
    var body: some View {
        Image(refineUIIcon: .clockAlarm24Filled)
            .foregroundStyle(
                LinearGradient(
                    colors: [.white, .gray],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
    }
}
