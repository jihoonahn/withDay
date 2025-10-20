import SwiftUI
import Rex
import Designsystem
import HomeFeatureInterface

struct MemoView: View {
    let interface: HomeInterface
    @State private var state = HomeState()

    init(interface: HomeInterface, state: HomeState) {
        self.interface = interface
        self.state = state
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                JColor.background.ignoresSafeArea()
                VStack {
                    HStack {
                        Spacer()
                        Button {
                            print("저장")
                        } label: {
                            Text("저장")
                        }
                    }
                    Spacer()
                }
                .padding(.top, 30)
                .padding(.horizontal, 20)
            }
        }
    }
}
