import SwiftUI

struct LoadingView: View {
    @State private var isActive: Bool = false

    var body: some View {
        GeometryReader { geometry in
            VStack {
                if isActive {
                    ContentView()
                } else {
                    Image("Logo")
                        .resizable()
                        .aspectRatio(contentMode: .fill) // Fill the entire area
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped() // Clip the overflowing parts of the image
                        .edgesIgnoringSafeArea(.all) // Allow the image to extend into the safe area
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
