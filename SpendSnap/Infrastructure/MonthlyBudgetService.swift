// Infrastructure/MonthlyBudgetService.swift
// SpendSnap

import Foundation
import SwiftData

/// Service that manages monthly budget workspace lifecycle.
struct MonthlyBudgetService {
    
    // MARK: - Ensure Budget Exists
    
    /// Ensures a MonthlyBudget record exists for the given month.
    /// If budget doesn't exist, creates it and populates from templates.
    @discardableResult
    static func ensureBudget(month: Int, year: Int, context: ModelContext) -> MonthlyBudget {
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
    
    // MARK: - Re-generate from Templates
    
    /// Deletes all template-generated entries for the month, then re-populates.
    /// Preserves manually added entries and itemised entries (petrol, grocery).
    static func regenerateFromTemplates(month: Int, year: Int, context: ModelContext) {
        // 1. Delete existing template-generated entries (templateID != nil)
        let allDescriptor = FetchDescriptor<MonthlyExpenseEntry>(
            predicate: #Predicate<MonthlyExpenseEntry> { $0.month == month && $0.year == year }
        )
        if let allEntries = try? context.fetch(allDescriptor) {
            for entry in allEntries where entry.templateID != nil {
                context.delete(entry)
            }
        }
        try? context.save()
        
        // 2. Force re-populate from templates (ignore existing count)
        forcePopulateFromTemplates(month: month, year: year, context: context)
        
        try? context.save()
    }
    
    // MARK: - Fetch Budget
    
    static func fetchBudget(month: Int, year: Int, context: ModelContext) -> MonthlyBudget? {
        let descriptor = FetchDescriptor<MonthlyBudget>(
            predicate: #Predicate<MonthlyBudget> { $0.month == month && $0.year == year }
        )
        return try? context.fetch(descriptor).first
    }
    
    // MARK: - Populate from Templates
    
    /// Creates MonthlyExpenseEntry instances from all active RecurringTemplates.
    /// Only runs if no TEMPLATE-GENERATED entries exist (preserves manual/itemised entries).
    private static func populateFromTemplates(month: Int, year: Int, context: ModelContext) {
        // Check if template-generated entries already exist
        let allDescriptor = FetchDescriptor<MonthlyExpenseEntry>(
            predicate: #Predicate<MonthlyExpenseEntry> { $0.month == month && $0.year == year }
        )
        let allEntries = (try? context.fetch(allDescriptor)) ?? []
        let templateEntries = allEntries.filter { $0.templateID != nil }
        
        // Only populate if no template entries exist yet
        guard templateEntries.isEmpty else { return }
        
        forcePopulateFromTemplates(month: month, year: year, context: context)
    }
    
    /// Force-creates entries from all active templates, regardless of existing entries.
    private static func forcePopulateFromTemplates(month: Int, year: Int, context: ModelContext) {
        let templateDescriptor = FetchDescriptor<RecurringTemplate>(
            predicate: #Predicate<RecurringTemplate> { $0.isActive },
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        guard let templates = try? context.fetch(templateDescriptor) else { return }
        
        for template in templates {
            let entry = MonthlyExpenseEntry.fromTemplate(template, month: month, year: year)
            context.insert(entry)
        }
    }
    
    // MARK: - Fetch Monthly Expense Entries
    
    static func fetchEntries(month: Int, year: Int, context: ModelContext) -> [MonthlyExpenseEntry] {
        let descriptor = FetchDescriptor<MonthlyExpenseEntry>(
            predicate: #Predicate<MonthlyExpenseEntry> { $0.month == month && $0.year == year },
            sortBy: [SortDescriptor(\.createdAt)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }
    
    // MARK: - Fetch Income Entries
    
    static func fetchIncome(month: Int, year: Int, context: ModelContext) -> [IncomeEntry] {
        let descriptor = FetchDescriptor<IncomeEntry>(
            predicate: #Predicate<IncomeEntry> { $0.month == month && $0.year == year },
            sortBy: [SortDescriptor(\.createdAt)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }
    
    // MARK: - Carry Forward Income
    
    static func carryForwardIncome(toMonth month: Int, year: Int, context: ModelContext) {
        let existingIncome = fetchIncome(month: month, year: year, context: context)
        guard existingIncome.isEmpty else { return }
        
        var prevMonth = month - 1
        var prevYear = year
        if prevMonth < 1 { prevMonth = 12; prevYear -= 1 }
        
        let prevIncome = fetchIncome(month: prevMonth, year: prevYear, context: context)
        guard !prevIncome.isEmpty else { return }
        
        for income in prevIncome {
            let newEntry = IncomeEntry(
                name: income.name, amount: income.amount, currency: income.currency,
                month: month, year: year, paymentSource: income.paymentSource, note: income.note
            )
            context.insert(newEntry)
        }
        try? context.save()
    }
}
