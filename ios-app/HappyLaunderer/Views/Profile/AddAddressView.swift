//
//  AddAddressView.swift
//  HappyLaunderer
//
//  Add a new saved address
//

import SwiftUI

struct AddAddressView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) var dismiss
    
    @State private var label = ""
    @State private var street = ""
    @State private var city = ""
    @State private var state = ""
    @State private var zipCode = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Address Label")) {
                    TextField("e.g., Home, Work", text: $label)
                }
                
                Section(header: Text("Address Details")) {
                    TextField("Street Address", text: $street)
                    TextField("City", text: $city)
                    TextField("State", text: $state)
                    TextField("ZIP Code", text: $zipCode)
                        .keyboardType(.numberPad)
                }
                
                if showError {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Add Address")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: saveAddress) {
                        if isLoading {
                            ProgressView()
                        } else {
                            Text("Save")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(isLoading || !isFormValid)
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        !label.isEmpty && !street.isEmpty && !city.isEmpty && !state.isEmpty && !zipCode.isEmpty
    }
    
    private func saveAddress() {
        isLoading = true
        showError = false
        
        let address = SavedAddress(
            label: label,
            street: street,
            city: city,
            state: state,
            zipCode: zipCode,
            latitude: nil,
            longitude: nil
        )
        
        Task {
            do {
                try await authManager.addSavedAddress(address)
                await MainActor.run {
                    isLoading = false
                    dismiss()
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
    AddAddressView()
        .environmentObject(AuthenticationManager.shared)
}

