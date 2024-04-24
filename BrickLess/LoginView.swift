import SwiftUI

struct LoginView: View {
    @ObservedObject var session: SessionStore
    @State private var username: String = ""
    @State private var password: String = ""
    @Binding var errorMessage: String?
    
    var body: some View {
        VStack {
            TextField("Username", text: $username)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .padding()

            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .padding()

            Button("Login") {
                // Initiates the login process
                self.errorMessage = "" // Clear any previous error messages
                session.loginUser(username: username, password: password)
            }
            .foregroundColor(.white)
            .background(Color.blue)
            .cornerRadius(8)
            .padding()

            NavigationLink("Create Account", destination: RegisterView(session: session))
                .padding()
        }
    }
}
