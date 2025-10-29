import SwiftUI
import Rex
import WeatherFeatureInterface
import Designsystem

public struct WeatherView: View {
    let interface: WeatherInterface
    @State private var state = WeatherState()

    public init(
        interface: WeatherInterface
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
                            VStack(alignment: .leading, spacing: 2) {
                                Text(state.currentWeather?.location ?? "서울")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(JColor.textPrimary)
                                
                                Text("현재 위치")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(JColor.textSecondary)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                interface.send(.refreshWeather)
                            }) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(JColor.textPrimary)
                                    .frame(width: 40, height: 40)
                                    .background(JColor.primary.opacity(0.1))
                                    .clipShape(Circle())
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        Text("Weather Content")
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
        .onAppear {
            interface.send(.loadWeather)
        }
    }
}
