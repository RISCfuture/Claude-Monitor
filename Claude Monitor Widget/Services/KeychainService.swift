//
//  KeychainService.swift
//  Claude Monitor Widget
//

import Foundation
import Security

/// Errors that can occur when accessing the macOS Keychain.
enum KeychainError: Error {
  case itemNotFound
  case unexpectedStatus(OSStatus)
  case invalidData
}

/// The source of an OAuth token.
enum TokenSource: String {
  case claudeCode
  case manual
}

/// A service for secure token retrieval using the macOS Keychain.
/// This widget version only reads tokens; it cannot write them.
final class KeychainService: Sendable {
  static let shared = KeychainService()

  private let appServiceName = "codes.tim.Claude-Monitor"
  private let appAccountName = "api-token"
  private let claudeCodeServiceName = "Claude Code-credentials"

  private init() {}

  /// Reads the OAuth token from Claude Code's Keychain entry.
  func readClaudeCodeToken() throws -> String {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: claudeCodeServiceName,
      kSecReturnData as String: true,
      kSecMatchLimit as String: kSecMatchLimitOne
    ]

    var result: AnyObject?
    let status = SecItemCopyMatching(query as CFDictionary, &result)

    guard status == errSecSuccess else {
      if status == errSecItemNotFound {
        throw KeychainError.itemNotFound
      }
      throw KeychainError.unexpectedStatus(status)
    }

    guard let data = result as? Data,
      let jsonString = String(data: data, encoding: .utf8)
    else {
      throw KeychainError.invalidData
    }

    return try parseClaudeCodeCredentials(jsonString)
  }

  private func parseClaudeCodeCredentials(_ json: String) throws -> String {
    guard let data = json.data(using: .utf8) else {
      throw KeychainError.invalidData
    }

    struct Credentials: Codable {
      let claudeAiOauth: OAuth

      struct OAuth: Codable {
        let accessToken: String
      }
    }

    let credentials = try JSONDecoder().decode(Credentials.self, from: data)
    return credentials.claudeAiOauth.accessToken
  }

  /// Reads the manually-entered token from the app's Keychain entry.
  /// Note: Without keychain access groups, this may not work in widget context.
  func readManualToken() throws -> String {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: appServiceName,
      kSecAttrAccount as String: appAccountName,
      kSecReturnData as String: true,
      kSecMatchLimit as String: kSecMatchLimitOne
    ]

    var result: AnyObject?
    let status = SecItemCopyMatching(query as CFDictionary, &result)

    guard status == errSecSuccess else {
      if status == errSecItemNotFound {
        throw KeychainError.itemNotFound
      }
      throw KeychainError.unexpectedStatus(status)
    }

    guard let data = result as? Data,
      let token = String(data: data, encoding: .utf8)
    else {
      throw KeychainError.invalidData
    }

    return token
  }

  /// Resolves the best available token.
  func resolveToken(preferredSource: TokenSource) -> (token: String, source: TokenSource)? {
    switch preferredSource {
      case .claudeCode:
        if let token = try? readClaudeCodeToken() {
          return (token, .claudeCode)
        }
      case .manual:
        if let token = try? readManualToken() {
          return (token, .manual)
        }
    }

    // Fallback: try the other source
    if let token = try? readClaudeCodeToken() {
      return (token, .claudeCode)
    }
    if let token = try? readManualToken() {
      return (token, .manual)
    }

    return nil
  }
}
