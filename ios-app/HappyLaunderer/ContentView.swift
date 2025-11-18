//
//  ContentView.swift
//  HappyLaunderer
//
//  Main content view that handles navigation based on auth state
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        Group {
            if authManager.isLoading {
                LoadingView()
            } else if authManager.isAuthenticated {
                MainTabView()
            } else {
                AuthenticationView()
            }
        }
    }
}

struct LoadingView: View {
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: "tshirt.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Happy Launderer")
                    .font(.title)
                    .fontWeight(.bold)
                
                ProgressView()
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthenticationManager.shared)
        .environmentObject(OrderManager.shared)
}

