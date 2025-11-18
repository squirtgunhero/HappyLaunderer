//
//  ProfileSetupView.swift
//  HappyLaunderer
//
//  Initial profile setup after registration
//

import SwiftUI

struct ProfileSetupView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) var dismiss
    
    @State private var name = ""
    @State private var phone = ""
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
                Section(header: Text("Personal Information")) {
                    TextField("Full Name", text: $name)
                    TextField("Phone Number", text: $phone)
                        .keyboardType(.phonePad)
                }
                
                Section(header: Text("Default Address")) {
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
            .navigationTitle("Complete Your Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Skip") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: saveProfile) {
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
        !name.isEmpty && !phone.isEmpty && !street.isEmpty && !city.isEmpty && !state.isEmpty && !zipCode.isEmpty
    }
    
    private func saveProfile() {
        isLoading = true
        showError = false
        
        let address = Address(
            street: street,
            city: city,
            state: state,
            zipCode: zipCode,
            latitude: nil,
            longitude: nil
        )
        
        Task {
            do {
                try await authManager.updateProfile(
                    name: name,
                    phone: phone,
                    defaultAddress: address
                )
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
    ProfileSetupView()
        .environmentObject(AuthenticationManager.shared)
}

