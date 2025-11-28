//
//  AlarmRowView.swift
//  AlarmMaster
//

import SwiftUI

struct AlarmRowView: View {
    let alarm: Alarm
    @EnvironmentObject var alarmManager: AlarmManager
    @State private var offset: CGFloat = 0
    @State private var showDeleteButton = false
    
    // MARK: - Color Theme
    private let cardColor = Color(red: 0.12, green: 0.12, blue: 0.16)
    private let accentRed = Color(red: 1.0, green: 0.25, blue: 0.35)
    private let accentGreen = Color(red: 0.2, green: 0.9, blue: 0.5)
    private let textPrimary = Color.white
    private let textSecondary = Color(white: 0.6)
    private let textMuted = Color(white: 0.4)
    
    var body: some View {
        ZStack(alignment: .trailing) {
            // Delete button (revealed on swipe)
            HStack {
                Spacer()
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        alarmManager.deleteAlarm(alarm)
                    }
                }) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 70, height: 80)
                        .background(accentRed)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
            
            // Main alarm card
            HStack(spacing: 16) {
                // Time display
                VStack(alignment: .leading, spacing: 2) {
                    Text(alarm.formattedTime)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(alarm.isEnabled ? textPrimary : textMuted)
                    
                    Text(alarm.formattedDate)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(alarm.isEnabled ? textSecondary : textMuted)
                }
                
                Spacer()
                
                // Label
                if !alarm.label.isEmpty && alarm.label != "Alarm" {
                    Text(alarm.label)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(alarm.isEnabled ? textSecondary : textMuted)
                        .lineLimit(1)
                        .frame(maxWidth: 100, alignment: .trailing)
                }
                
                // Toggle
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        alarmManager.toggleAlarm(alarm)
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(alarm.isEnabled ? accentGreen.opacity(0.2) : Color(white: 0.2))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: alarm.isEnabled ? "bell.fill" : "bell.slash.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(alarm.isEnabled ? accentGreen : textMuted)
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(cardColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(
                                alarm.isEnabled ? accentGreen.opacity(0.15) : Color.clear,
                                lineWidth: 1
                            )
                    )
            )
            .offset(x: offset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if value.translation.width < 0 {
                            offset = max(value.translation.width, -80)
                        }
                    }
                    .onEnded { value in
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            if value.translation.width < -40 {
                                offset = -80
                                showDeleteButton = true
                            } else {
                                offset = 0
                                showDeleteButton = false
                            }
                        }
                    }
            )
            .onTapGesture {
                if showDeleteButton {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        offset = 0
                        showDeleteButton = false
                    }
                }
            }
        }
    }
}

#Preview {
    ZStack {
        Color(red: 0.05, green: 0.05, blue: 0.08)
            .ignoresSafeArea()
        
        VStack(spacing: 12) {
            AlarmRowView(alarm: Alarm(time: Date(), date: Date(), label: "Wake up", isEnabled: true))
            AlarmRowView(alarm: Alarm(time: Date(), date: Date(), label: "Meeting", isEnabled: false))
        }
        .padding()
        .environmentObject(AlarmManager())
    }
}


