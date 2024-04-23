import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
                    Text("BrickLess")
                        .font(.custom("Arial", size: 60))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding()
                    
                    NavigationLink(destination: RecreationalView()) {
                        Text("Recreational")
                            .foregroundColor(.white)
                            .font(.title)
                    }
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
                    
                    NavigationLink(destination: PremiumView()) {
                        Text("Premium")
                            .foregroundColor(.white)
                            .font(.title)
                    }
                    .padding()
                    .background(Color.red)
                    .cornerRadius(10)
                    
                    NavigationLink(destination: ProfessionalView()) {
                        Text("Professional")
                            .foregroundColor(.white)
                            .font(.title)
                    }
                    .padding()
                    .background(Color.green)
                    .cornerRadius(10)
                }
            }
            .navigationBarHidden(true)
        }
    }
}

struct RecreationalView: View {
    var body: some View {
        Text("Recreational View")
            .navigationBarHidden(true)
    }
}

struct PremiumView: View {
    var body: some View {
        Text("Premium View")
            .navigationBarHidden(true)
    }
}

struct ProfessionalView: View {
    var body: some View {
        Text("Professional View")
            .navigationBarHidden(true)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
