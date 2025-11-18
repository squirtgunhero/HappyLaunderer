//
//  SignUpView.swift
//  HappyLaunderer
//
//  Sign up form view
//

import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(spacing: 20) {
            // Name field
            VStack(alignment: .leading, spacing: 8) {
                Text("Full Name")
                    .font(.subheadline)
                    .foregroundColor(.white)
                
                TextField("Enter your name", text: $name)
                    .textFieldStyle(.plain)
                    .padding()
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(10)
            }
            
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
                
                SecureField("Create a password", text: $password)
                    .textFieldStyle(.plain)
                    .padding()
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(10)
            }
            
            // Confirm password field
            VStack(alignment: .leading, spacing: 8) {
                Text("Confirm Password")
                    .font(.subheadline)
                    .foregroundColor(.white)
                
                SecureField("Confirm your password", text: $confirmPassword)
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
            
            // Sign up button
            Button(action: handleSignUp) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                    } else {
                        Text("Sign Up")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white)
                .foregroundColor(.blue)
                .cornerRadius(10)
            }
            .disabled(isLoading || !isFormValid)
        }
        .padding(.horizontal, 30)
    }
    
    private var isFormValid: Bool {
        !name.isEmpty && !email.isEmpty && !password.isEmpty && password == confirmPassword && password.count >= 8
    }
    
    private func handleSignUp() {
        guard password == confirmPassword else {
            showError = true
            errorMessage = "Passwords do not match"
            return
        }
        
        guard password.count >= 8 else {
            showError = true
            errorMessage = "Password must be at least 8 characters"
            return
        }
        
        isLoading = true
        showError = false
        
        Task {
            do {
                try await authManager.signUp(email: email, password: password, name: name)
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
    SignUpView()
        .environmentObject(AuthenticationManager.shared)
        .background(Color.blue)
}

