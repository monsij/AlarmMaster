//
//  Weather.swift
//  AlarmMaster
//

import Foundation

struct Weather: Codable {
    let todayTemperature: Double
    let todayIcon: String
    let tomorrowTemperature: Double
    let tomorrowIcon: String
    let sunriseTime: Date
    
    var todayTemperatureString: String {
        "\(Int(todayTemperature))°"
    }
    
    var tomorrowTemperatureString: String {
        "\(Int(tomorrowTemperature))°"
    }
    
    var sunriseTimeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: sunriseTime)
    }
    
    // Helper to get SF Symbol name from OpenWeather icon code
    func iconName(for iconCode: String) -> String {
        // OpenWeather icon codes: https://openweathermap.org/weather-conditions
        switch iconCode {
        case "01d", "01n": return "sun.max.fill" // clear sky
        case "02d", "02n": return "cloud.sun.fill" // few clouds
        case "03d", "03n": return "cloud.fill" // scattered clouds
        case "04d", "04n": return "cloud.fill" // broken clouds
        case "09d", "09n": return "cloud.rain.fill" // shower rain
        case "10d", "10n": return "cloud.sun.rain.fill" // rain
        case "11d", "11n": return "cloud.bolt.fill" // thunderstorm
        case "13d", "13n": return "cloud.snow.fill" // snow
        case "50d", "50n": return "cloud.fog.fill" // mist
        default: return "sun.max.fill"
        }
    }
}

struct WeatherResponse: Codable {
    let main: MainWeather
    let weather: [WeatherCondition]
    let sys: SystemInfo
    let rain: Rain?
    let snow: Snow?
    
    struct MainWeather: Codable {
        let temp: Double
    }
    
    struct WeatherCondition: Codable {
        let main: String
        let icon: String
    }
    
    struct SystemInfo: Codable {
        let sunrise: TimeInterval
        let sunset: TimeInterval
    }
    
    struct Rain: Codable {
        let oneHour: Double?
        
        enum CodingKeys: String, CodingKey {
            case oneHour = "1h"
        }
    }
    
    struct Snow: Codable {
        let oneHour: Double?
        
        enum CodingKeys: String, CodingKey {
            case oneHour = "1h"
        }
    }
}

struct ForecastResponse: Codable {
    let list: [ForecastItem]
    
    struct ForecastItem: Codable {
        let dt: TimeInterval
        let main: MainWeather
        let weather: [WeatherCondition]
        let pop: Double // Probability of precipitation (0-1)
        
        struct MainWeather: Codable {
            let temp: Double
        }
        
        struct WeatherCondition: Codable {
            let main: String
            let icon: String
        }
    }
}

struct WeatherAPIError: Codable {
    let cod: ErrorCode?
    let message: String?
    
    enum ErrorCode: Codable {
        case string(String)
        case int(Int)
        
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let intValue = try? container.decode(Int.self) {
                self = .int(intValue)
            } else if let stringValue = try? container.decode(String.self) {
                self = .string(stringValue)
            } else {
                throw DecodingError.typeMismatch(ErrorCode.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected Int or String"))
            }
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .int(let value):
                try container.encode(value)
            case .string(let value):
                try container.encode(value)
            }
        }
    }
}

