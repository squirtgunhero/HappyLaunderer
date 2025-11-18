//
//  LoginView.swift
//  HappyLaunderer
//
//  Login form view
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(spacing: 20) {
            // Email field
            VStack(alignment: .leading, spacing: 8) {
                Text("Email")
                    .font(.subheadline)
                    .foregroundColor(.white)
                
                TextField("Enter your email", text: $email)
                    .textFieldStyle(.plain)
                    .padding()
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(10)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
            }
            
            // Password field
            VStack(alignment: .leading, spacing: 8) {
                Text("Password")
                    .font(.subheadline)
                    .foregroundColor(.white)
                
                SecureField("Enter your password", text: $password)
                    .textFieldStyle(.plain)
                    .padding()
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(10)
            }
            
            // Error message
            if showError {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal)
            }
            
            // Login button
            Button(action: handleLogin) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                    } else {
                        Text("Log In")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white)
                .foregroundColor(.blue)
                .cornerRadius(10)
            }
            .disabled(isLoading || email.isEmpty || password.isEmpty)
            
            // Forgot password
            Button(action: {
                // Handle forgot password
            }) {
                Text("Forgot Password?")
                    .font(.subheadline)
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 30)
    }
    
    private func handleLogin() {
        isLoading = true
        showError = false
        
        Task {
            do {
                try await authManager.signIn(email: email, password: password)
                await MainActor.run {
                    isLoading = false
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
    LoginView()
        .environmentObject(AuthenticationManager.shared)
        .background(Color.blue)
}

