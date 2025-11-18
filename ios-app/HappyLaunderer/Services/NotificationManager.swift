//
//  NotificationManager.swift
//  HappyLaunderer
//
//  Manages push notifications
//

import Foundation
import UserNotifications

class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()
    
    @Published var deviceToken: String?
    
    private override init() {
        super.init()
    }
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("Error requesting notification permission: \(error)")
                return
            }
            
            if granted {
                print("Notification permission granted")
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } else {
                print("Notification permission denied")
            }
        }
    }
    
    func handleDeviceToken(_ token: Data) {
        let tokenString = token.map { String(format: "%02.2hhx", $0) }.joined()
        deviceToken = tokenString
        print("Device token: \(tokenString)")
        
        // Send token to backend
        Task {
            await sendTokenToBackend(tokenString)
        }
    }
    
    func handleRegistrationError(_ error: Error) {
        print("Failed to register for notifications: \(error)")
    }
    
    private func sendTokenToBackend(_ token: String) async {
        // TODO: Send device token to backend for push notifications
        // This would be an API call to your backend to store the token
        // associated with the user's account
    }
    
    func scheduleLocalNotification(title: String, body: String, timeInterval: TimeInterval = 1) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // Handle notification tap
        let userInfo = response.notification.request.content.userInfo
        
        // Extract order ID if present
        if let orderId = userInfo["orderId"] as? String {
            // Navigate to order detail
            NotificationCenter.default.post(
                name: NSNotification.Name("OpenOrderDetail"),
                object: nil,
                userInfo: ["orderId": orderId]
            )
        }
        
        completionHandler()
    }
}

