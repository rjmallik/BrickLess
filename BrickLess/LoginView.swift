import SwiftUI

struct LoginView: View {
    @ObservedObject var session: SessionStore
    @State private var username: String = ""
    @State private var password: String = ""
    @Binding var errorMessage: String?

    init(session: SessionStore, errorMessage: Binding<String?>) {
        self.session = session
        _errorMessage = errorMessage
    }

    var body: some View {
        NavigationView {
            VStack {
                TextField("Username", text: $username)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .padding()

                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .padding()

                if let errorMessage = errorMessage {
                    Text(errorMessage).foregroundColor(.red)
                }

                Button("Login") {
                    session.loginUser(username: username, password: password)
                    if !session.isLoggedIn {
                        errorMessage = "Incorrect username or password."
                    }
                }
                .foregroundColor(.white)
                .background(Color.blue)
                .cornerRadius(8)
                .padding()

                NavigationLink("Create Account", destination: RegisterView(session: session))
                    .padding()
            }
        }
        .padding()
    }
}
