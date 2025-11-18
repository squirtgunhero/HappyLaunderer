//
//  HappyLaundererApp.swift
//  HappyLaunderer
//
//  Main app entry point
//

import SwiftUI

@main
struct HappyLaundererApp: App {
    @StateObject private var authManager = AuthenticationManager.shared
    @StateObject private var orderManager = OrderManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environmentObject(orderManager)
        }
    }
}

