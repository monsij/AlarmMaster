//
//  WeatherBarView.swift
//  AlarmMaster
//

import SwiftUI

struct WeatherBarView: View {
    @ObservedObject var weatherService: WeatherService
    
    // Different styling from alarm items - more vibrant and distinct
    private let weatherCardColor = Color(red: 0.15, green: 0.15, blue: 0.20)
    private let weatherGradientStart = Color(red: 0.15, green: 0.15, blue: 0.20)
    private let weatherGradientEnd = Color(red: 0.18, green: 0.18, blue: 0.24)
    private let textPrimary = Color.white
    private let textSecondary = Color(white: 0.6)
    private let accentBlue = Color(red: 0.3, green: 0.6, blue: 1.0)
    private let accentCyan = Color(red: 0.2, green: 0.8, blue: 0.9)
    
    var body: some View {
        if let weather = weatherService.currentWeather {
            HStack(spacing: 12) {
                // Today's weather
                HStack(spacing: 6) {
                    Image(systemName: weather.iconName(for: weather.todayIcon))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.yellow, Color.orange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text(weather.todayTemperatureString)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(textPrimary)
                }
                .frame(maxWidth: .infinity)
                
                // Separator
                Text("|")
                    .font(.system(size: 16, weight: .light))
                    .foregroundStyle(textSecondary.opacity(0.4))
                
                // Sunrise
                HStack(spacing: 6) {
                    Image(systemName: "sunrise.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.yellow, Color.orange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text(weather.sunriseTimeString)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(textPrimary)
                }
                .frame(maxWidth: .infinity)
                
                // Separator
                Text("|")
                    .font(.system(size: 16, weight: .light))
                    .foregroundStyle(textSecondary.opacity(0.4))
                
                // Tomorrow's weather
                HStack(spacing: 6) {
                    Image(systemName: weather.iconName(for: weather.tomorrowIcon))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [accentCyan, accentBlue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text(weather.tomorrowTemperatureString)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(textPrimary)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(
                ZStack {
                    // Subtle gradient background
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [weatherGradientStart, weatherGradientEnd],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    // Glowing border effect
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    accentBlue.opacity(0.4),
                                    accentCyan.opacity(0.4),
                                    accentBlue.opacity(0.4)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                        .shadow(color: accentBlue.opacity(0.3), radius: 4, x: 0, y: 0)
                }
            )
            .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 2)
        } else if weatherService.isLoading {
            HStack(spacing: 12) {
                ProgressView()
                    .tint(accentBlue)
                Text("Loading weather...")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(textSecondary)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [weatherGradientStart, weatherGradientEnd],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
        } else if let error = weatherService.errorMessage {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.orange)
                Text(error)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(textSecondary)
                    .lineLimit(2)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [weatherGradientStart, weatherGradientEnd],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
        } else {
            // Initial state - show refresh button
            Button(action: {
                weatherService.requestLocationAndFetchWeather()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Get Weather")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(accentBlue)
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [weatherGradientStart, weatherGradientEnd],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(accentBlue.opacity(0.5), lineWidth: 1.5)
                        )
                )
                .shadow(color: accentBlue.opacity(0.2), radius: 4, x: 0, y: 2)
            }
        }
    }
    
}

#Preview {
    WeatherBarView(weatherService: WeatherService())
        .padding()
        .background(Color(red: 0.05, green: 0.05, blue: 0.08))
}

