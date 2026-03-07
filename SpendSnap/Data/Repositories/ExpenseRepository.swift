// Data/Repositories/ExpenseRepository.swift
// SpendSnap

import Foundation
import SwiftData

/// SwiftData implementation of ExpenseRepositoryProtocol.
/// Handles all CRUD operations for expenses.
final class ExpenseRepository: ExpenseRepositoryProtocol {
    
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - CRUD Operations
    
    func saveExpense(_ expense: Expense) throws {
        modelContext.insert(expense)
        try modelContext.save()
    }
    
    func fetchExpenses() throws -> [Expense] {
        let descriptor = FetchDescriptor<Expense>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    func fetchExpenses(for month: Int, year: Int) throws -> [Expense] {
        // Build date range for the given month
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1
        
        guard let startDate = Calendar.current.date(from: components),
              let endDate = Calendar.current.date(byAdding: .month, value: 1, to: startDate) else {
            return []
        }
        
        let descriptor = FetchDescriptor<Expense>(
            predicate: #Predicate<Expense> { expense in
                expense.date >= startDate && expense.date < endDate
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    func deleteExpense(_ expense: Expense) throws {
        // Delete associated photo
        PhotoStorageService.deletePhoto(named: expense.photoFileName)
        modelContext.delete(expense)
        try modelContext.save()
    }
    
    func updateExpense(_ expense: Expense) throws {
        expense.updatedAt = Date()
        try modelContext.save()
    }
}
