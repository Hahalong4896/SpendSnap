// Domain/Models/RecurringTemplate.swift
// SpendSnap

import Foundation
import SwiftData

/// Template for a fixed monthly expense.
/// Phase 2.5b: Added costPerKm for vehicle maintenance calculation.
@Model
final class RecurringTemplate {
    
    var id: UUID
    var name: String
    var defaultAmount: Decimal
    var currency: String
    var sortOrder: Int
    var isActive: Bool
    var note: String?
    var createdAt: Date
    
    /// Cost per km for maintenance calculation (e.g., 0.20).
    /// When set, the template is treated as a mileage-based expense.
    /// Monthly amount = costPerKm × total distance from petrol entries.
    var costPerKm: Decimal?
    
    var expenseGroup: ExpenseGroup?
    var paymentSource: PaymentSource?
    
    init(
        id: UUID = UUID(),
        name: String,
        defaultAmount: Decimal,
        currency: String = "SGD",
        expenseGroup: ExpenseGroup? = nil,
        paymentSource: PaymentSource? = nil,
        sortOrder: Int = 0,
        isActive: Bool = true,
        note: String? = nil,
        costPerKm: Decimal? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.defaultAmount = defaultAmount
        self.currency = currency
        self.expenseGroup = expenseGroup
        self.paymentSource = paymentSource
        self.sortOrder = sortOrder
        self.isActive = isActive
        self.note = note
        self.costPerKm = costPerKm
        self.createdAt = createdAt
    }
}
