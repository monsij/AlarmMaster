//
//  ContentView.swift
//  AlarmMaster
//

import SwiftUI

// MARK: - AlarmActiveView

struct AlarmActiveView: View {
    let alarm: Alarm
    let onStop: () -> Void
    let onSnooze: () -> Void
    
    @State private var pulseAnimation = false
    @State private var timeString = ""
    @State private var bellRotation: Double = 0
    
    private let backgroundColor = Color(red: 0.05, green: 0.05, blue: 0.08)
    private let accentRed = Color(red: 1.0, green: 0.25, blue: 0.35)
    private let accentOrange = Color(red: 1.0, green: 0.6, blue: 0.2)
    private let textPrimary = Color.white
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()
            
            Circle()
                .fill(
                    RadialGradient(
                        colors: [accentRed.opacity(0.3), Color.clear],
                        center: .center,
                        startRadius: 100,
                        endRadius: pulseAnimation ? 400 : 200
                    )
                )
                .frame(width: 800, height: 800)
                .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: pulseAnimation)
            
            VStack(spacing: 40) {
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(accentRed.opacity(0.2))
                        .frame(width: 180, height: 180)
                        .blur(radius: 30)
                    
                    Image(systemName: "bell.fill")
                        .font(.system(size: 100, weight: .medium))
                        .foregroundStyle(accentRed)
                        .rotationEffect(.degrees(bellRotation))
                }
                
                Text(timeString)
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundStyle(textPrimary)
                    .monospacedDigit()
                
                Text(alarm.label)
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .foregroundStyle(textPrimary.opacity(0.7))
                
                Spacer()
                
                VStack(spacing: 20) {
                    Button(action: onStop) {
                        HStack(spacing: 16) {
                            Image(systemName: "stop.fill")
                                .font(.system(size: 24, weight: .bold))
                            Text("STOP")
                                .font(.system(size: 24, weight: .black, design: .rounded))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(accentRed)
                                .shadow(color: accentRed.opacity(0.5), radius: 20, y: 5)
                        )
                    }
                    
                    Button(action: onSnooze) {
                        HStack(spacing: 16) {
                            Image(systemName: "moon.zzz.fill")
                                .font(.system(size: 22, weight: .semibold))
                            Text("SNOOZE 5 MIN")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                        }
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(accentOrange)
                        )
                    }
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            updateTime()
            pulseAnimation = true
            startBellAnimation()
        }
        .onReceive(timer) { _ in
            updateTime()
        }
    }
    
    private func updateTime() {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        timeString = formatter.string(from: Date())
    }
    
    private func startBellAnimation() {
        withAnimation(.easeInOut(duration: 0.1).repeatForever(autoreverses: true)) {
            bellRotation = 15
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeInOut(duration: 0.1).repeatForever(autoreverses: true)) {
                bellRotation = -15
            }
        }
    }
}

// MARK: - ContentView

struct ContentView: View {
    @EnvironmentObject var alarmManager: AlarmManager
    @State private var showingAddAlarm = false
    @State private var killButtonScale: CGFloat = 1.0
    @State private var killButtonRotation: Double = 0
    
    private let backgroundColor = Color(red: 0.05, green: 0.05, blue: 0.08)
    private let cardColor = Color(red: 0.12, green: 0.12, blue: 0.16)
    private let accentRed = Color(red: 1.0, green: 0.25, blue: 0.35)
    private let accentGreen = Color(red: 0.2, green: 0.9, blue: 0.5)
    private let textPrimary = Color.white
    private let textSecondary = Color(white: 0.6)
    
    var body: some View {
        ZStack {
            NavigationStack {
                ZStack {
                    LinearGradient(
                        colors: [backgroundColor, Color(red: 0.08, green: 0.06, blue: 0.12)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                    
                    VStack(spacing: 0) {
                        masterToggleSection
                            .padding(.horizontal, 20)
                            .padding(.top, 10)
                        
                        if alarmManager.alarms.isEmpty {
                            emptyStateView
                        } else {
                            alarmListView
                        }
                        
                        Spacer(minLength: 0)
                    }
                }
                .navigationTitle("Alarms")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: { showingAddAlarm = true }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundStyle(accentGreen)
                        }
                    }
                }
                .sheet(isPresented: $showingAddAlarm) {
                    AddAlarmView()
                        .environmentObject(alarmManager)
                }
            }
            .tint(accentGreen)
            
            if alarmManager.isAlarmRinging, let alarm = alarmManager.activeAlarm {
                AlarmActiveView(
                    alarm: alarm,
                    onStop: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            alarmManager.stopAlarm()
                        }
                    },
                    onSnooze: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            alarmManager.snoozeAlarm()
                        }
                    }
                )
                .transition(.opacity.combined(with: .scale(scale: 1.1)))
                .zIndex(100)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: alarmManager.isAlarmRinging)
    }
    
    private var masterToggleSection: some View {
        VStack(spacing: 16) {
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    killButtonScale = 0.9
                    killButtonRotation += 10
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        killButtonScale = 1.0
                        killButtonRotation = 0
                    }
                }
                
                withAnimation(.easeInOut(duration: 0.3)) {
                    alarmManager.allAlarmsEnabled.toggle()
                }
            }) {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(alarmManager.allAlarmsEnabled ? accentGreen.opacity(0.2) : accentRed.opacity(0.2))
                            .frame(width: 56, height: 56)
                        
                        Image(systemName: "power")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(alarmManager.allAlarmsEnabled ? accentGreen : accentRed)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(alarmManager.allAlarmsEnabled ? "ALARMS ACTIVE" : "ALARMS OFF")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(textPrimary)
                        
                        Text(statusText)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(textSecondary)
                    }
                    
                    Spacer()
                    
                    ZStack {
                        Capsule()
                            .fill(alarmManager.allAlarmsEnabled ? accentGreen : Color(white: 0.3))
                            .frame(width: 56, height: 32)
                        
                        Circle()
                            .fill(.white)
                            .frame(width: 26, height: 26)
                            .offset(x: alarmManager.allAlarmsEnabled ? 12 : -12)
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(cardColor)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(
                                    alarmManager.allAlarmsEnabled ? accentGreen.opacity(0.3) : accentRed.opacity(0.3),
                                    lineWidth: 1
                                )
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
            .scaleEffect(killButtonScale)
            .rotation3DEffect(.degrees(killButtonRotation), axis: (x: 0, y: 1, z: 0))
        }
    }
    
    private var statusText: String {
        if alarmManager.alarms.isEmpty {
            return "No alarms set"
        } else if alarmManager.allAlarmsEnabled {
            return "\(alarmManager.enabledAlarmsCount) of \(alarmManager.totalAlarmsCount) alarms enabled"
        } else {
            return "Tap to enable all alarms"
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(cardColor)
                    .frame(width: 120, height: 120)
                
                Image(systemName: "alarm.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(textSecondary)
            }
            
            Text("No Alarms")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(textPrimary)
            
            Text("Tap + to create your first alarm")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(textSecondary)
            
            Spacer()
        }
    }
    
    private var alarmListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(alarmManager.alarms) { alarm in
                    AlarmRowView(alarm: alarm)
                        .environmentObject(alarmManager)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 100)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AlarmManager())
}
