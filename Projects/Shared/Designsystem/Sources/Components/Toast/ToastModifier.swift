import SwiftUI

public struct ToastModifier<ToastContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    let duration: TimeInterval
    let toastContent: () -> ToastContent

    @State private var workItem: DispatchWorkItem?

    public func body(content: Content) -> some View {
        ZStack {
            content
            
            VStack {
                Spacer()
                toastContent()
                    .offset(y: isPresented ? 0 : 28)
                    .opacity(isPresented ? 1 : 0)
                    .scaleEffect(isPresented ? 1 : 0.96, anchor: .bottom)
                    .allowsHitTesting(false)
            }
            .animation(.interactiveSpring(response: 0.45, dampingFraction: 0.85, blendDuration: 0.25), value: isPresented)
            .onChange(of: isPresented) { visible in
                handlePresentationChange(isVisible: visible)
            }
        }
    }
    
    private func handlePresentationChange(isVisible: Bool) {
        workItem?.cancel()
        guard isVisible else { return }
        let task = DispatchWorkItem {
            withAnimation(.interactiveSpring(response: 0.42, dampingFraction: 0.82, blendDuration: 0.25)) {
                isPresented = false
            }
        }
        workItem = task
        DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: task)
    }
}
