//
//  AddressPickerView.swift
//  HappyLaunderer
//
//  View for picking or entering an address
//

import SwiftUI

struct AddressPickerView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) var dismiss
    @Binding var selectedAddress: Address?
    
    @State private var street = ""
    @State private var city = ""
    @State private var state = ""
    @State private var zipCode = ""
    
    var body: some View {
        NavigationView {
            Form {
                // Saved addresses
                if let savedAddresses = authManager.currentUser?.savedAddresses, !savedAddresses.isEmpty {
                    Section(header: Text("Saved Addresses")) {
                        ForEach(savedAddresses) { savedAddress in
                            Button(action: {
                                selectedAddress = savedAddress.address
                                dismiss()
                            }) {
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(savedAddress.label)
                                        .font(.headline)
                                    Text(savedAddress.formattedAddress)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
                
                // Enter new address
                Section(header: Text("Enter New Address")) {
                    TextField("Street Address", text: $street)
                    TextField("City", text: $city)
                    TextField("State", text: $state)
                    TextField("ZIP Code", text: $zipCode)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle("Select Address")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Use This") {
                        selectedAddress = Address(
                            street: street,
                            city: city,
                            state: state,
                            zipCode: zipCode,
                            latitude: nil,
                            longitude: nil
                        )
                        dismiss()
                    }
                    .disabled(!isAddressValid)
                }
            }
        }
    }
    
    private var isAddressValid: Bool {
        !street.isEmpty && !city.isEmpty && !state.isEmpty && !zipCode.isEmpty
    }
}

#Preview {
    AddressPickerView(selectedAddress: .constant(nil))
        .environmentObject(AuthenticationManager.shared)
}

