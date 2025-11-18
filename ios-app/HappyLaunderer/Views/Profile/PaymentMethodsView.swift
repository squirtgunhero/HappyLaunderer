//
//  PaymentMethodsView.swift
//  HappyLaunderer
//
//  View for managing payment methods via Clerk/Stripe
//

import SwiftUI

struct PaymentMethodsView: View {
    @State private var showAddPaymentMethod = false
    @State private var paymentMethods: [PaymentMethod] = []
    
    var body: some View {
        List {
            Section {
                if paymentMethods.isEmpty {
                    VStack(spacing: 15) {
                        Image(systemName: "creditcard")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        
                        Text("No payment methods")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("Add a payment method to checkout faster")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button(action: {
                            showAddPaymentMethod = true
                        }) {
                            Text("Add Payment Method")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    ForEach(paymentMethods) { method in
                        PaymentMethodRow(paymentMethod: method)
                    }
                    .onDelete(perform: deletePaymentMethod)
                }
            }
            
            if !paymentMethods.isEmpty {
                Section {
                    Button(action: {
                        showAddPaymentMethod = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                            Text("Add Payment Method")
                        }
                    }
                }
            }
        }
        .navigationTitle("Payment Methods")
        .sheet(isPresented: $showAddPaymentMethod) {
            AddPaymentMethodView()
        }
    }
    
    private func deletePaymentMethod(at offsets: IndexSet) {
        // TODO: Implement payment method deletion via Clerk/Stripe
        paymentMethods.remove(atOffsets: offsets)
    }
}

struct PaymentMethod: Identifiable {
    let id = UUID()
    let type: String // "card", "apple_pay", etc.
    let last4: String
    let brand: String // "visa", "mastercard", etc.
    let expiryMonth: Int
    let expiryYear: Int
    let isDefault: Bool
}

struct PaymentMethodRow: View {
    let paymentMethod: PaymentMethod
    
    var body: some View {
        HStack(spacing: 15) {
            // Card icon
            Image(systemName: cardIcon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(paymentMethod.brand.capitalized)
                        .font(.headline)
                    
                    if paymentMethod.isDefault {
                        Text("Default")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.2))
                            .foregroundColor(.blue)
                            .cornerRadius(4)
                    }
                }
                
                Text("•••• \(paymentMethod.last4)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("Expires \(paymentMethod.expiryMonth)/\(paymentMethod.expiryYear)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
    
    private var cardIcon: String {
        switch paymentMethod.brand.lowercased() {
        case "visa":
            return "creditcard.fill"
        case "mastercard":
            return "creditcard.fill"
        case "amex":
            return "creditcard.fill"
        default:
            return "creditcard"
        }
    }
}

struct AddPaymentMethodView: View {
    @Environment(\.dismiss) var dismiss
    @State private var cardNumber = ""
    @State private var expiryDate = ""
    @State private var cvv = ""
    @State private var zipCode = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Card Information")) {
                    TextField("Card Number", text: $cardNumber)
                        .keyboardType(.numberPad)
                    
                    HStack {
                        TextField("MM/YY", text: $expiryDate)
                            .keyboardType(.numberPad)
                        
                        TextField("CVV", text: $cvv)
                            .keyboardType(.numberPad)
                    }
                    
                    TextField("ZIP Code", text: $zipCode)
                        .keyboardType(.numberPad)
                }
                
                Section {
                    HStack {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.green)
                        Text("Your payment information is secure and encrypted")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if showError {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Add Payment Method")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: addPaymentMethod) {
                        if isLoading {
                            ProgressView()
                        } else {
                            Text("Add")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(isLoading || !isFormValid)
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        !cardNumber.isEmpty && !expiryDate.isEmpty && !cvv.isEmpty && !zipCode.isEmpty
    }
    
    private func addPaymentMethod() {
        isLoading = true
        showError = false
        
        // TODO: Implement Stripe payment method creation via Clerk
        Task {
            await MainActor.run {
                isLoading = false
                dismiss()
            }
        }
    }
}

#Preview {
    NavigationView {
        PaymentMethodsView()
    }
}

