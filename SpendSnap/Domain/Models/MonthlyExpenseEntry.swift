// Domain/Models/MonthlyExpenseEntry.swift
// SpendSnap

import Foundation
import SwiftData

/// A concrete expense record for a specific month.
/// Typically instantiated from a RecurringTemplate, but can also be created manually.
///
/// Phase 2.5 update: Added photoFileName and vendor to support receipt capture
/// for items like groceries and petrol that need photo tracking.
///
@Model
final class MonthlyExpenseEntry {
    
    // MARK: - Properties
    
    var id: UUID
    var name: String
    var amount: Decimal
    var currency: String
    var month: Int
    var year: Int
    var isPaid: Bool
    var paidDate: Date?
    var note: String?
    var createdAt: Date
    
    // MARK: - Receipt capture support
    var photoFileName: String?      // Local filename of captured receipt photo
    var vendor: String?             // Shop/station name
    
    // MARK: - Template reference
    var templateID: String?
    
    // MARK: - Relationships
    
    var expenseGroup: ExpenseGroup?
    var paymentSource: PaymentSource?
    
    // MARK: - Init
    
    init(
        id: UUID = UUID(),
        name: String,
        amount: Decimal,
        currency: String = "SGD",
        month: Int,
        year: Int,
        isPaid: Bool = false,
        paidDate: Date? = nil,
        expenseGroup: ExpenseGroup? = nil,
        paymentSource: PaymentSource? = nil,
        templateID: String? = nil,
        note: String? = nil,
        photoFileName: String? = nil,
        vendor: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.amount = amount
        self.currency = currency
        self.month = month
        self.year = year
        self.isPaid = isPaid
        self.paidDate = paidDate
        self.expenseGroup = expenseGroup
        self.paymentSource = paymentSource
        self.templateID = templateID
        self.note = note
        self.photoFileName = photoFileName
        self.vendor = vendor
        self.createdAt = createdAt
    }
}

// MARK: - Convenience: Create from template

extension MonthlyExpenseEntry {
    static func fromTemplate(_ template: RecurringTemplate, month: Int, year: Int) -> MonthlyExpenseEntry {
        MonthlyExpenseEntry(
            name: template.name,
            amount: template.defaultAmount,
            currency: template.currency,
            month: month,
            year: year,
            expenseGroup: template.expenseGroup,
            paymentSource: template.paymentSource,
            templateID: template.id.uuidString
        )
    }
}
