//
//  Payment.swift
//  HappyLaunderer
//
//  Payment model
//

import Foundation

struct Payment: Codable, Identifiable {
    let id: String
    let orderId: String
    let userId: String
    let stripePaymentId: String?
    let stripePaymentIntentId: String?
    let amount: Double
    var status: PaymentStatus
    let paymentMethodId: String?
    let errorMessage: String?
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case orderId = "order_id"
        case userId = "user_id"
        case stripePaymentId = "stripe_payment_id"
        case stripePaymentIntentId = "stripe_payment_intent_id"
        case amount
        case status
        case paymentMethodId = "payment_method_id"
        case errorMessage = "error_message"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

enum PaymentStatus: String, Codable {
    case pending = "pending"
    case completed = "completed"
    case failed = "failed"
    case refunded = "refunded"
    
    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .completed: return "Completed"
        case .failed: return "Failed"
        case .refunded: return "Refunded"
        }
    }
}

// MARK: - API Request/Response Models
struct ProcessPaymentRequest: Codable {
    let orderId: String
    let paymentMethodId: String
}

struct PaymentResponse: Codable {
    let success: Bool
    let payment: Payment
    let clientSecret: String?
}

struct PaymentsResponse: Codable {
    let success: Bool
    let payments: [Payment]
}

