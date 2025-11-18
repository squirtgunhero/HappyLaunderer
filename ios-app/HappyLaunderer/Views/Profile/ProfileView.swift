//
//  ProfileView.swift
//  HappyLaunderer
//
//  User profile and settings view
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showEditProfile = false
    @State private var showAddAddress = false
    
    var body: some View {
        NavigationView {
            List {
                // User info section
                Section {
                    HStack(spacing: 15) {
                        Circle()
                            .fill(Color.blue.gradient)
                            .frame(width: 60, height: 60)
                            .overlay(
                                Text(authManager.currentUser?.name?.prefix(1).uppercased() ?? "U")
                                    .font(.title)
                                    .foregroundColor(.white)
                            )
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text(authManager.currentUser?.name ?? "User")
                                .font(.title3)
                                .fontWeight(.bold)
                            
                            if let phone = authManager.currentUser?.phone {
                                Text(phone)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            showEditProfile = true
                        }) {
                            Text("Edit")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                // Default address
                if let defaultAddress = authManager.currentUser?.defaultAddress {
                    Section(header: Text("Default Address")) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(defaultAddress.formattedAddress)
                                .font(.body)
                        }
                    }
                }
                
                // Saved addresses
                Section(header: HStack {
                    Text("Saved Addresses")
                    Spacer()
                    Button(action: {
                        showAddAddress = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.blue)
                    }
                }) {
                    if let savedAddresses = authManager.currentUser?.savedAddresses,
                       !savedAddresses.isEmpty {
                        ForEach(Array(savedAddresses.enumerated()), id: \.element.id) { index, address in
                            VStack(alignment: .leading, spacing: 5) {
                                Text(address.label)
                                    .font(.headline)
                                Text(address.formattedAddress)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    Task {
                                        try? await authManager.removeSavedAddress(at: index)
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    } else {
                        Text("No saved addresses")
                            .foregroundColor(.secondary)
                    }
                }
                
                // Settings
                Section(header: Text("Settings")) {
                    NavigationLink(destination: NotificationSettingsView()) {
                        Label("Notifications", systemImage: "bell")
                    }
                    
                    NavigationLink(destination: PaymentMethodsView()) {
                        Label("Payment Methods", systemImage: "creditcard")
                    }
                }
                
                // Account actions
                Section {
                    Button(action: {
                        authManager.logout()
                    }) {
                        HStack {
                            Label("Log Out", systemImage: "arrow.right.square")
                            Spacer()
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Profile")
            .sheet(isPresented: $showEditProfile) {
                EditProfileView()
            }
            .sheet(isPresented: $showAddAddress) {
                AddAddressView()
            }
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthenticationManager.shared)
}

