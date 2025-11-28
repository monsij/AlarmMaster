//
//  AlarmMasterApp.swift
//  AlarmMaster
//
//  A simple iOS app to manage alarms with a master kill switch
//

import SwiftUI
import UserNotifications
import AVFoundation

@main
struct AlarmMasterApp: App {
    @StateObject private var alarmManager = AlarmManager()
    
    init() {
        // Request notification permissions on launch
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound, .criticalAlert]) { granted, error in
            if granted {
                print("✓ Notification permission granted")
            } else if let error = error {
                print("✗ Notification permission error: \(error.localizedDescription)")
            }
        }
        
        // Setup audio session for alarm playback
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(alarmManager)
                .preferredColorScheme(.dark)
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                    // Re-activate audio session when coming to foreground
                    try? AVAudioSession.sharedInstance().setActive(true)
                }
        }
    }
}

