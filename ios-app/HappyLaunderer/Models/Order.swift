//
//  Order.swift
//  HappyLaunderer
//
//  Order model
//

import Foundation

struct Order: Codable, Identifiable {
    let id: String
    let userId: String
    let pickupAddress: Address
    let deliveryAddress: Address
    let scheduledTime: Date
    var status: OrderStatus
    let serviceType: ServiceType
    var itemCount: Int
    let price: Double
    var driverId: String?
    var driverLocation: DriverLocation?
    var notes: String?
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case pickupAddress = "pickup_address"
        case deliveryAddress = "delivery_address"
        case scheduledTime = "scheduled_time"
        case status
        case serviceType = "service_type"
        case itemCount = "item_count"
        case price
        case driverId = "driver_id"
        case driverLocation = "driver_location"
        case notes
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

enum OrderStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case pickedUp = "picked_up"
    case inLaundry = "in_laundry"
    case ready = "ready"
    case outForDelivery = "out_for_delivery"
    case completed = "completed"
    case cancelled = "cancelled"
    
    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .pickedUp: return "Picked Up"
        case .inLaundry: return "In Laundry"
        case .ready: return "Ready"
        case .outForDelivery: return "Out for Delivery"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        }
    }
    
    var systemImage: String {
        switch self {
        case .pending: return "clock"
        case .pickedUp: return "shippingbox"
        case .inLaundry: return "washer"
        case .ready: return "checkmark.circle"
        case .outForDelivery: return "truck.box"
        case .completed: return "checkmark.circle.fill"
        case .cancelled: return "xmark.circle"
        }
    }
    
    var color: String {
        switch self {
        case .pending: return "orange"
        case .pickedUp: return "blue"
        case .inLaundry: return "purple"
        case .ready: return "green"
        case .outForDelivery: return "blue"
        case .completed: return "green"
        case .cancelled: return "red"
        }
    }
}

enum ServiceType: String, Codable, CaseIterable {
    case standard = "standard"
    case express = "express"
    case premium = "premium"
    
    var displayName: String {
        switch self {
        case .standard: return "Standard"
        case .express: return "Express"
        case .premium: return "Premium"
        }
    }
    
    var description: String {
        switch self {
        case .standard: return "3-5 business days"
        case .express: return "24-48 hours"
        case .premium: return "Same day delivery"
        }
    }
    
    var basePrice: Double {
        switch self {
        case .standard: return 25.00
        case .express: return 40.00
        case .premium: return 60.00
        }
    }
    
    var features: [String] {
        switch self {
        case .standard:
            return ["Wash and fold", "Basic detergent", "Standard packaging"]
        case .express:
            return ["Wash and fold", "Premium detergent", "Next-day delivery", "Eco-friendly packaging"]
        case .premium:
            return ["Wash and fold", "Luxury detergent", "Same-day delivery", "Hand washing available", "Premium packaging", "Stain treatment included"]
        }
    }
}

struct DriverLocation: Codable {
    let latitude: Double
    let longitude: Double
    let timestamp: Date
}

struct OrderStatusHistory: Codable, Identifiable {
    let id: String
    let orderId: String
    let oldStatus: OrderStatus?
    let newStatus: OrderStatus
    let changedBy: String?
    let notes: String?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case orderId = "order_id"
        case oldStatus = "old_status"
        case newStatus = "new_status"
        case changedBy = "changed_by"
        case notes
        case createdAt = "created_at"
    }
}

// MARK: - API Request/Response Models
struct CreateOrderRequest: Codable {
    let pickupAddress: Address
    let deliveryAddress: Address
    let scheduledTime: Date
    let serviceType: ServiceType
    let itemCount: Int
    let notes: String?
}

struct OrderResponse: Codable {
    let success: Bool
    let order: Order
    let statusHistory: [OrderStatusHistory]?
}

struct OrdersResponse: Codable {
    let success: Bool
    let orders: [Order]
    let count: Int
}

