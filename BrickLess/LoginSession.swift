import Foundation
import Combine

class SessionStore: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var isLoggingIn: Bool = false // To track loading state during login
    @Published var hasAttemptedLogin = false //
    @Published var loginError: String? // To handle login errors

    private let correctUsername = "user"
    private let correctPassword = "password"
    private var users: [String: String] = [:]
    
    // Combine publisher for login status changes
    var loginStatusPublisher: AnyPublisher<Bool, Never> {
        $isLoggedIn.eraseToAnyPublisher()
    }
    
    func loginUser(username: String, password: String) {
        hasAttemptedLogin = false // Reset before login attempt
        isLoggingIn = true // Start loading
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { // Simulate network delay
            self.hasAttemptedLogin = true // Set that an attempt has been made
            if (username == self.correctUsername && password == self.correctPassword) || (self.users[username] == password) {
                self.isLoggedIn = true
                self.loginError = nil // Clear error message on successful login
            } else {
                self.isLoggedIn = false
                self.loginError = "Incorrect username or password." // Set error message on failed login
            }
            self.isLoggingIn = false // End loading
        }
    }
    func registerUser(username: String, password: String, completion: @escaping (Bool, String) -> Void) {
        isLoggingIn = true // Start loading
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { // Simulate processing time
            if self.users[username] != nil {
                completion(false, "This username is already taken.")
            } else {
                self.users[username] = password
                completion(true, "User registered successfully.")
            }
            self.isLoggingIn = false // End loading
        }
    }
    
    func signOut() {
        isLoggedIn = false
    }
}
