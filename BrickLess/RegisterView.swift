import SwiftUI

struct RegisterView: View {
    @ObservedObject var session: SessionStore
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var errorMessage: String?

    var body: some View {
        VStack {
            TextField("Choose a username", text: $username)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .padding()

            SecureField("Choose a password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .padding()

            if let errorMessage = errorMessage {
                Text(errorMessage).foregroundColor(.red).padding()
            }

            Button("Create Account") {
                session.registerUser(username: username, password: password) { success, message in
                    if success {
                        session.loginUser(username: username, password: password)
                    } else {
                        self.errorMessage = message
                    }
                }
            }
            .foregroundColor(.white)
            .background(Color.green)
            .cornerRadius(8)
            .padding()
        }
        .padding()
    }
}
