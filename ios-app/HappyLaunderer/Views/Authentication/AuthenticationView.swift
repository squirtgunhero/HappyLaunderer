//
//  AuthenticationView.swift
//  HappyLaunderer
//
//  Main authentication view (login/signup)
//

import SwiftUI

struct AuthenticationView: View {
    @State private var isSignUp = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.4)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    // Logo and title
                    VStack(spacing: 15) {
                        Image(systemName: "tshirt.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.white)
                        
                        Text("Happy Launderer")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Laundry made easy")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .padding(.top, 60)
                    
                    Spacer()
                    
                    // Auth form
                    if isSignUp {
                        SignUpView()
                    } else {
                        LoginView()
                    }
                    
                    // Toggle between login and signup
                    Button(action: {
                        withAnimation {
                            isSignUp.toggle()
                        }
                    }) {
                        HStack {
                            Text(isSignUp ? "Already have an account?" : "Don't have an account?")
                                .foregroundColor(.white)
                            Text(isSignUp ? "Log In" : "Sign Up")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                        .padding()
                    }
                    
                    Spacer()
                }
            }
        }
    }
}

#Preview {
    AuthenticationView()
        .environmentObject(AuthenticationManager.shared)
}

