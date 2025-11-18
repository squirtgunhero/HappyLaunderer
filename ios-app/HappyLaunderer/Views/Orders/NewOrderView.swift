//
//  NewOrderView.swift
//  HappyLaunderer
//
//  Form to create a new order
//

import SwiftUI

struct NewOrderView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var orderManager: OrderManager
    @Environment(\.dismiss) var dismiss
    
    @State private var pickupAddress: Address?
    @State private var deliveryAddress: Address?
    @State private var scheduledDate = Date().addingTimeInterval(3600) // 1 hour from now
    @State private var serviceType: ServiceType = .standard
    @State private var itemCount = 1
    @State private var notes = ""
    @State private var useDefaultAddressForPickup = false
    @State private var useDefaultAddressForDelivery = false
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showingAddressPicker = false
    @State private var addressPickerMode: AddressMode = .pickup
    @State private var showSuccessMessage = false
    
    enum AddressMode {
        case pickup
        case delivery
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Pickup Address Section
                Section(header: Text("Pickup Address")) {
                    if let address = pickupAddress {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(address.formattedAddress)
                                .font(.body)
                        }
                        
                        Button("Change Address") {
                            addressPickerMode = .pickup
                            showingAddressPicker = true
                        }
                    } else {
                        Button("Select Pickup Address") {
                            addressPickerMode = .pickup
                            showingAddressPicker = true
                        }
                    }
                    
                    if let defaultAddress = authManager.currentUser?.defaultAddress {
                        Toggle("Use Default Address", isOn: $useDefaultAddressForPickup)
                            .onChange(of: useDefaultAddressForPickup) { oldValue, newValue in
                                if newValue {
                                    pickupAddress = defaultAddress
                                } else {
                                    pickupAddress = nil
                                }
                            }
                    }
                }
                
                // Delivery Address Section
                Section(header: Text("Delivery Address")) {
                    if let address = deliveryAddress {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(address.formattedAddress)
                                .font(.body)
                        }
                        
                        Button("Change Address") {
                            addressPickerMode = .delivery
                            showingAddressPicker = true
                        }
                    } else {
                        Button("Select Delivery Address") {
                            addressPickerMode = .delivery
                            showingAddressPicker = true
                        }
                    }
                    
                    Button("Same as Pickup") {
                        deliveryAddress = pickupAddress
                    }
                    .disabled(pickupAddress == nil)
                }
                
                // Schedule Section
                Section(header: Text("Schedule")) {
                    DatePicker(
                        "Pickup Time",
                        selection: $scheduledDate,
                        in: Date()...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                }
                
                // Service Type Section
                Section(header: Text("Service Type")) {
                    Picker("Service", selection: $serviceType) {
                        ForEach(ServiceType.allCases, id: \.self) { type in
                            VStack(alignment: .leading) {
                                Text(type.displayName)
                                Text(type.description)
                                    .font(.caption)
                            }
                            .tag(type)
                        }
                    }
                    .pickerStyle(.inline)
                    
                    HStack {
                        Text("Price")
                            .fontWeight(.semibold)
                        Spacer()
                        Text("$\(String(format: "%.2f", serviceType.basePrice))")
                            .foregroundColor(.blue)
                            .fontWeight(.bold)
                    }
                }
                
                // Additional Details Section
                Section(header: Text("Additional Details")) {
                    Stepper("Items: \(itemCount)", value: $itemCount, in: 1...50)
                    
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                // Error Message
                if showError {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("New Order")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: createOrder) {
                        if isLoading {
                            ProgressView()
                        } else {
                            Text("Create Order")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(isLoading || !isFormValid)
                }
            }
            .sheet(isPresented: $showingAddressPicker) {
                AddressPickerView(selectedAddress: addressPickerMode == .pickup ? $pickupAddress : $deliveryAddress)
            }
            .alert("Order Created!", isPresented: $showSuccessMessage) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your laundry pickup has been scheduled successfully.")
            }
        }
    }
    
    private var isFormValid: Bool {
        pickupAddress != nil && deliveryAddress != nil
    }
    
    private func createOrder() {
        guard let pickup = pickupAddress,
              let delivery = deliveryAddress else {
            showError = true
            errorMessage = "Please select both pickup and delivery addresses"
            return
        }
        
        isLoading = true
        showError = false
        
        Task {
            do {
                _ = try await orderManager.createOrder(
                    pickupAddress: pickup,
                    deliveryAddress: delivery,
                    scheduledTime: scheduledDate,
                    serviceType: serviceType,
                    itemCount: itemCount,
                    notes: notes.isEmpty ? nil : notes
                )
                
                await MainActor.run {
                    isLoading = false
                    showSuccessMessage = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    showError = true
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

#Preview {
    NewOrderView()
        .environmentObject(AuthenticationManager.shared)
        .environmentObject(OrderManager.shared)
}

