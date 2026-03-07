// Infrastructure/Notifications/NotificationService.swift
// SpendSnap

import UserNotifications

/// Manages local notifications for monthly report reminders.
struct NotificationService {
    
    // MARK: - Permission
    
    static func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .badge, .sound]
        ) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }
    
    // MARK: - Schedule Monthly Report Reminder
    
    /// Schedules a notification for the 1st of each month at 9:00 AM.
    static func scheduleMonthlyReportReminder() {
        let content = UNMutableNotificationContent()
        content.title = "Monthly Spending Report"
        content.body = "Your spending report is ready! See where your money went last month."
        content.sound = .default
        
        // Trigger: 1st of every month at 9:00 AM
        var dateComponents = DateComponents()
        dateComponents.day = 1
        dateComponents.hour = 9
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "monthly_report_reminder",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error)")
            }
        }
    }
    
    // MARK: - Cancel
    
    static func cancelMonthlyReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["monthly_report_reminder"]
        )
    }
}
