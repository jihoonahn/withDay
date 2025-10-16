import Foundation
import SwiftUI
import Rex
import RootFeatureInterface
import HomeFeatureInterface
import Designsystem

public struct HomeView: View {
    let interface: HomeInterface
    @State private var state = HomeState()

    public init(
        interface: HomeInterface
    ) {
        self.interface = interface
    }
    
    public var body: some View {
        NavigationView {
            ZStack {
                JColor.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        HStack {
                            Text(Date.now.toString())
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(JColor.textPrimary)

                            Spacer()
                            
                            Button(action: {
                                
                            }) {
                                Image(refineUIIcon: .alert24Regular)
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(JColor.textPrimary)
                                    .frame(width: 40, height: 40)
                                    .background(JColor.surface.opacity(0.8))
                                    .clipShape(Circle())
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        // 여기에 컨텐츠 추가
                        Text("Home Content")
                            .font(.title)
                            .foregroundColor(JColor.textPrimary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .padding(.bottom, 100)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationBarHidden(true)
        .task {
            for await newState in interface.stateStream {
                await MainActor.run {
                    self.state = newState
                }
            }
        }
    }
}
