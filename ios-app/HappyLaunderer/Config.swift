//
//  Config.swift
//  HappyLaunderer
//
//  Configuration constants for the app
//

import Foundation

struct Config {
    // MARK: - API Configuration
    static let backendAPIURL = "http://localhost:3000/api"
    
    // MARK: - Clerk Configuration
    static let clerkPublishableKey = "pk_test_your_clerk_publishable_key_here"
    
    // MARK: - Stripe Configuration
    static let stripePublishableKey = "pk_test_your_stripe_publishable_key_here"
    
    // MARK: - Feature Flags
    static let enablePushNotifications = true
    static let enableRealTimeTracking = true
    
    // MARK: - App Constants
    static let defaultServiceType = ServiceType.standard
    static let maxSavedAddresses = 5
    
    // MARK: - Helper Methods
    static func apiEndpoint(_ path: String) -> String {
        return "\(backendAPIURL)\(path)"
    }
}

