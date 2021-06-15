//
//  DataController-Reminders.swift
//  OddTracker
//
//  Created by Michael Brünen on 15.06.21.
//

import UserNotifications

extension DataController {
    // MARK: - Notifications
    /// Adds a notification for the given project
    /// - Parameters:
    ///   - project: The project the notification is for
    ///   - completion: The completion handler
    func addReminders(for project: Project, completion: @escaping (Bool) -> Void) {
        // we check our authorization status for local notifications
        let notificationCenter = UNUserNotificationCenter.current()

        notificationCenter.getNotificationSettings { settings in
            switch settings.authorizationStatus {
                case .notDetermined:
                    self.requestNotifications { success in
                        if success {
                            self.placeReminders(for: project, completion: completion)
                        } else {
                            DispatchQueue.main.async {
                                completion(false)
                            }
                        }
                    }
                case .authorized:
                    self.placeReminders(for: project, completion: completion)
                default:
                    DispatchQueue.main.async {
                        completion(false)
                    }
            }
        }
    }

    /// Removes a notification for the given project
    /// - Parameter project: The project to remove the notification from
    func removeReminders(for project: Project) {
        let notificationCenter = UNUserNotificationCenter.current()
        let id = project.objectID.uriRepresentation().absoluteString
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [id])
    }

    /// Requests the permissions to show notifications from the user
    /// - Parameter completion: The completion handler
    private func requestNotifications(completion: @escaping (Bool) -> Void) {
        let notificationCenter = UNUserNotificationCenter.current()

        notificationCenter.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            completion(granted)
        }
    }

    /// Places a single notification for the given project
    /// - Parameters:
    ///   - project: The project to place the notification for
    ///   - completion: The completion handler
    private func placeReminders(for project: Project, completion: @escaping (Bool) -> Void) {
        // content of the notification
        let content = UNMutableNotificationContent()
        content.sound = .default
        content.title = project.projectTitle
        if !project.projectDetail.isEmpty {
            content.subtitle = project.projectDetail
        }

        // trigger for the notification
        let components = Calendar.current.dateComponents([.hour, .minute], from: project.reminderTime ?? Date())
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        // wrap up content and trigger with an id
        let id = project.objectID.uriRepresentation().absoluteString
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        // send the request off to iOS
        UNUserNotificationCenter.current().add(request) { error in
            DispatchQueue.main.async {
                if error == nil {
                    completion(true)
                } else {
                    completion(false)
                }
            }
        }
    }
}
