//
//  Alarm.swift
//  AlarmMaster
//

import Foundation

struct Alarm: Identifiable, Codable, Equatable {
    let id: UUID
    var time: Date
    var date: Date
    var label: String
    var isEnabled: Bool
    
    init(id: UUID = UUID(), time: Date, date: Date, label: String = "Alarm", isEnabled: Bool = true) {
        self.id = id
        self.time = time
        self.date = date
        self.label = label
        self.isEnabled = isEnabled
    }
    
    /// Combined date and time for the alarm
    var scheduledDate: Date {
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        
        var combined = DateComponents()
        combined.year = dateComponents.year
        combined.month = dateComponents.month
        combined.day = dateComponents.day
        combined.hour = timeComponents.hour
        combined.minute = timeComponents.minute
        combined.second = 0
        
        return calendar.date(from: combined) ?? Date()
    }
    
    /// Formatted time string (e.g., "7:30 AM")
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: time)
    }
    
    /// Formatted date string (e.g., "Nov 27")
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
    
    /// Full formatted string (e.g., "Nov 27, 7:30 AM")
    var formattedDateTime: String {
        "\(formattedDate), \(formattedTime)"
    }
    
    /// Check if alarm is in the past
    var isPast: Bool {
        scheduledDate < Date()
    }
}


