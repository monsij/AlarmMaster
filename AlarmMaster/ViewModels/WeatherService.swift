//
//  WeatherService.swift
//  AlarmMaster
//

import Foundation
import CoreLocation
import Combine

class WeatherService: NSObject, ObservableObject {
    @Published var currentWeather: Weather?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiKey: String
    private let locationManager = CLLocationManager()
    private var cancellables = Set<AnyCancellable>()
    
    // You can get a free API key from https://openweathermap.org/api
    // Set your API key in one of these ways:
    // 1. Create a Config.plist file in the AlarmMaster folder with key "OpenWeatherAPIKey"
    // 2. Or directly replace "YOUR_API_KEY_HERE" below with your API key
    private static let defaultAPIKey = "YOUR_API_KEY_HERE"
    
    override init() {
        // Try to load API key from Config.plist first, then fall back to default
        if let configPath = Bundle.main.path(forResource: "Config", ofType: "plist"),
           let configDict = NSDictionary(contentsOfFile: configPath),
           let apiKey = configDict["OpenWeatherAPIKey"] as? String,
           !apiKey.isEmpty {
            self.apiKey = apiKey
        } else {
            self.apiKey = Self.defaultAPIKey
        }
        
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
    }
    
    func requestLocationAndFetchWeather() {
        guard apiKey != "YOUR_API_KEY_HERE" else {
            errorMessage = "Please set your OpenWeatherMap API key"
            return
        }
        
        let status = locationManager.authorizationStatus
        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestLocation()
        case .denied, .restricted:
            errorMessage = "Location access denied. Please enable location services in Settings."
        @unknown default:
            break
        }
    }
    
    private func fetchWeather(latitude: Double, longitude: Double) {
        isLoading = true
        errorMessage = nil
        
        // Fetch current weather
        let currentURL = URL(string: "https://api.openweathermap.org/data/2.5/weather?lat=\(latitude)&lon=\(longitude)&appid=\(apiKey)&units=metric")!
        
        // Fetch forecast for precipitation chance
        let forecastURL = URL(string: "https://api.openweathermap.org/data/2.5/forecast?lat=\(latitude)&lon=\(longitude)&appid=\(apiKey)&units=metric")!
        
        let currentPublisher = URLSession.shared.dataTaskPublisher(for: currentURL)
            .tryMap { data, response -> Data in
                // First check if it's an error response
                if let errorResponse = try? JSONDecoder().decode(WeatherAPIError.self, from: data),
                   let message = errorResponse.message {
                    print("❌ Weather API Error: \(message)")
                    throw NSError(domain: "WeatherService", code: 1, userInfo: [NSLocalizedDescriptionKey: message])
                }
                
                // Log raw response for debugging if decoding fails
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("📡 Current Weather API Response: \(jsonString.prefix(500))")
                }
                
                return data
            }
            .decode(type: WeatherResponse.self, decoder: JSONDecoder())
            .handleEvents(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("❌ Failed to decode current weather: \(error)")
                }
            })
            .eraseToAnyPublisher()
        
        let forecastPublisher = URLSession.shared.dataTaskPublisher(for: forecastURL)
            .tryMap { data, response -> Data in
                // First check if it's an error response
                if let errorResponse = try? JSONDecoder().decode(WeatherAPIError.self, from: data),
                   let message = errorResponse.message {
                    print("❌ Forecast API Error: \(message)")
                    throw NSError(domain: "WeatherService", code: 1, userInfo: [NSLocalizedDescriptionKey: message])
                }
                
                // Log raw response for debugging if decoding fails
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("📡 Forecast API Response: \(jsonString.prefix(500))")
                }
                
                return data
            }
            .decode(type: ForecastResponse.self, decoder: JSONDecoder())
            .handleEvents(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("❌ Failed to decode forecast: \(error)")
                }
            })
            .eraseToAnyPublisher()
        
        Publishers.Zip(currentPublisher, forecastPublisher)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        let errorMsg = error.localizedDescription
                        self?.errorMessage = "Weather unavailable: \(errorMsg)"
                        print("Weather fetch error: \(error)")
                        
                        // Log raw response for debugging
                        if let nsError = error as NSError? {
                            print("Error domain: \(nsError.domain), code: \(nsError.code)")
                        }
                    }
                },
                receiveValue: { [weak self] current, forecast in
                    self?.processWeatherData(current: current, forecast: forecast)
                }
            )
            .store(in: &cancellables)
    }
    
    private func processWeatherData(current: WeatherResponse, forecast: ForecastResponse) {
        // Get today's temperature and icon
        let todayTemp = current.main.temp
        let todayIcon = current.weather.first?.icon ?? "01d"
        
        // Get tomorrow's forecast (typically around 24 hours from now)
        // Find the forecast item that's closest to tomorrow at noon, or the first item tomorrow
        let calendar = Calendar.current
        let now = Date()
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now)!
        let tomorrowNoon = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: tomorrow)!
        
        // Find the forecast item closest to tomorrow noon
        var tomorrowForecast: ForecastResponse.ForecastItem? = nil
        var minTimeDifference: TimeInterval = Double.greatestFiniteMagnitude
        
        for item in forecast.list {
            let itemDate = Date(timeIntervalSince1970: item.dt)
            let timeDiff = abs(itemDate.timeIntervalSince(tomorrowNoon))
            
            // Only consider items that are actually tomorrow
            if calendar.isDate(itemDate, inSameDayAs: tomorrow) {
                if timeDiff < minTimeDifference {
                    minTimeDifference = timeDiff
                    tomorrowForecast = item
                }
            }
        }
        
        // Fallback: if no tomorrow forecast found, use the first forecast item that's after 18 hours
        if tomorrowForecast == nil {
            let futureDate = now.addingTimeInterval(18 * 60 * 60) // 18 hours from now
            tomorrowForecast = forecast.list.first { item in
                Date(timeIntervalSince1970: item.dt) >= futureDate
            }
        }
        
        // Fallback: use the first forecast item if still nothing found
        let tomorrowTemp = tomorrowForecast?.main.temp ?? todayTemp
        let tomorrowIcon = tomorrowForecast?.weather.first?.icon ?? todayIcon
        
        // Get sunrise time (Unix timestamp)
        let sunriseTime = Date(timeIntervalSince1970: current.sys.sunrise)
        
        currentWeather = Weather(
            todayTemperature: todayTemp,
            todayIcon: todayIcon,
            tomorrowTemperature: tomorrowTemp,
            tomorrowIcon: tomorrowIcon,
            sunriseTime: sunriseTime
        )
    }
}

extension WeatherService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        fetchWeather(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        isLoading = false
        errorMessage = "Failed to get location: \(error.localizedDescription)"
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        case .denied, .restricted:
            errorMessage = "Location access denied"
        default:
            break
        }
    }
}

