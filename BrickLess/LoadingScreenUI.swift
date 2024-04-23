import SwiftUI

struct LoadingView: View {
    @State private var isActive: Bool = false
    let backgroundColor = Color.red // Replace this with the color that matches your logo's background

    var body: some View {
        GeometryReader { geometry in
            VStack {
                if isActive {
                    ContentView()
                } else {
                    // Entire screen with the background color
                    Color(backgroundColor)
                        .edgesIgnoringSafeArea(.all) // Allow the background color to extend into the safe area
                        .overlay(
                            Image("Logo")
                                .resizable()
                                .aspectRatio(contentMode: .fit) // Keep the image's aspect ratio
                                .frame(width: geometry.size.width / 2, height: geometry.size.height / 2)
                                // Center the image in the middle of the screen
                                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                        )
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
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

