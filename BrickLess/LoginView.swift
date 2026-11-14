import SwiftUI

struct LoginView: View {
    @ObservedObject var session: SessionStore
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showingReset = false
    @State private var resetEmail: String = ""
    @State private var resetMessage: String?
    @Binding var errorMessage: String?

    var body: some View {
        VStack {
            Text("PlayMatch")
                .font(.system(size: 44, weight: .bold))
                .padding(.bottom, 8)

            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.emailAddress)
                .padding(.horizontal)

            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            RememberMeCheckbox()

            if session.isLoading {
                ProgressView()
                    .padding()
            } else {
                Button("Login") {
                    errorMessage = nil
                    session.signIn(email: email, password: password)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(8)
                .padding()
            }

            if let errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding(.horizontal)
            }

            NavigationLink("Create Account", destination: RegisterView(session: session))
                .padding()

            Button("Forgot password?") { showingReset = true }
                .font(.footnote)
        }
        .alert("Reset password", isPresented: $showingReset) {
            TextField("Email", text: $resetEmail)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
            Button("Send reset email") {
                session.sendPasswordReset(email: resetEmail) { error in
                    resetMessage = error ?? "Reset email sent. Check your inbox."
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(resetMessage ?? "We will email you a link to reset your password.")
        }
    }
}

/// A "Remember me" checkbox, shared by the sign-in and sign-up
/// screens. The choice is stored in UserDefaults (key
/// SessionStore.rememberMeDefaultsKey) so it survives app restarts;
/// SessionStore reads the same key at launch to decide whether a
/// restored session stays signed in.
struct RememberMeCheckbox: View {
    @AppStorage(SessionStore.rememberMeDefaultsKey) private var rememberMe = false

    var body: some View {
        Button {
            rememberMe.toggle()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: rememberMe ? "checkmark.square.fill" : "square")
                    .foregroundColor(rememberMe ? .blue : .secondary)
                Text("Remember me")
                    .foregroundColor(.primary)
                Spacer()
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
    }
}
