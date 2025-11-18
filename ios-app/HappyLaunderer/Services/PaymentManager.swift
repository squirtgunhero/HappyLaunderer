//
//  PaymentManager.swift
//  HappyLaunderer
//
//  Manages payment processing with Stripe via Clerk
//

import Foundation

class PaymentManager: ObservableObject {
    static let shared = PaymentManager()
    
    @Published var payments: [Payment] = []
    @Published var isProcessing = false
    
    private let apiClient = APIClient.shared
    private var authManager = AuthenticationManager.shared
    
    private init() {}
    
    // MARK: - Payment Processing
    
    func processPayment(orderId: String, paymentMethodId: String) async throws -> Payment {
        guard let token = authManager.authToken else {
            throw APIError.unauthorized
        }
        
        await MainActor.run {
            self.isProcessing = true
        }
        
        let request = ProcessPaymentRequest(
            orderId: orderId,
            paymentMethodId: paymentMethodId
        )
        
        do {
            let response: PaymentResponse = try await apiClient.post(
                endpoint: Config.apiEndpoint("/payments/charge"),
                body: request,
                token: token
            )
            
            await MainActor.run {
                self.payments.insert(response.payment, at: 0)
                self.isProcessing = false
            }
            
            return response.payment
        } catch {
            await MainActor.run {
                self.isProcessing = false
            }
            throw error
        }
    }
    
    // MARK: - Fetching Payments
    
    func fetchPayments() async throws {
        guard let token = authManager.authToken else {
            throw APIError.unauthorized
        }
        
        let response: PaymentsResponse = try await apiClient.get(
            endpoint: Config.apiEndpoint("/payments"),
            token: token
        )
        
        await MainActor.run {
            self.payments = response.payments
        }
    }
    
    func fetchPaymentForOrder(orderId: String) async throws -> Payment {
        guard let token = authManager.authToken else {
            throw APIError.unauthorized
        }
        
        let response: PaymentResponse = try await apiClient.get(
            endpoint: Config.apiEndpoint("/payments/\(orderId)"),
            token: token
        )
        
        return response.payment
    }
}

