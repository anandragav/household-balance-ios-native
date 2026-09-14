import SwiftUI

struct SignInView: View {
  @EnvironmentObject var session: SessionStore
  @State private var mode = false
  @State private var name = ""
  @State private var email = ""
  @State private var password = ""
  @State private var busy = false

  var body: some View {
    NavigationStack {
      Form {
        if mode {
          TextField("Your name", text: $name)
            .textContentType(.name)
        }
        TextField("Email", text: $email)
          .textContentType(.emailAddress)
          .keyboardType(.emailAddress)
          .textInputAutocapitalization(.never)
        SecureField("Password", text: $password)
          .textContentType(mode ? .newPassword : .password)

        if let error = session.error {
          Text(error).foregroundStyle(.red)
        }

        Button(mode ? "Create account" : "Sign in") {
          Task {
            busy = true
            if mode {
              await session.signUp(name: name, email: email, password: password)
            } else {
              await session.signIn(email: email, password: password)
            }
            busy = false
          }
        }
        .disabled(busy || email.isEmpty || password.count < 8)

        Button(mode ? "Already have an account? Sign in" : "Need an account? Create one") {
          mode.toggle()
        }
      }
      .navigationTitle("Household Balance")
      .navigationBarTitleDisplayMode(.inline)
    }
  }
}
