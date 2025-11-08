import SwiftUI

public extension View {
    func toast<Content: View>(
        isPresented: Binding<Bool>,
        duration: TimeInterval = 1.25,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        modifier(ToastModifier(isPresented: isPresented, duration: duration, toastContent: content))
    }
}
