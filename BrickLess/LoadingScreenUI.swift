import SwiftUI

struct LoadingView: View {
    @State private var isActive: Bool = false
    var duration: TimeInterval  // Time in seconds to wait before transitioning
    let backgroundColor: Color // Color for the background
    let logoImageName: String // Name of the logo image

    /// Orange sampled from the new PlayMatch icon's own flat background
    /// (#FE5400), so the artwork's orange field blends seamlessly into
    /// the full-screen background on every device.
    static let playMatchOrange = Color(red: 254 / 255, green: 84 / 255, blue: 0)

    /// The new PlayMatch icon asset (two stick figures passing balls).
    /// Its PNG lives in PlayMatchIcon.imageset — RJ uploads it there via
    /// the GitHub web UI, since the snapshot push flow cannot carry
    /// binary files.
    static let playMatchIconImageName = "PlayMatchIcon"

    init(duration: TimeInterval = 2, backgroundColor: Color = playMatchOrange, logoImageName: String = playMatchIconImageName) {
        self.duration = duration
        self.backgroundColor = backgroundColor
        self.logoImageName = logoImageName
    }

    /// The image to show. If the PlayMatch icon asset is not bundled yet
    /// (its PNG has not been uploaded into PlayMatchIcon.imageset),
    /// fall back to the legacy "Logo" asset so the screen never renders
    /// as blank orange.
    private var resolvedLogoImageName: String {
        if logoImageName == Self.playMatchIconImageName,
           UIImage(named: logoImageName) == nil {
            return "Logo"
        }
        return logoImageName
    }

    /// The icon, drawn as large as the screen allows without distortion.
    /// The icon is square, so on a tall phone it spans the full width
    /// and the matching orange background fills the rest of the screen
    /// edge to edge. A true scaledToFill would crop both stick figures
    /// off on tall iPhones (only the centre ~46% of the square stays
    /// visible), so the artwork is aspect-fit on the icon's own orange
    /// instead — the whole screen reads as the icon, with nothing cut off.
    @ViewBuilder
    private func logoImage(side: CGFloat) -> some View {
        let image = Image(resolvedLogoImageName)
            .resizable()
            .scaledToFit()
            .frame(width: side, height: side)
        if resolvedLogoImageName == Self.playMatchIconImageName {
            // The icon PNG has white rounded corners (RGB, no alpha).
            // Clip them off with the icon's own corner radius (~22.5%
            // of its side) so no white wedges show against the orange.
            image.clipShape(RoundedRectangle(cornerRadius: side * 0.225, style: .continuous))
        } else {
            image
        }
    }

    var body: some View {
        GeometryReader { geometry in
            if isActive {
                ContentView()
            } else {
                ZStack {
                    backgroundColor
                    logoImage(side: min(geometry.size.width, geometry.size.height))
                }
                .ignoresSafeArea()
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                        withAnimation {
                            self.isActive = true
                        }
                    }
                }
            }
        }
        .transition(.opacity)
    }
}
