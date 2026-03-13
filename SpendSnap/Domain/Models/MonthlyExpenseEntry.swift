// Domain/Models/MonthlyExpenseEntry.swift
// SpendSnap

import Foundation
import SwiftData

/// A concrete expense record for a specific month.
/// Supports three entry types:
/// - "fixed": Standard recurring amount (rent, insurance, parking)
/// - "petrol": Fuel fill-up with mileage tracking
/// - "grocery": Grocery purchase with item list
///
@Model
final class MonthlyExpenseEntry {
    
    // MARK: - Core Properties
    
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
    
    // MARK: - Entry Type
    /// "fixed" (default), "petrol", or "grocery"
    var entryType: String
    
    // MARK: - Receipt / Photo
    var photoFileName: String?
    var vendor: String?
    
    // MARK: - Petrol-specific
    var odometerReading: Double?
    var litersFilled: Double?
    var pricePerLiter: Decimal?
    
    // MARK: - Grocery-specific
    var itemNotes: String?
    
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
        entryType: String = "fixed",
        odometerReading: Double? = nil,
        litersFilled: Double? = nil,
        pricePerLiter: Decimal? = nil,
        itemNotes: String? = nil,
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
        self.entryType = entryType
        self.odometerReading = odometerReading
        self.litersFilled = litersFilled
        self.pricePerLiter = pricePerLiter
        self.itemNotes = itemNotes
        self.createdAt = createdAt
    }
}

// MARK: - Entry Type Enum

enum BudgetEntryType: String {
    case fixed = "fixed"
    case petrol = "petrol"
    case grocery = "grocery"
}

extension MonthlyExpenseEntry {
    var type: BudgetEntryType {
        get { BudgetEntryType(rawValue: entryType) ?? .fixed }
        set { entryType = newValue.rawValue }
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
            templateID: template.id.uuidString,
            entryType: "fixed"
        )
    }
}
