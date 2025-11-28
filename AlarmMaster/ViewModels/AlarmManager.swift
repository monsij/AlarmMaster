//
//  AlarmManager.swift
//  AlarmMaster
//

import Foundation
import UserNotifications
import Combine
import SwiftUI
import AVFoundation
import AudioToolbox

// MARK: - AlarmSoundManager

class AlarmSoundManager: NSObject, ObservableObject {
    static let shared = AlarmSoundManager()
    
    @Published var isPlaying = false
    
    private var audioPlayer: AVAudioPlayer?
    private var toneTimer: Timer?
    
    private override init() {
        super.init()
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers, .duckOthers])
            try session.setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    func playAlarm() {
        guard !isPlaying else { return }
        
        isPlaying = true
        
        if let soundURL = Bundle.main.url(forResource: "alarm_tone", withExtension: "wav") {
            playSound(from: soundURL)
        } else {
            startGeneratedAlarm()
        }
    }
    
    private func playSound(from url: URL) {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = -1
            audioPlayer?.volume = 1.0
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch {
            print("Failed to play sound: \(error)")
            startGeneratedAlarm()
        }
    }
    
    private func startGeneratedAlarm() {
        toneTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.playSystemTone()
        }
        toneTimer?.fire()
        startHapticPattern()
    }
    
    private func playSystemTone() {
        AudioServicesPlaySystemSound(1005)
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }
    
    private func startHapticPattern() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.warning)
    }
    
    func stopAlarm() {
        isPlaying = false
        audioPlayer?.stop()
        audioPlayer = nil
        toneTimer?.invalidate()
        toneTimer = nil
        AudioServicesDisposeSystemSoundID(kSystemSoundID_Vibrate)
    }
    
    // MARK: - Custom Sound File Configuration
    
    /// Change this to your MP3 filename (without extension) that you added to the project
    static let customSoundFileName = "alarm_sound"  // e.g., "my_alarm" for "my_alarm.mp3"
    static let customSoundExtension = "mp3"
    
    /// Set to true to use your custom MP3, false to use generated tone
    static let useCustomSound = true
    
    /// Prepares the alarm sound file in Library/Sounds for notifications
    static func generateAlarmToneFile() -> URL? {
        // iOS notifications require sounds to be in Library/Sounds
        let libraryPath = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)[0]
        let soundsDir = libraryPath.appendingPathComponent("Sounds")
        
        // Create Sounds directory if it doesn't exist
        try? FileManager.default.createDirectory(at: soundsDir, withIntermediateDirectories: true)
        
        // Try to use custom sound file first
        if useCustomSound, let customURL = copyCustomSoundToLibrary(soundsDir: soundsDir) {
            return customURL
        }
        
        // Fall back to generated tone
        return generateDefaultTone(in: soundsDir)
    }
    
    /// Copies custom MP3/audio file from bundle to Library/Sounds
    private static func copyCustomSoundToLibrary(soundsDir: URL) -> URL? {
        guard let bundleURL = Bundle.main.url(forResource: customSoundFileName, withExtension: customSoundExtension) else {
            print("⚠️ Custom sound file '\(customSoundFileName).\(customSoundExtension)' not found in bundle")
            return nil
        }
        
        let destURL = soundsDir.appendingPathComponent("alarm_tone.\(customSoundExtension)")
        
        do {
            // Remove existing file if present
            try? FileManager.default.removeItem(at: destURL)
            // Copy the custom sound
            try FileManager.default.copyItem(at: bundleURL, to: destURL)
            print("✓ Using custom alarm sound: \(customSoundFileName).\(customSoundExtension)")
            return destURL
        } catch {
            print("Failed to copy custom sound: \(error)")
            return nil
        }
    }
    
    /// Generates a soft default alarm tone
    private static func generateDefaultTone(in soundsDir: URL) -> URL? {
        let fileURL = soundsDir.appendingPathComponent("alarm_tone.caf")
        
        let sampleRate: Double = 44100
        let duration: Double = 30.0  // Max allowed for notification sounds
        let baseFrequency: Double = 520.0  // C5 - softer, lower pitch
        
        let numSamples = Int(sampleRate * duration)
        var samples = [Float](repeating: 0, count: numSamples)
        
        for i in 0..<numSamples {
            let time = Double(i) / sampleRate
            
            // Soft pattern: gentle tone, brief pause, gentle tone, longer pause
            let cycleTime = time.truncatingRemainder(dividingBy: 1.5)
            let shouldPlay = (cycleTime < 0.4) || (cycleTime >= 0.55 && cycleTime < 0.95)
            
            if shouldPlay {
                let toneStart = cycleTime < 0.4 ? 0.0 : 0.55
                let toneDuration = 0.4
                let tonePosition = cycleTime - toneStart
                
                let attack = min(tonePosition / 0.08, 1.0)
                let release = min((toneDuration - tonePosition) / 0.08, 1.0)
                let envelope = min(attack, release)
                
                let fundamental = sin(2.0 * .pi * baseFrequency * time)
                let harmonic = sin(2.0 * .pi * baseFrequency * 2.0 * time) * 0.15
                
                samples[i] = Float((fundamental + harmonic) * 0.5 * envelope)
            } else {
                samples[i] = 0
            }
        }
        
        do {
            try writeCAFFile(samples: samples, sampleRate: Int(sampleRate), to: fileURL)
            print("✓ Generated default alarm tone")
            return fileURL
        } catch {
            print("Failed to generate tone file: \(error)")
            return nil
        }
    }
    
    /// Write samples as a CAF file (Core Audio Format - better iOS compatibility)
    private static func writeCAFFile(samples: [Float], sampleRate: Int, to url: URL) throws {
        // Remove existing file
        try? FileManager.default.removeItem(at: url)
        
        let format = AVAudioFormat(standardFormatWithSampleRate: Double(sampleRate), channels: 1)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(samples.count))!
        buffer.frameLength = AVAudioFrameCount(samples.count)
        
        let channelData = buffer.floatChannelData![0]
        for i in 0..<samples.count {
            channelData[i] = samples[i]
        }
        
        // Write as CAF format for better iOS compatibility
        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVSampleRateKey: sampleRate,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false
        ]
        
        let file = try AVAudioFile(forWriting: url, settings: settings)
        try file.write(from: buffer)
    }
    
}

// MARK: - AlarmManager

class AlarmManager: NSObject, ObservableObject {
    @Published var alarms: [Alarm] = []
    @Published var allAlarmsEnabled: Bool = true {
        didSet {
            if oldValue != allAlarmsEnabled {
                toggleAllAlarms(enabled: allAlarmsEnabled)
            }
        }
    }
    
    @Published var activeAlarm: Alarm?
    @Published var isAlarmRinging: Bool = false
    
    private let storageKey = "saved_alarms"
    private let masterToggleKey = "master_toggle"
    private let snoozeDuration: TimeInterval = 5 * 60
    
    private var alarmCheckTimer: Timer?
    
    override init() {
        super.init()
        loadAlarms()
        loadMasterToggle()
        setupNotificationDelegate()
        startAlarmMonitoring()
        _ = AlarmSoundManager.generateAlarmToneFile()
    }
    
    // MARK: - Alarm Monitoring
    
    private func startAlarmMonitoring() {
        alarmCheckTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.checkForDueAlarms()
        }
    }
    
    private func checkForDueAlarms() {
        guard !isAlarmRinging else { return }
        
        let now = Date()
        
        for alarm in alarms where alarm.isEnabled {
            let alarmTime = alarm.scheduledDate
            if abs(now.timeIntervalSince(alarmTime)) < 1 {
                triggerAlarm(alarm)
                break
            }
        }
    }
    
    // MARK: - Trigger Alarm
    
    func triggerAlarm(_ alarm: Alarm) {
        DispatchQueue.main.async { [weak self] in
            self?.activeAlarm = alarm
            self?.isAlarmRinging = true
            AlarmSoundManager.shared.playAlarm()
        }
    }
    
    // MARK: - Stop Alarm
    
    func stopAlarm() {
        AlarmSoundManager.shared.stopAlarm()
        
        if let alarm = activeAlarm {
            if let index = alarms.firstIndex(where: { $0.id == alarm.id }) {
                alarms[index].isEnabled = false
                cancelNotification(for: alarm)
                saveAlarms()
            }
        }
        
        activeAlarm = nil
        isAlarmRinging = false
    }
    
    // MARK: - Snooze Alarm
    
    func snoozeAlarm() {
        AlarmSoundManager.shared.stopAlarm()
        
        if let alarm = activeAlarm {
            let snoozeTime = Date().addingTimeInterval(snoozeDuration)
            let snoozeAlarm = Alarm(
                time: snoozeTime,
                date: snoozeTime,
                label: "\(alarm.label) (Snoozed)",
                isEnabled: true
            )
            
            scheduleNotification(for: snoozeAlarm)
            alarms.append(snoozeAlarm)
            alarms.sort { $0.scheduledDate < $1.scheduledDate }
            saveAlarms()
        }
        
        activeAlarm = nil
        isAlarmRinging = false
    }
    
    // MARK: - Notification Delegate Setup
    
    private func setupNotificationDelegate() {
        UNUserNotificationCenter.current().delegate = self
        
        let stopAction = UNNotificationAction(
            identifier: "STOP_ACTION",
            title: "Stop",
            options: [.destructive, .foreground]
        )
        
        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE_ACTION",
            title: "Snooze 5 min",
            options: [.foreground]
        )
        
        let alarmCategory = UNNotificationCategory(
            identifier: "ALARM_CATEGORY",
            actions: [stopAction, snoozeAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([alarmCategory])
    }
    
    // MARK: - Alarm CRUD Operations
    
    func addAlarm(_ alarm: Alarm) {
        var newAlarm = alarm
        newAlarm.isEnabled = allAlarmsEnabled
        alarms.append(newAlarm)
        alarms.sort { $0.scheduledDate < $1.scheduledDate }
        
        if newAlarm.isEnabled {
            scheduleNotification(for: newAlarm)
        }
        saveAlarms()
    }
    
    func deleteAlarm(_ alarm: Alarm) {
        cancelNotification(for: alarm)
        alarms.removeAll { $0.id == alarm.id }
        saveAlarms()
    }
    
    func deleteAlarms(at offsets: IndexSet) {
        for index in offsets {
            cancelNotification(for: alarms[index])
        }
        alarms.remove(atOffsets: offsets)
        saveAlarms()
    }
    
    func toggleAlarm(_ alarm: Alarm) {
        guard let index = alarms.firstIndex(where: { $0.id == alarm.id }) else { return }
        alarms[index].isEnabled.toggle()
        
        if alarms[index].isEnabled {
            scheduleNotification(for: alarms[index])
        } else {
            cancelNotification(for: alarms[index])
        }
        
        saveAlarms()
        updateMasterToggleState()
    }
    
    // MARK: - Master Toggle
    
    func toggleAllAlarms(enabled: Bool) {
        if !enabled && isAlarmRinging {
            stopAlarm()
        }
        
        for index in alarms.indices {
            alarms[index].isEnabled = enabled
            
            if enabled {
                scheduleNotification(for: alarms[index])
            } else {
                cancelNotification(for: alarms[index])
            }
        }
        saveAlarms()
        saveMasterToggle()
    }
    
    func killAllAlarms() {
        allAlarmsEnabled = false
    }
    
    func enableAllAlarms() {
        allAlarmsEnabled = true
    }
    
    private func updateMasterToggleState() {
        let anyEnabled = alarms.contains { $0.isEnabled }
        if !anyEnabled && allAlarmsEnabled {
            allAlarmsEnabled = false
        }
    }
    
    // MARK: - Notifications
    
    private func scheduleNotification(for alarm: Alarm) {
        guard !alarm.isPast else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "⏰ Alarm"
        content.body = alarm.label.isEmpty ? "Time to wake up!" : alarm.label
        
        // Use our custom alarm sound file (located in Library/Sounds/)
        // This will play even when the phone is locked!
        let soundFileName = AlarmSoundManager.useCustomSound ? "alarm_tone.\(AlarmSoundManager.customSoundExtension)" : "alarm_tone.caf"
        content.sound = UNNotificationSound(named: UNNotificationSoundName(soundFileName))
        
        content.interruptionLevel = .timeSensitive
        content.categoryIdentifier = "ALARM_CATEGORY"
        content.userInfo = ["alarmId": alarm.id.uuidString]
        
        // Add app logo to notification
        if let attachment = createNotificationAttachment() {
            content.attachments = [attachment]
        }
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: alarm.scheduledDate)
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: alarm.id.uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            } else {
                print("✓ Scheduled alarm for \(alarm.formattedDateTime)")
            }
        }
    }
    
    /// Creates a notification attachment with the app logo
    private func createNotificationAttachment() -> UNNotificationAttachment? {
        // Try to find the notification icon in the bundle
        guard let imageURL = Bundle.main.url(forResource: "notification_icon", withExtension: "png") else {
            print("⚠️ notification_icon.png not found in bundle")
            return nil
        }
        
        // Copy to temporary location (required for attachments)
        let tempDir = FileManager.default.temporaryDirectory
        let tempURL = tempDir.appendingPathComponent("notification_icon_\(UUID().uuidString).png")
        
        do {
            try? FileManager.default.removeItem(at: tempURL)
            try FileManager.default.copyItem(at: imageURL, to: tempURL)
            
            let attachment = try UNNotificationAttachment(
                identifier: "alarm_image",
                url: tempURL,
                options: [UNNotificationAttachmentOptionsThumbnailClippingRectKey: CGRect(x: 0, y: 0, width: 1, height: 1).dictionaryRepresentation]
            )
            return attachment
        } catch {
            print("Failed to create notification attachment: \(error)")
            return nil
        }
    }
    
    private func cancelNotification(for alarm: Alarm) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [alarm.id.uuidString])
        print("✗ Cancelled alarm: \(alarm.formattedDateTime)")
    }
    
    private func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        print("✗ Cancelled all alarms")
    }
    
    // MARK: - Persistence
    
    private func saveAlarms() {
        if let encoded = try? JSONEncoder().encode(alarms) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }
    
    private func loadAlarms() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([Alarm].self, from: data) {
            alarms = decoded
        }
    }
    
    private func saveMasterToggle() {
        UserDefaults.standard.set(allAlarmsEnabled, forKey: masterToggleKey)
    }
    
    private func loadMasterToggle() {
        allAlarmsEnabled = UserDefaults.standard.bool(forKey: masterToggleKey)
        if !UserDefaults.standard.bool(forKey: "\(masterToggleKey)_set") {
            allAlarmsEnabled = true
            UserDefaults.standard.set(true, forKey: "\(masterToggleKey)_set")
        }
    }
    
    // MARK: - Computed Properties
    
    var enabledAlarmsCount: Int {
        alarms.filter { $0.isEnabled }.count
    }
    
    var totalAlarmsCount: Int {
        alarms.count
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension AlarmManager: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        if let alarmIdString = notification.request.content.userInfo["alarmId"] as? String,
           let alarmId = UUID(uuidString: alarmIdString),
           let alarm = alarms.first(where: { $0.id == alarmId }) {
            triggerAlarm(alarm)
        }
        completionHandler([.banner, .sound])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let alarmIdString = response.notification.request.content.userInfo["alarmId"] as? String
        let alarmId = alarmIdString.flatMap { UUID(uuidString: $0) }
        let alarm = alarmId.flatMap { id in alarms.first { $0.id == id } }
        
        switch response.actionIdentifier {
        case "STOP_ACTION", UNNotificationDismissActionIdentifier:
            if alarm != nil {
                if let index = alarms.firstIndex(where: { $0.id == alarmId }) {
                    alarms[index].isEnabled = false
                    saveAlarms()
                }
            }
            
        case "SNOOZE_ACTION":
            if let alarm = alarm {
                let snoozeTime = Date().addingTimeInterval(snoozeDuration)
                let snoozeAlarm = Alarm(
                    time: snoozeTime,
                    date: snoozeTime,
                    label: "\(alarm.label) (Snoozed)",
                    isEnabled: true
                )
                scheduleNotification(for: snoozeAlarm)
                alarms.append(snoozeAlarm)
                saveAlarms()
            }
            
        default:
            if let alarm = alarm {
                triggerAlarm(alarm)
            }
        }
        
        completionHandler()
    }
}
