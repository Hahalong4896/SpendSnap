// Infrastructure/LocationService.swift
// SpendSnap

import CoreLocation

/// Auto-detects user's current city and country using CoreLocation.
/// Uses reverse geocoding to convert coordinates to place names.
final class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    // MARK: - Singleton
    
    static let shared = LocationService()
    
    // MARK: - Published State
    
    @Published var currentCity: String?
    @Published var currentCountry: String?
    @Published var isAuthorised = false
    
    // MARK: - Private
    
    private let manager = CLLocationManager()
    private var completion: ((String?, String?) -> Void)?
    
    // MARK: - Init
    
    private override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }
    
    // MARK: - Request Permission
    
    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }
    
    // MARK: - Detect Location
    
    /// Fetches current city and country. Calls completion with (city, countryCode).
    func detectLocation(completion: @escaping (String?, String?) -> Void) {
        self.completion = completion
        
        let status = manager.authorizationStatus
        
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        case .notDetermined:
            self.completion = completion
            manager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            completion(nil, nil)
        @unknown default:
            completion(nil, nil)
        }
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            completion?(nil, nil)
            completion = nil
            return
        }
        
        // Reverse geocode to get city + country
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            DispatchQueue.main.async {
                if let placemark = placemarks?.first {
                    let city = placemark.locality ?? placemark.administrativeArea
                    let country = placemark.isoCountryCode  // "SG", "MY", "JP"
                    
                    self?.currentCity = city
                    self?.currentCountry = country
                    self?.completion?(city, country)
                } else {
                    self?.completion?(nil, nil)
                }
                self?.completion = nil
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
        completion?(nil, nil)
        completion = nil
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        isAuthorised = (status == .authorizedWhenInUse || status == .authorizedAlways)
        
        // If just authorised and we have a pending completion, request location
        if isAuthorised, completion != nil {
            manager.requestLocation()
        }
    }
}
