import SwiftUI

@MainActor
final class SessionStore: ObservableObject {
  @Published var household: Household?
  @Published var email: String?
  @Published var status: Status = .booting
  @Published var error: String?

  enum Status { case booting, signedOut, empty, ready }

  func boot() async {
    status = .booting
    do {
      let envelope = try await APIClient.shared.household()
      email = envelope.user?.email
      household = envelope.household
      status = envelope.household == nil ? .empty : .ready
    } catch APIError.unauthorized {
      status = .signedOut
    } catch {
      self.error = error.localizedDescription
      status = .signedOut
    }
  }

  func signIn(email: String, password: String) async {
    error = nil
    do {
      try await APIClient.shared.signIn(email: email, password: password)
      await boot()
    } catch {
      self.error = error.localizedDescription
    }
  }

  func signUp(name: String, email: String, password: String) async {
    error = nil
    do {
      try await APIClient.shared.signUp(name: name, email: email, password: password)
      await boot()
    } catch {
      self.error = error.localizedDescription
    }
  }

  func signOut() async {
    await APIClient.shared.signOut()
    household = nil
    status = .signedOut
  }

  func refresh() async {
    do {
      let envelope = try await APIClient.shared.household()
      household = envelope.household
      status = envelope.household == nil ? .empty : .ready
    } catch APIError.unauthorized {
      status = .signedOut
    } catch {
      self.error = error.localizedDescription
    }
  }

  func run(_ body: [String: Any]) async {
    error = nil
    do {
      let envelope = try await APIClient.shared.action(body)
      if let household = envelope.household {
        self.household = household
        status = .ready
      } else if let message = envelope.error {
        error = message
      }
    } catch {
      self.error = error.localizedDescription
    }
  }
}
