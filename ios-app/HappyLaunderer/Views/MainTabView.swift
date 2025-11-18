//
//  MainTabView.swift
//  HappyLaunderer
//
//  Main tab navigation
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            OrdersListView()
                .tabItem {
                    Label("Orders", systemImage: "list.bullet")
                }
                .tag(1)
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(2)
        }
        .accentColor(.blue)
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthenticationManager.shared)
        .environmentObject(OrderManager.shared)
}

