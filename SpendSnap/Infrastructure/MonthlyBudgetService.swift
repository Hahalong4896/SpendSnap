// Infrastructure/MonthlyBudgetService.swift
// SpendSnap

import Foundation
import SwiftData

/// Service that manages monthly budget workspace lifecycle.
///
/// Responsibilities:
/// - Create MonthlyBudget record for a new month
/// - Auto-populate MonthlyExpenseEntry instances from active RecurringTemplates
/// - Optionally carry forward income entries from previous month
///
struct MonthlyBudgetService {
    
    // MARK: - Ensure Budget Exists
    
    /// Ensures a MonthlyBudget record exists for the given month.
    /// If not, creates it and populates recurring expense entries from templates.
    ///
    /// - Parameters:
    ///   - month: Target month (1-12)
    ///   - year: Target year (e.g., 2026)
    ///   - context: SwiftData model context
    /// - Returns: The existing or newly created MonthlyBudget
    @discardableResult
    static func ensureBudget(month: Int, year: Int, context: ModelContext) -> MonthlyBudget {
        // Check if budget already exists for this month
        if let existing = fetchBudget(month: month, year: year, context: context) {
            return existing
        }
        
        // Create new budget
        let budget = MonthlyBudget(month: month, year: year)
        context.insert(budget)
        
        // Auto-populate from active templates
        populateFromTemplates(month: month, year: year, context: context)
        
        try? context.save()
        return budget
    }
    
    // MARK: - Fetch Budget
    
    /// Fetches the MonthlyBudget for a given month/year, if it exists.
    static func fetchBudget(month: Int, year: Int, context: ModelContext) -> MonthlyBudget? {
        let descriptor = FetchDescriptor<MonthlyBudget>(
            predicate: #Predicate<MonthlyBudget> { $0.month == month && $0.year == year }
        )
        return try? context.fetch(descriptor).first
    }
    
    // MARK: - Populate from Templates
    
    /// Creates MonthlyExpenseEntry instances from all active RecurringTemplates.
    /// Only runs if no entries exist for the target month yet.
    private static func populateFromTemplates(month: Int, year: Int, context: ModelContext) {
        // Check if entries already exist (safety guard)
        let existingDescriptor = FetchDescriptor<MonthlyExpenseEntry>(
            predicate: #Predicate<MonthlyExpenseEntry> { $0.month == month && $0.year == year }
        )
        let existingCount = (try? context.fetchCount(existingDescriptor)) ?? 0
        guard existingCount == 0 else { return }
        
        // Fetch all active templates
        let templateDescriptor = FetchDescriptor<RecurringTemplate>(
            predicate: #Predicate<RecurringTemplate> { $0.isActive },
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        guard let templates = try? context.fetch(templateDescriptor) else { return }
        
        // Create an instance for each template
        for template in templates {
            let entry = MonthlyExpenseEntry.fromTemplate(template, month: month, year: year)
            context.insert(entry)
        }
    }
    
    // MARK: - Fetch Monthly Expense Entries
    
    /// Fetches all MonthlyExpenseEntry records for a given month/year.
    static func fetchEntries(month: Int, year: Int, context: ModelContext) -> [MonthlyExpenseEntry] {
        let descriptor = FetchDescriptor<MonthlyExpenseEntry>(
            predicate: #Predicate<MonthlyExpenseEntry> { $0.month == month && $0.year == year },
            sortBy: [SortDescriptor(\.createdAt)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }
    
    // MARK: - Fetch Income Entries
    
    /// Fetches all IncomeEntry records for a given month/year.
    static func fetchIncome(month: Int, year: Int, context: ModelContext) -> [IncomeEntry] {
        let descriptor = FetchDescriptor<IncomeEntry>(
            predicate: #Predicate<IncomeEntry> { $0.month == month && $0.year == year },
            sortBy: [SortDescriptor(\.createdAt)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }
    
    // MARK: - Carry Forward Income
    
    /// Copies income entries from the previous month to the target month.
    /// Only runs if the target month has no income entries yet.
    static func carryForwardIncome(toMonth month: Int, year: Int, context: ModelContext) {
        // Check if income entries already exist for target month
        let existingIncome = fetchIncome(month: month, year: year, context: context)
        guard existingIncome.isEmpty else { return }
        
        // Calculate previous month
        var prevMonth = month - 1
        var prevYear = year
        if prevMonth < 1 {
            prevMonth = 12
            prevYear -= 1
        }
        
        // Fetch previous month's income
        let prevIncome = fetchIncome(month: prevMonth, year: prevYear, context: context)
        guard !prevIncome.isEmpty else { return }
        
        // Copy each income entry
        for income in prevIncome {
            let newEntry = IncomeEntry(
                name: income.name,
                amount: income.amount,
                currency: income.currency,
                month: month,
                year: year,
                paymentSource: income.paymentSource,
                note: income.note
            )
            context.insert(newEntry)
        }
        
        try? context.save()
    }
}
