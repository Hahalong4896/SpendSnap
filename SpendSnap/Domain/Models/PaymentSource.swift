// Domain/Models/PaymentSource.swift
// SpendSnap

import Foundation
import SwiftData

/// User-configurable payment source (bank account, e-wallet, cash).
/// No defaults are seeded — user creates all sources in Settings.
///
/// Examples: "OCBC", "DBS", "TransferWise", "Cash", "CPF"
///
@Model
final class PaymentSource {
    
    // MARK: - Properties
    
    var id: UUID
    var name: String                // Display name (e.g., "OCBC")
    var icon: String                // SF Symbol name (e.g., "building.columns")
    var colorHex: String            // Colour for badges/charts (e.g., "#0984e3")
    var sortOrder: Int              // Display order in pickers
    var isActive: Bool              // Soft-delete: hidden when false
    var note: String?               // Optional note (e.g., account hint)
    var createdAt: Date
    
    // MARK: - Init
    
    init(
        id: UUID = UUID(),
        name: String,
        icon: String = "building.columns",
        colorHex: String = "#636e72",
        sortOrder: Int = 0,
        isActive: Bool = true,
        note: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.sortOrder = sortOrder
        self.isActive = isActive
        self.note = note
        self.createdAt = createdAt
    }
}
