import SwiftUI

struct LoadingView: View {
    @State private var isActive: Bool = false
    var duration: TimeInterval  // Time in seconds to wait before transitioning
    let backgroundColor: Color // Color for the background
    let logoImageName: String // Name of the logo image

    init(duration: TimeInterval = 2, backgroundColor: Color = .red, logoImageName: String = "Logo") {
        self.duration = duration
        self.backgroundColor = backgroundColor
        self.logoImageName = logoImageName
    }

    var body: some View {
        GeometryReader { geometry in
            VStack {
                if isActive {
                    ContentView()
                } else {
                    Color(backgroundColor)
                        .edgesIgnoringSafeArea(.all)
                        .overlay(
                            Image(logoImageName)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: geometry.size.width / 2, height: geometry.size.height / 2)
                                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                        )
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                                withAnimation {
                                    self.isActive = true
                                }
                            }
                        }
                }
            }
        }
        .transition(.opacity)
    }
}
