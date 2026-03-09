// Domain/Models/Currency+Helpers.swift
// SpendSnap
//
// SINGLE source of truth for the Currency enum.
// DELETE the Currency enum from AmountInputView.swift (lines 7-57 there).
// Keep only the AmountInputView struct and CurrencyPickerSheet in that file.

import Foundation

/// Supported currencies with flag and symbol information.
/// Used throughout the app for pickers, display, and conversion.
enum Currency: String, CaseIterable, Identifiable, Hashable {
    case sgd = "SGD"
    case myr = "MYR"
    case thb = "THB"
    case jpy = "JPY"
    case eur = "EUR"
    case usd = "USD"
    case gbp = "GBP"
    case cny = "CNY"
    
    var id: String { rawValue }
    
    /// Currency symbol for display (e.g., "S$", "RM")
    /// NOTE: Keep property name as "symbol" to match existing usage in AmountInputView
    var symbol: String {
        switch self {
        case .sgd: return "S$"
        case .myr: return "RM"
        case .thb: return "฿"
        case .jpy: return "¥"
        case .eur: return "€"
        case .usd: return "$"
        case .gbp: return "£"
        case .cny: return "¥"
        }
    }
    
    /// Full currency name
    var name: String {
        switch self {
        case .sgd: return "Singapore Dollar"
        case .myr: return "Malaysian Ringgit"
        case .thb: return "Thai Baht"
        case .jpy: return "Japanese Yen"
        case .eur: return "Euro"
        case .usd: return "US Dollar"
        case .gbp: return "British Pound"
        case .cny: return "Chinese Yuan"
        }
    }
    
    /// Flag emoji for display
    var flag: String {
        switch self {
        case .sgd: return "🇸🇬"
        case .myr: return "🇲🇾"
        case .thb: return "🇹🇭"
        case .jpy: return "🇯🇵"
        case .eur: return "🇪🇺"
        case .usd: return "🇺🇸"
        case .gbp: return "🇬🇧"
        case .cny: return "🇨🇳"
        }
    }
    
    // MARK: - Static Helpers (used by Phase 2.5 screens)
    
    /// Get symbol from currency code string (e.g., "SGD" → "S$")
    static func symbol(for code: String) -> String {
        Currency(rawValue: code)?.symbol ?? code
    }
    
    /// Get flag from currency code string
    static func flag(for code: String) -> String {
        Currency(rawValue: code)?.flag ?? "🏳️"
    }
}
