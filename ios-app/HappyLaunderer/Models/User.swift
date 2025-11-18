//
//  User.swift
//  HappyLaunderer
//
//  User model
//

import Foundation

struct User: Codable, Identifiable {
    let id: String
    let clerkId: String
    var name: String?
    var phone: String?
    var defaultAddress: Address?
    var savedAddresses: [SavedAddress]
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case clerkId = "clerk_id"
        case name
        case phone
        case defaultAddress = "default_address"
        case savedAddresses = "saved_addresses"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct Address: Codable, Hashable {
    var street: String
    var city: String
    var state: String
    var zipCode: String
    var latitude: Double?
    var longitude: Double?
    
    enum CodingKeys: String, CodingKey {
        case street
        case city
        case state
        case zipCode = "zipCode"
        case latitude
        case longitude
    }
    
    var formattedAddress: String {
        return "\(street), \(city), \(state) \(zipCode)"
    }
}

struct SavedAddress: Codable, Identifiable {
    var id = UUID()
    var label: String
    var street: String
    var city: String
    var state: String
    var zipCode: String
    var latitude: Double?
    var longitude: Double?
    
    enum CodingKeys: String, CodingKey {
        case label
        case street
        case city
        case state
        case zipCode = "zipCode"
        case latitude
        case longitude
    }
    
    var address: Address {
        return Address(
            street: street,
            city: city,
            state: state,
            zipCode: zipCode,
            latitude: latitude,
            longitude: longitude
        )
    }
    
    var formattedAddress: String {
        return "\(street), \(city), \(state) \(zipCode)"
    }
}

// MARK: - API Response Models
struct UserResponse: Codable {
    let success: Bool
    let user: User
}

