import SwiftUI

struct LoginView: View {
    @ObservedObject var session: SessionStore
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showingReset = false
    @State private var resetEmail: String = ""
    @State private var resetMessage: String?
    @FocusState private var focusedField: Field?
    @Binding var errorMessage: String?

    /// Which field the keyboard is in, so Next on the email field
    /// moves to the password field instead of doing nothing.
    private enum Field {
        case email, password
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Wordmark: a ball badge, the PlayMatch name, and a
                // short welcoming line, so the screen reads as the
                // front door of the app instead of a bare form.
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(PlayMatchColors.brand)
                            .frame(width: 76, height: 76)
                        Image(systemName: "basketball.fill")
                            .font(.system(size: 38))
                            .foregroundColor(.white)
                    }
                    Text("PlayMatch")
                        .font(.system(size: 44, weight: .bold))
                        .foregroundColor(PlayMatchColors.brand)
                    Text("Find your game. Play together.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 32)

                // Email + password, with icons so each field reads at
                // a glance. The fields stay editable only when no
                // sign-in is running.
                VStack(spacing: 12) {
                    HStack(spacing: 10) {
                        Image(systemName: "envelope")
                            .foregroundColor(.secondary)
                        TextField("Email", text: $email)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .submitLabel(.next)
                            .focused($focusedField, equals: .email)
                            .onSubmit { focusedField = .password }
                    }
                    .padding(14)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)

                    HStack(spacing: 10) {
                        Image(systemName: "lock")
                            .foregroundColor(.secondary)
                        SecureField("Password", text: $password)
                            .textContentType(.password)
                            .submitLabel(.go)
                            .focused($focusedField, equals: .password)
                            .onSubmit { attemptSignIn() }
                    }
                    .padding(14)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                }
                .disabled(session.isLoading)

                RememberMeCheckbox()

                // The Login button never leaves the screen: while a
                // sign-in is in flight it shows an inline spinner and
                // ignores taps, and on failure it comes straight back
                // with the error underneath it for an immediate retry.
                Button(action: attemptSignIn) {
                    HStack(spacing: 8) {
                        if session.isLoading {
                            ProgressView()
                                .tint(.white)
                        }
                        Text(SessionStore.loginButtonTitle(isLoading: session.isLoading))
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(PlayMatchColors.brand)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(SessionStore.loginButtonDisabled(isLoading: session.isLoading))
                .opacity(session.isLoading ? 0.8 : 1)

                // Every failed sign-in shows here, in red, with the
                // button back above it.
                if let errorMessage {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "exclamationmark.circle.fill")
                        Text(errorMessage)
                            .multilineTextAlignment(.leading)
                    }
                    .font(.subheadline)
                    .foregroundColor(.red)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.red.opacity(0.08))
                    .cornerRadius(10)
                }

                NavigationLink("Create Account", destination: RegisterView(session: session))
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .foregroundColor(PlayMatchColors.brand)
                    .cornerRadius(12)

                Button("Forgot password?") { showingReset = true }
                    .font(.footnote)
                    .foregroundColor(PlayMatchColors.brand)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
            .frame(maxWidth: 420)
            .frame(maxWidth: .infinity)
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
        .onAppear {
            // Remember me: prefill the login from the Keychain-saved
            // credentials (saved at the last successful sign-in with
            // Remember me checked). Signing out ends the session but
            // leaves these alone, so the form is filled in and the
            // player just taps Login. Only prefill empty fields.
            if email.isEmpty, password.isEmpty,
               let saved = session.savedLoginCredentials() {
                email = saved.email
                password = saved.password
            }
        }
        .appBackground()
    }

    /// One tap on Login (or Go on the keyboard): clear the old error
    /// and start a sign-in. Extra taps while one is in flight are
    /// ignored here as well as in SessionStore, so a double-tap can
    /// never start a duplicate request.
    private func attemptSignIn() {
        guard !session.isLoading else { return }
        errorMessage = nil
        session.signIn(email: email, password: password) { success in
            // Successful sign-in with Remember me checked
            // saves the login to the Keychain; unchecked
            // deletes any saved login.
            if success {
                session.applyRememberMe(email: email, password: password)
            }
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
                    .foregroundColor(rememberMe ? PlayMatchColors.brand : .secondary)
                Text("Remember me")
                    .foregroundColor(.primary)
                Spacer()
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
    }
}
