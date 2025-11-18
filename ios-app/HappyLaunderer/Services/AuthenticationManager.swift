//
//  AuthenticationManager.swift
//  HappyLaunderer
//
//  Manages authentication state with Clerk
//

import Foundation
import SwiftUI

class AuthenticationManager: ObservableObject {
    static let shared = AuthenticationManager()
    
    @Published var isAuthenticated = false
    @Published var isLoading = true
    @Published var currentUser: User?
    @Published var authToken: String?
    
    private let apiClient = APIClient.shared
    
    private init() {
        // Check for stored auth token
        checkAuthStatus()
    }
    
    func checkAuthStatus() {
        isLoading = true
        
        // Check if we have a stored token
        if let token = UserDefaults.standard.string(forKey: "authToken") {
            authToken = token
            
            // Verify token by fetching user profile
            Task {
                do {
                    try await fetchUserProfile()
                    await MainActor.run {
                        isAuthenticated = true
                        isLoading = false
                    }
                } catch {
                    print("Token verification failed: \(error)")
                    await MainActor.run {
                        logout()
                    }
                }
            }
        } else {
            isLoading = false
        }
    }
    
    // MARK: - Authentication Methods
    
    func signIn(email: String, password: String) async throws {
        // Note: In a real implementation, you would use Clerk's iOS SDK
        // This is a simplified version that assumes you're using a custom backend integration
        
        // For now, this is a placeholder that would need to integrate with Clerk
        // The actual Clerk SDK handles OAuth, social sign-in, etc.
        throw APIError.serverError("Please integrate Clerk SDK for authentication")
    }
    
    func signUp(email: String, password: String, name: String) async throws {
        // Note: In a real implementation, you would use Clerk's iOS SDK
        // This is a placeholder
        throw APIError.serverError("Please integrate Clerk SDK for authentication")
    }
    
    func setAuthToken(_ token: String) {
        authToken = token
        UserDefaults.standard.set(token, forKey: "authToken")
        isAuthenticated = true
    }
    
    func logout() {
        authToken = nil
        currentUser = nil
        isAuthenticated = false
        UserDefaults.standard.removeObject(forKey: "authToken")
    }
    
    // MARK: - User Profile Methods
    
    func fetchUserProfile() async throws {
        guard let token = authToken else {
            throw APIError.unauthorized
        }
        
        let response: UserResponse = try await apiClient.get(
            endpoint: Config.apiEndpoint("/auth/profile"),
            token: token
        )
        
        await MainActor.run {
            self.currentUser = response.user
        }
    }
    
    func updateProfile(name: String?, phone: String?, defaultAddress: Address?) async throws {
        guard let token = authToken else {
            throw APIError.unauthorized
        }
        
        struct UpdateProfileRequest: Codable {
            let name: String?
            let phone: String?
            let defaultAddress: Address?
        }
        
        let request = UpdateProfileRequest(
            name: name,
            phone: phone,
            defaultAddress: defaultAddress
        )
        
        let response: UserResponse = try await apiClient.put(
            endpoint: Config.apiEndpoint("/auth/profile"),
            body: request,
            token: token
        )
        
        await MainActor.run {
            self.currentUser = response.user
        }
    }
    
    func addSavedAddress(_ address: SavedAddress) async throws {
        guard let token = authToken else {
            throw APIError.unauthorized
        }
        
        let response: UserResponse = try await apiClient.post(
            endpoint: Config.apiEndpoint("/auth/profile/addresses"),
            body: address,
            token: token
        )
        
        await MainActor.run {
            self.currentUser = response.user
        }
    }
    
    func removeSavedAddress(at index: Int) async throws {
        guard let token = authToken else {
            throw APIError.unauthorized
        }
        
        let response: UserResponse = try await apiClient.delete(
            endpoint: Config.apiEndpoint("/auth/profile/addresses/\(index)"),
            token: token
        )
        
        await MainActor.run {
            self.currentUser = response.user
        }
    }
}

