// Domain/Models/Expense.swift
// SpendSnap

import Foundation
import SwiftData

@Model
final class Expense {
    
    // MARK: - Properties
    
    var id: UUID
    var amount: Decimal
    var currency: String          // ISO 4217 code, default "SGD"
    var vendor: String?           // Optional merchant name
    var note: String?             // User notes
    var photoFileName: String     // Local filename of captured photo
    var date: Date                // Expense date (user-editable)
    var createdAt: Date
    var updatedAt: Date
    var syncStatus: String        // SyncStatus raw value (SwiftData doesn't support enums directly)
    
    // MARK: - Relationships
    
    var category: Category?
    
    // MARK: - Computed Properties
    
    /// Type-safe accessor for sync status
    var sync: SyncStatus {
        get { SyncStatus(rawValue: syncStatus) ?? .local }
        set { syncStatus = newValue.rawValue }
    }
    
    /// Formatted location string (e.g. "Kuala Lumpur, MY")
    var locationDisplay: String? {
        guard let city = locationCity, !city.isEmpty else { return nil }
        if let country = locationCountry, !country.isEmpty {
            return "\(city), \(country)"
        }
        return city
    }
    // MARK: - Init
    
    init(
        id: UUID = UUID(),
        amount: Decimal,
        currency: String = "SGD",
        category: Category? = nil,
        vendor: String? = nil,
        note: String? = nil,
        photoFileName: String,
        date: Date = Date(),
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        // Add to init parameters:
        locationCity: String? = nil,
        locationCountry: String? = nil,
        syncStatus: SyncStatus = .local
        
    ) {
        self.id = id
        self.amount = amount
        self.currency = currency
        self.category = category
        self.vendor = vendor
        self.note = note
        self.photoFileName = photoFileName
        self.date = date
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.syncStatus = syncStatus.rawValue
        self.locationCity = locationCity
        self.locationCountry = locationCountry
    }
    
    // Add these alongside the other properties:
    var locationCity: String?
    var locationCountry: String?
}

    
