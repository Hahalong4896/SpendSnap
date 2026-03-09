// Domain/Models/RecurringTemplate.swift
// SpendSnap

import Foundation
import SwiftData

/// Template for a fixed monthly expense.
/// Configured once, auto-populated into each month's budget workspace.
///
/// Example: "Rent Installment" = RM2,500/month via TransferWise under Housing group
///
/// The template-to-instance pattern:
/// 1. User creates template (once)
/// 2. MonthlyBudgetService creates MonthlyExpenseEntry instances each month
/// 3. Instances copy defaultAmount but can be edited per-month
/// 4. Editing an instance does NOT change the template
///
@Model
final class RecurringTemplate {
    
    // MARK: - Properties
    
    var id: UUID
    var name: String                // Item name (e.g., "Electricity", "Car Insurance")
    var defaultAmount: Decimal      // Default monthly amount
    var currency: String            // Currency code (e.g., "SGD", "MYR")
    var sortOrder: Int              // Display order within group
    var isActive: Bool              // Active = included in monthly auto-population
    var note: String?               // Optional description
    var createdAt: Date
    
    // MARK: - Relationships
    // Using direct references (no inverse) per Phase 1 learning
    
    var expenseGroup: ExpenseGroup?
    var paymentSource: PaymentSource?
    
    // MARK: - Init
    
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
        self.createdAt = createdAt
    }
}
