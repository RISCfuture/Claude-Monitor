//
//  ClaudeAPIService.swift
//  Claude Monitor Widget
//

import Foundation

/// Errors that can occur when communicating with the Claude API.
enum APIError: Error, LocalizedError {
  case noToken
  case invalidURL
  case httpError(statusCode: Int, message: String?)
  case decodingError(Error)
  case networkError(Error)

  var errorDescription: String? {
    "Could not access the Claude API."
  }
}

/// A service for communicating with the Anthropic Claude API.
final class ClaudeAPIService: Sendable {
  static let shared = ClaudeAPIService()

  private let baseURL = "https://api.anthropic.com"
  private let usagePath = "/api/oauth/usage"

  private init() {}

  /// Fetches the current usage data from the Claude API.
  func fetchUsage(token: String) async throws -> UsageResponse {
    guard let url = URL(string: baseURL + usagePath) else {
      throw APIError.invalidURL
    }

    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    request.setValue("oauth-2025-04-20", forHTTPHeaderField: "anthropic-beta")
    request.setValue("claude-code/2.0.32", forHTTPHeaderField: "User-Agent")
    request.setValue("application/json", forHTTPHeaderField: "Accept")

    do {
      let (data, response) = try await URLSession.shared.data(for: request)

      guard let httpResponse = response as? HTTPURLResponse else {
        throw APIError.networkError(NSError(domain: "Invalid response", code: -1))
      }

      guard (200...299).contains(httpResponse.statusCode) else {
        let message = String(data: data, encoding: .utf8)
        throw APIError.httpError(statusCode: httpResponse.statusCode, message: message)
      }

      do {
        return try JSONDecoder().decode(UsageResponse.self, from: data)
      } catch {
        throw APIError.decodingError(error)
      }
    } catch let error as APIError {
      throw error
    } catch {
      throw APIError.networkError(error)
    }
  }
}
