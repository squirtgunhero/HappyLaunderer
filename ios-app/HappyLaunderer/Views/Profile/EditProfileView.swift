//
//  EditProfileView.swift
//  HappyLaunderer
//
//  Edit user profile
//

import SwiftUI

struct EditProfileView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) var dismiss
    
    @State private var name: String
    @State private var phone: String
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    init() {
        _name = State(initialValue: AuthenticationManager.shared.currentUser?.name ?? "")
        _phone = State(initialValue: AuthenticationManager.shared.currentUser?.phone ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Personal Information")) {
                    TextField("Full Name", text: $name)
                    TextField("Phone Number", text: $phone)
                        .keyboardType(.phonePad)
                }
                
                if showError {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
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
                    .disabled(isLoading || name.isEmpty || phone.isEmpty)
                }
            }
        }
    }
    
    private func saveProfile() {
        isLoading = true
        showError = false
        
        Task {
            do {
                try await authManager.updateProfile(
                    name: name,
                    phone: phone,
                    defaultAddress: nil
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
    EditProfileView()
        .environmentObject(AuthenticationManager.shared)
}

