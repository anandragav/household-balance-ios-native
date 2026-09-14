import Foundation

enum APIError: LocalizedError {
  case unauthorized
  case message(String)

  var errorDescription: String? {
    switch self {
    case .unauthorized: return "Please sign in again."
    case .message(let text): return text
    }
  }
}

final class APIClient {
  static let shared = APIClient()
  static let origin = URL(string: "https://family-balance.grok.me")!

  private let session: URLSession = {
    let config = URLSessionConfiguration.default
    config.httpCookieAcceptPolicy = .always
    config.httpShouldSetCookies = true
    config.httpCookieStorage = HTTPCookieStorage.shared
    return URLSession(configuration: config)
  }()

  private init() {}

  private func url(_ path: String) -> URL {
    origin.appendingPathComponent(path.trimmingCharacters(in: CharacterSet(charactersIn: "/")))
  }

  func signIn(email: String, password: String) async throws {
    try await postAuth("api/auth/sign-in/email", body: [
      "email": email,
      "password": password,
    ])
  }

  func signUp(name: String, email: String, password: String) async throws {
    try await postAuth("api/auth/sign-up/email", body: [
      "name": name,
      "email": email,
      "password": password,
    ])
  }

  func signOut() async {
    _ = try? await postAuth("api/auth/sign-out", body: [:])
  }

  func household() async throws -> HouseholdEnvelope {
    try await get("api/mobile/household")
  }

  func action(_ body: [String: Any]) async throws -> HouseholdEnvelope {
    try await post("api/mobile/action", body: body)
  }

  private func get<T: Decodable>(_ path: String) async throws -> T {
    var request = URLRequest(url: url(path))
    request.httpMethod = "GET"
    return try await decode(request)
  }

  private func post<T: Decodable>(_ path: String, body: [String: Any]) async throws -> T {
    var request = URLRequest(url: url(path))
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "content-type")
    request.httpBody = try JSONSerialization.data(withJSONObject: body)
    return try await decode(request)
  }

  @discardableResult
  private func postAuth(_ path: String, body: [String: Any]) async throws -> [String: Any] {
    var request = URLRequest(url: url(path))
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "content-type")
    request.httpBody = try JSONSerialization.data(withJSONObject: body)
    let (data, response) = try await session.data(for: request)
    guard let http = response as? HTTPURLResponse else {
      throw APIError.message("No response.")
    }
    if http.statusCode == 401 { throw APIError.unauthorized }
    let object = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] ?? [:]
    if http.statusCode >= 400 {
      let msg = (object["message"] as? String) ?? (object["error"] as? String) ?? "Could not sign in."
      throw APIError.message(msg)
    }
    return object
  }

  private func decode<T: Decodable>(_ request: URLRequest) async throws -> T {
    let (data, response) = try await session.data(for: request)
    guard let http = response as? HTTPURLResponse else {
      throw APIError.message("No response.")
    }
    if http.statusCode == 401 { throw APIError.unauthorized }
    if http.statusCode >= 400 {
      let object = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
      throw APIError.message((object?["error"] as? String) ?? "Request failed.")
    }
    return try JSONDecoder().decode(T.self, from: data)
  }
}
