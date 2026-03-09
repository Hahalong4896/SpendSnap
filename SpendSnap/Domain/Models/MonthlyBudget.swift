// Domain/Models/MonthlyBudget.swift
// SpendSnap

import Foundation
import SwiftData

/// Lightweight metadata record for a month's budget.
/// Acts as an anchor — related IncomeEntry and MonthlyExpenseEntry
/// records are queried by matching (month, year).
///
/// Created automatically when user first opens a month's budget workspace.
///
@Model
final class MonthlyBudget {
    
    // MARK: - Properties
    
    var id: UUID
    var month: Int                  // 1-12
    var year: Int                   // e.g., 2026
    var isFinalized: Bool           // Whether user has "closed" the month
    var createdAt: Date
    var note: String?               // Optional month note
    
    // MARK: - Init
    
    init(
        id: UUID = UUID(),
        month: Int,
        year: Int,
        isFinalized: Bool = false,
        createdAt: Date = Date(),
        note: String? = nil
    ) {
        self.id = id
        self.month = month
        self.year = year
        self.isFinalized = isFinalized
        self.createdAt = createdAt
        self.note = note
    }
}
