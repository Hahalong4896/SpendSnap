// Domain/Models/IncomeEntry.swift
// SpendSnap

import Foundation
import SwiftData

/// Records income for a specific month.
/// Supports multiple income streams per month (Salary, Part Time, Bonus, etc.).
///
@Model
final class IncomeEntry {
    
    // MARK: - Properties
    
    var id: UUID
    var name: String                // Income source name (e.g., "Salary", "Part Time")
    var amount: Decimal             // Income amount
    var currency: String            // Currency code (default: "SGD")
    var month: Int                  // 1-12
    var year: Int                   // e.g., 2026
    var note: String?               // Optional note
    var createdAt: Date
    
    // MARK: - Relationships
    
    var paymentSource: PaymentSource?   // Which account receives this income
    
    // MARK: - Init
    
    init(
        id: UUID = UUID(),
        name: String,
        amount: Decimal,
        currency: String = "SGD",
        month: Int,
        year: Int,
        paymentSource: PaymentSource? = nil,
        note: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.amount = amount
        self.currency = currency
        self.month = month
        self.year = year
        self.paymentSource = paymentSource
        self.note = note
        self.createdAt = createdAt
    }
}
