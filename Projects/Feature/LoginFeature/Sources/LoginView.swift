import SwiftUI
import Rex
import RootFeatureInterface
import LoginFeatureInterface

public struct LoginView: View {
    let interface: LoginInterface
    @State private var state = LoginState()

    public init(
        interface: LoginInterface
    ) {
        self.interface = interface
    }
    
    public var body: some View {
        VStack {
            HStack {
                Text("Login")
                    .font(Font.largeTitle)
                    .bold()
                Spacer()
            }
            .padding(.top, 50)
            Spacer()
            VStack(spacing: 20) {
                Button {
                    interface.send(.selectToGoogleOauth)
                } label: {
                    Text("Apple Oauth")
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .background(Color.black)
                .cornerRadius(8)
                Button {
                    interface.send(.selectToGoogleOauth)
                } label: {
                    Text("Google Oauth")
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .background(Color.black)
                .cornerRadius(8)
            }
            .padding(.bottom, 50)
        }
        .padding()
        .task {
            for await newState in interface.stateStream {
                await MainActor.run {
                    self.state = newState
                }
            }
        }
    }
}
