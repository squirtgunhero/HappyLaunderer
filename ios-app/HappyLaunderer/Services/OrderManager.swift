//
//  OrderManager.swift
//  HappyLaunderer
//
//  Manages orders and order-related operations
//

import Foundation

class OrderManager: ObservableObject {
    static let shared = OrderManager()
    
    @Published var orders: [Order] = []
    @Published var activeOrders: [Order] = []
    @Published var isLoading = false
    
    private let apiClient = APIClient.shared
    private var authManager = AuthenticationManager.shared
    
    // Track active polling tasks for cancellation
    private var pollingTasks: [String: Task<Void, Never>] = [:]
    
    private init() {}
    
    // MARK: - Order Creation
    
    func createOrder(
        pickupAddress: Address,
        deliveryAddress: Address,
        scheduledTime: Date,
        serviceType: ServiceType,
        itemCount: Int,
        notes: String?
    ) async throws -> Order {
        guard let token = authManager.authToken else {
            throw APIError.unauthorized
        }
        
        let request = CreateOrderRequest(
            pickupAddress: pickupAddress,
            deliveryAddress: deliveryAddress,
            scheduledTime: scheduledTime,
            serviceType: serviceType,
            itemCount: itemCount,
            notes: notes
        )
        
        let response: OrderResponse = try await apiClient.post(
            endpoint: Config.apiEndpoint("/orders"),
            body: request,
            token: token
        )
        
        await MainActor.run {
            self.orders.insert(response.order, at: 0)
            if !response.order.status.isCompleted {
                self.activeOrders.insert(response.order, at: 0)
            }
        }
        
        return response.order
    }
    
    // MARK: - Fetching Orders
    
    func fetchOrders(status: OrderStatus? = nil) async throws {
        guard let token = authManager.authToken else {
            throw APIError.unauthorized
        }
        
        await MainActor.run {
            self.isLoading = true
        }
        
        var endpoint = Config.apiEndpoint("/orders")
        if let status = status {
            endpoint += "?status=\(status.rawValue)"
        }
        
        let response: OrdersResponse = try await apiClient.get(
            endpoint: endpoint,
            token: token
        )
        
        await MainActor.run {
            self.orders = response.orders
            self.activeOrders = response.orders.filter { !$0.status.isCompleted }
            self.isLoading = false
        }
    }
    
    func fetchOrderDetails(orderId: String) async throws -> (Order, [OrderStatusHistory]) {
        guard let token = authManager.authToken else {
            throw APIError.unauthorized
        }
        
        let response: OrderResponse = try await apiClient.get(
            endpoint: Config.apiEndpoint("/orders/\(orderId)"),
            token: token
        )
        
        // Update local cache
        await MainActor.run {
            if let index = self.orders.firstIndex(where: { $0.id == orderId }) {
                self.orders[index] = response.order
            }
            
            if let index = self.activeOrders.firstIndex(where: { $0.id == orderId }) {
                if response.order.status.isCompleted {
                    self.activeOrders.remove(at: index)
                } else {
                    self.activeOrders[index] = response.order
                }
            }
        }
        
        return (response.order, response.statusHistory ?? [])
    }
    
    // MARK: - Order Actions
    
    func cancelOrder(orderId: String) async throws {
        guard let token = authManager.authToken else {
            throw APIError.unauthorized
        }
        
        struct EmptyBody: Codable {}
        
        let response: OrderResponse = try await apiClient.post(
            endpoint: Config.apiEndpoint("/orders/\(orderId)/cancel"),
            body: EmptyBody(),
            token: token
        )
        
        await MainActor.run {
            if let index = self.orders.firstIndex(where: { $0.id == orderId }) {
                self.orders[index] = response.order
            }
            
            if let index = self.activeOrders.firstIndex(where: { $0.id == orderId }) {
                self.activeOrders.remove(at: index)
            }
        }
    }
    
    // MARK: - Real-time Updates
    
    /// Start polling for order updates every 30 seconds
    /// - Parameter orderId: The order ID to poll for updates
    /// - Returns: A Task that can be cancelled to stop polling
    @discardableResult
    func startRealTimeUpdates(for orderId: String) -> Task<Void, Never> {
        // Cancel any existing polling task for this order
        stopRealTimeUpdates(for: orderId)
        
        // Create a new polling task
        let task = Task {
            // Poll for updates every 30 seconds
            while !Task.isCancelled {
                // Wait 30 seconds before next update
                try? await Task.sleep(nanoseconds: 30_000_000_000)
                
                // Check if task was cancelled during sleep
                if Task.isCancelled {
                    break
                }
                
                do {
                    let (order, _) = try await fetchOrderDetails(orderId: orderId)
                    
                    // Stop polling if order is completed or cancelled
                    if order.status.isCompleted {
                        await MainActor.run {
                            self.stopRealTimeUpdates(for: orderId)
                        }
                        break
                    }
                } catch {
                    print("Failed to fetch order updates: \(error)")
                    // Continue polling even if one request fails
                }
            }
            
            // Clean up when task completes
            await MainActor.run {
                self.pollingTasks.removeValue(forKey: orderId)
            }
        }
        
        // Store the task for later cancellation
        pollingTasks[orderId] = task
        
        return task
    }
    
    /// Stop polling for order updates
    /// - Parameter orderId: The order ID to stop polling for
    func stopRealTimeUpdates(for orderId: String) {
        pollingTasks[orderId]?.cancel()
        pollingTasks.removeValue(forKey: orderId)
    }
    
    /// Stop all active polling tasks
    func stopAllRealTimeUpdates() {
        for task in pollingTasks.values {
            task.cancel()
        }
        pollingTasks.removeAll()
    }
}

// MARK: - OrderStatus Extension
extension OrderStatus {
    var isCompleted: Bool {
        return self == .completed || self == .cancelled
    }
    
    var isActive: Bool {
        return !isCompleted
    }
}

