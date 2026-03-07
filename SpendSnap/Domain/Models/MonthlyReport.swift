// Domain/Models/MonthlyReport.swift
// SpendSnap

import Foundation
import SwiftData

@Model
final class MonthlyReport {
    
    // MARK: - Properties
    
    var id: UUID
    var month: Int              // 1-12
    var year: Int               // e.g., 2026
    var totalSpend: Decimal
    var transactionCount: Int
    var categoryBreakdown: Data? // JSON-encoded [String: Decimal]
    var topCategory: String
    var generatedAt: Date
    var pdfFileName: String?    // Local filename of exported PDF
    
    // MARK: - Computed Properties
    
    /// Decode category breakdown from stored JSON
    var breakdown: [String: Decimal] {
        get {
            guard let data = categoryBreakdown else { return [:] }
            return (try? JSONDecoder().decode([String: Decimal].self, from: data)) ?? [:]
        }
        set {
            categoryBreakdown = try? JSONEncoder().encode(newValue)
        }
    }
    
    // MARK: - Init
    
    init(
        id: UUID = UUID(),
        month: Int,
        year: Int,
        totalSpend: Decimal = 0,
        transactionCount: Int = 0,
        topCategory: String = "",
        generatedAt: Date = Date(),
        pdfFileName: String? = nil
    ) {
        self.id = id
        self.month = month
        self.year = year
        self.totalSpend = totalSpend
        self.transactionCount = transactionCount
        self.topCategory = topCategory
        self.generatedAt = generatedAt
        self.pdfFileName = pdfFileName
    }
}
