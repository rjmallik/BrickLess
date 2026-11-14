import SwiftUI

/// Step 1 of account setup: email + username + password.
/// On success the app routes to ProfileSetupView (via SessionStore.needsProfileSetup).
struct RegisterView: View {
    @ObservedObject var session: SessionStore
    @State private var email: String = ""
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var errorMessage: String?

    var body: some View {
        VStack {
            Text("Create your account")
                .font(.title2.bold())
                .padding(.bottom, 8)

            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.emailAddress)
                .padding(.horizontal)

            TextField("Username", text: $username)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(.horizontal)
            Text("3-20 letters, numbers or underscores. This is how other players find you.")
                .font(.footnote)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            SecureField("Confirm password", text: $confirmPassword)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            if let errorMessage {
                Text(errorMessage).foregroundColor(.red).padding(.horizontal)
            }

            RememberMeCheckbox()

            if session.isLoading {
                ProgressView().padding()
            } else {
                Button("Create Account") {
                    errorMessage = nil
                    guard password == confirmPassword else {
                        errorMessage = "Passwords do not match."
                        return
                    }
                    session.signUp(email: email, username: username, password: password) { _, error in
                        errorMessage = error
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .cornerRadius(8)
                .padding()
            }
        }
        .padding(.vertical)
    }
}
