// Infrastructure/CurrencyService.swift
// SpendSnap

import Foundation

/// Fetches and caches live exchange rates.
/// Base currency: SGD. Rates represent how much 1 unit of foreign currency = X SGD.
///
/// Example: If MYR rate is 0.29, then RM1.00 = S$0.29
///
@Observable
final class CurrencyService {
    
    // MARK: - Singleton
    
    static let shared = CurrencyService()
    
    // MARK: - State
    
    var rates: [String: Double] = [:]
    var lastUpdated: Date?
    var isLoading = false
    var errorMessage: String?
    
    // MARK: - Constants
    
    /// Free API — no key required, 1500 requests/month
    private let apiURL = "https://open.er-api.com/v6/latest/SGD"
    
    /// UserDefaults keys for caching
    private let ratesKey = "cached_exchange_rates"
    private let lastUpdatedKey = "rates_last_updated"
    
    // MARK: - Init
    
    private init() {
        loadCachedRates()
    }
    
    // MARK: - Fetch Rates
    
    /// Fetches latest exchange rates from API.
    /// Rates are relative to SGD (base currency).
    func fetchRates() async {
        // Don't fetch if already updated today
        if let lastUpdated = lastUpdated,
           Calendar.current.isDateInToday(lastUpdated) {
            return
        }
        
        await MainActor.run { isLoading = true }
        
        do {
            guard let url = URL(string: apiURL) else {
                throw CurrencyError.invalidURL
            }
            
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw CurrencyError.serverError
            }
            
            let decoded = try JSONDecoder().decode(ExchangeRateResponse.self, from: data)
            
            // The API returns rates FROM SGD TO other currencies.
            // We need the inverse: how much SGD is 1 unit of foreign currency.
            // e.g., API says SGD→MYR = 3.45, so 1 MYR = 1/3.45 SGD = 0.2899 SGD
            var convertedRates: [String: Double] = ["SGD": 1.0]
            
            for (code, rate) in decoded.rates {
                if rate > 0 {
                    convertedRates[code] = 1.0 / rate
                }
            }
            
            await MainActor.run {
                self.rates = convertedRates
                self.lastUpdated = Date()
                self.isLoading = false
                self.errorMessage = nil
            }
            
            // Cache to UserDefaults
            cacheRates(convertedRates)
            
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = "Failed to fetch rates: \(error.localizedDescription)"
            }
            
            // Use fallback rates if no cached rates exist
            if rates.isEmpty {
                await MainActor.run {
                    self.rates = Self.fallbackRates
                }
            }
        }
    }
    
    // MARK: - Convert
    
    /// Converts an amount from a given currency to SGD.
    /// - Parameters:
    ///   - amount: The amount in the original currency
    ///   - from: The currency code (e.g., "MYR", "USD")
    /// - Returns: The equivalent amount in SGD
    func convertToSGD(amount: Decimal, from currency: String) -> Decimal {
        if currency == "SGD" { return amount }
        
        guard let rate = rates[currency] else {
            // If no rate available, return original amount
            return amount
        }
        
        return amount * Decimal(rate)
    }
    
    /// Converts an amount from SGD to a given currency.
    func convertFromSGD(amount: Decimal, to currency: String) -> Decimal {
        if currency == "SGD" { return amount }
        
        guard let rate = rates[currency], rate > 0 else {
            return amount
        }
        
        return amount / Decimal(rate)
    }
    
    /// Get the display rate string (e.g., "1 MYR = 0.29 SGD")
    func rateDescription(for currency: String) -> String? {
        guard currency != "SGD",
              let rate = rates[currency] else { return nil }
        return String(format: "1 %@ = %.4f SGD", currency, rate)
    }
    
    // MARK: - Cache
    
    private func cacheRates(_ rates: [String: Double]) {
        UserDefaults.standard.set(rates, forKey: ratesKey)
        UserDefaults.standard.set(Date(), forKey: lastUpdatedKey)
    }
    
    private func loadCachedRates() {
        if let cached = UserDefaults.standard.dictionary(forKey: ratesKey) as? [String: Double] {
            self.rates = cached
        }
        if let date = UserDefaults.standard.object(forKey: lastUpdatedKey) as? Date {
            self.lastUpdated = date
        }
        
        // Use fallback if nothing cached
        if rates.isEmpty {
            rates = Self.fallbackRates
        }
    }
    
    // MARK: - Fallback Rates (approximate, updated March 2026)
    
    /// Hardcoded fallback rates: 1 unit of currency = X SGD
    static let fallbackRates: [String: Double] = [
        "SGD": 1.0,
        "MYR": 0.29,     // 1 MYR ≈ 0.29 SGD
        "THB": 0.038,     // 1 THB ≈ 0.038 SGD
        "JPY": 0.0089,    // 1 JPY ≈ 0.0089 SGD
        "EUR": 1.45,      // 1 EUR ≈ 1.45 SGD
        "USD": 1.34,      // 1 USD ≈ 1.34 SGD
        "GBP": 1.70,      // 1 GBP ≈ 1.70 SGD
        "CNY": 0.185      // 1 CNY ≈ 0.185 SGD
    ]
}

// MARK: - API Response Model

private struct ExchangeRateResponse: Decodable {
    let result: String
    let rates: [String: Double]
}

// MARK: - Errors

enum CurrencyError: LocalizedError {
    case invalidURL
    case serverError
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid API URL"
        case .serverError: return "Server returned an error"
        case .decodingError: return "Failed to decode rates"
        }
    }
}
