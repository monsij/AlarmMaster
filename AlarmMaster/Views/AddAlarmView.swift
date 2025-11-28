//
//  AddAlarmView.swift
//  AlarmMaster
//

import SwiftUI

struct AddAlarmView: View {
    @EnvironmentObject var alarmManager: AlarmManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedTime = Date()
    @State private var selectedDate = Date()
    @State private var alarmLabel = ""
    
    // MARK: - Color Theme
    private let backgroundColor = Color(red: 0.05, green: 0.05, blue: 0.08)
    private let cardColor = Color(red: 0.12, green: 0.12, blue: 0.16)
    private let accentGreen = Color(red: 0.2, green: 0.9, blue: 0.5)
    private let textPrimary = Color.white
    private let textSecondary = Color(white: 0.6)
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(
                    colors: [backgroundColor, Color(red: 0.08, green: 0.06, blue: 0.12)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Time Picker
                        timePickerSection
                        
                        // Date Picker
                        datePickerSection
                        
                        // Label Input
                        labelSection
                        
                        // Save Button
                        saveButton
                    }
                    .padding(20)
                }
            }
            .navigationTitle("New Alarm")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(textSecondary)
                }
            }
        }
    }
    
    // MARK: - Time Picker Section
    private var timePickerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Time", systemImage: "clock.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(accentGreen)
            
            DatePicker("", selection: $selectedTime, displayedComponents: .hourAndMinute)
                .datePickerStyle(.wheel)
                .labelsHidden()
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(cardColor)
                )
                .colorScheme(.dark)
        }
    }
    
    // MARK: - Date Picker Section
    private var datePickerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Date", systemImage: "calendar")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(accentGreen)
            
            DatePicker("", selection: $selectedDate, in: Date()..., displayedComponents: .date)
                .datePickerStyle(.graphical)
                .labelsHidden()
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(cardColor)
                )
                .tint(accentGreen)
                .colorScheme(.dark)
        }
    }
    
    // MARK: - Label Section
    private var labelSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Label (Optional)", systemImage: "tag.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(accentGreen)
            
            TextField("Alarm label", text: $alarmLabel)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(textPrimary)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(cardColor)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        }
    }
    
    // MARK: - Save Button
    private var saveButton: some View {
        Button(action: saveAlarm) {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20, weight: .semibold))
                
                Text("Save Alarm")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
            }
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(accentGreen)
            )
        }
        .padding(.top, 8)
    }
    
    // MARK: - Actions
    private func saveAlarm() {
        let newAlarm = Alarm(
            time: selectedTime,
            date: selectedDate,
            label: alarmLabel.isEmpty ? "Alarm" : alarmLabel
        )
        alarmManager.addAlarm(newAlarm)
        dismiss()
    }
}

#Preview {
    AddAlarmView()
        .environmentObject(AlarmManager())
}


