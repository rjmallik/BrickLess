import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                VStack {
                    Spacer() // Use a single spacer at the top to push content down
                    
                    Text("BrickLess")
                        .font(.custom("Arial", size: 60))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    NavigationLink(destination: RecreationalView()) {
                        Text("Recreational")
                            .foregroundColor(.white)
                            .font(.title)
                            .frame(maxWidth: .infinity, minHeight: 250) // Make the button wider and taller
                    }
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
                    .padding(.vertical, 35) // Add horizontal padding
                    
                    NavigationLink(destination: PremiumView()) {
                        Text("Premium")
                            .foregroundColor(.white)
                            .font(.title)
                            .frame(maxWidth: .infinity, minHeight: 120) // Make the button wider and taller
                    }
                    .padding()
                    .background(Color.red)
                    .cornerRadius(10)
                    .padding(.vertical, 35) // Add horizontal padding
                    
                    Spacer() // Use a single spacer at the bottom to push content up
                }
            }
            .navigationBarHidden(true)
        }
    }
}



struct RecreationalView: View {
    @Environment(\.presentationMode) var presentationMode


    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: geometry.size.height * 0.15) {  // Reduced vertical whitespace
                HStack(spacing: geometry.size.width * 0.05) {  // Reduced horizontal whitespace
                    Text("Find Games Near You")
                        .frame(width: geometry.size.width * 0.45, height: geometry.size.width * 0.45)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(15) // Curved edges
                    Text("My Profile")
                        .frame(width: geometry.size.width * 0.45, height: geometry.size.width * 0.45)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(15) // Curved edges
                }
                HStack(spacing: geometry.size.width * 0.05) {  // Reduced horizontal whitespace
                    Text("Add Friends")
                        .frame(width: geometry.size.width * 0.45, height: geometry.size.width * 0.45)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(15) // Curved edges
                    Text("My Guys")
                        .frame(width: geometry.size.width * 0.45, height: geometry.size.width * 0.45)
                        .background(Color.yellow)
                        .foregroundColor(.black)
                        .cornerRadius(15) // Curved edges
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .padding(2)  // Reduced padding around the VStack
        }
        .edgesIgnoringSafeArea(.all)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: Button(action: {
            self.presentationMode.wrappedValue.dismiss()
        }) {
            Text("Back")
                .frame(minWidth: 84, minHeight: 34) // Minimum recommended tap target size for iOS
                .background(Color.gray) // Give it a gray background
                .foregroundColor(.white) // Text color
                .cornerRadius(5) // Rounded corners
        })
        .navigationBarHidden(false) // Show the navigation bar
    }
}

// Apply the same modifications for PremiumView and ProfessionalView
struct PremiumView: View {
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack {
            Text("Premium View")
            // Other content
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: Button(action: {
            self.presentationMode.wrappedValue.dismiss()
        }) {
            Text("Back")
                .frame(minWidth: 84, minHeight: 34)
                .background(Color.gray)
                .foregroundColor(.white)
                .cornerRadius(5)
        })
        .navigationBarHidden(false)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}