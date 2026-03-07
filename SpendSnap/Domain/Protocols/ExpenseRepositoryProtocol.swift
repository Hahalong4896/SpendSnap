// Domain/Protocols/ExpenseRepositoryProtocol.swift
// SpendSnap

import Foundation

/// Defines the contract for expense data operations.
/// Concrete implementations live in the Data layer.
protocol ExpenseRepositoryProtocol {
    func saveExpense(_ expense: Expense) throws
    func fetchExpenses() throws -> [Expense]
    func fetchExpenses(for month: Int, year: Int) throws -> [Expense]
    func deleteExpense(_ expense: Expense) throws
    func updateExpense(_ expense: Expense) throws
}
