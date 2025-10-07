import UserNotifications

#if os(iOS)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

class NotificationManager {
    static let shared = NotificationManager()
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            if granted {
                DispatchQueue.main.async {
                    self.registerForRemoteNotifications()
                }
            }
        }
    }
    
    func scheduleDailyReminders() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        
        scheduleNotification(
            id: "morning",
            title: "Good Morning! ☀️",
            body: "Start your day strong. Complete your morning habits!",
            hour: 9,
            minute: 0
        )
        
        scheduleNotification(
            id: "evening",
            title: "Evening Check-in 🌙",
            body: "How did today go? Log your habits before bed!",
            hour: 20,
            minute: 0
        )
    }
    
    private func scheduleNotification(id: String, title: String, body: String, hour: Int, minute: Int) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }

#if os(iOS)
    private func registerForRemoteNotifications() {
        UIApplication.shared.registerForRemoteNotifications()
    }
#elseif canImport(AppKit)
    private func registerForRemoteNotifications() {
        NSApplication.shared.registerForRemoteNotifications()
    }
#else
    private func registerForRemoteNotifications() {}
#endif
}
