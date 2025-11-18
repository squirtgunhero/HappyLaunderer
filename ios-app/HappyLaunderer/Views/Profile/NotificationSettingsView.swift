//
//  NotificationSettingsView.swift
//  HappyLaunderer
//
//  Notification preferences
//

import SwiftUI

struct NotificationSettingsView: View {
    @AppStorage("pushNotificationsEnabled") private var pushNotificationsEnabled = true
    @AppStorage("orderUpdatesEnabled") private var orderUpdatesEnabled = true
    @AppStorage("promotionsEnabled") private var promotionsEnabled = true
    @AppStorage("smsNotificationsEnabled") private var smsNotificationsEnabled = false
    
    var body: some View {
        Form {
            Section(header: Text("Push Notifications")) {
                Toggle("Enable Push Notifications", isOn: $pushNotificationsEnabled)
                    .onChange(of: pushNotificationsEnabled) { oldValue, newValue in
                        if newValue {
                            requestPushNotificationPermission()
                        }
                    }
                
                if pushNotificationsEnabled {
                    Toggle("Order Updates", isOn: $orderUpdatesEnabled)
                    Toggle("Promotions", isOn: $promotionsEnabled)
                }
            }
            
            Section(header: Text("SMS Notifications"), footer: Text("Standard messaging rates may apply")) {
                Toggle("Enable SMS Notifications", isOn: $smsNotificationsEnabled)
            }
            
            Section {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                    Text("You can change these settings anytime")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Notifications")
    }
    
    private func requestPushNotificationPermission() {
        // Request notification permission
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("Error requesting notification permission: \(error)")
            }
            
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }
}

import UserNotifications

#Preview {
    NavigationView {
        NotificationSettingsView()
    }
}

