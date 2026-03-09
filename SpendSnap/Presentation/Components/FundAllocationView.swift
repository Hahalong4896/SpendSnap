// Presentation/Components/FundAllocationView.swift
// SpendSnap

import SwiftUI
import SwiftData

/// Displays a summary of how much needs to be transferred to each payment source.
/// Aggregates both recurring entries and daily expenses for the given month.
///
/// Usage:
/// FundAllocationView(
///     recurringEntries: monthlyEntries,
///     dailyExpenses: dailyExpensesList,
///     incomeEntries: incomeList
/// )
///
struct FundAllocationView: View {
    
    let recurringEntries: [MonthlyExpenseEntry]
    let dailyExpenses: [Expense]
    let incomeEntries: [IncomeEntry]
    
    // MARK: - Computed
    
    /// Aggregates all expenses by payment source, converted to SGD.
    private var allocationBySource: [(source: String, icon: String, colorHex: String, total: Decimal)] {
        let cs = CurrencyService.shared
        var dict: [String: (icon: String, colorHex: String, total: Decimal)] = [:]
        
        // Sum recurring entries
        for entry in recurringEntries {
            let sourceName = entry.paymentSource?.name ?? "Unassigned"
            let icon = entry.paymentSource?.icon ?? "questionmark.circle"
            let color = entry.paymentSource?.colorHex ?? "#b2bec3"
            let sgd = cs.convertToSGD(amount: entry.amount, from: entry.currency)
            let existing = dict[sourceName] ?? (icon: icon, colorHex: color, total: 0)
            dict[sourceName] = (icon: icon, colorHex: color, total: existing.total + sgd)
        }
        
        // Sum daily expenses
        for expense in dailyExpenses {
            let sourceName = expense.paymentSource?.name ?? "Unassigned"
            let icon = expense.paymentSource?.icon ?? "questionmark.circle"
            let color = expense.paymentSource?.colorHex ?? "#b2bec3"
            let sgd = cs.convertToSGD(amount: expense.amount, from: expense.currency)
            let existing = dict[sourceName] ?? (icon: icon, colorHex: color, total: 0)
            dict[sourceName] = (icon: icon, colorHex: color, total: existing.total + sgd)
        }
        
        return dict.map { (source: $0.key, icon: $0.value.icon, colorHex: $0.value.colorHex, total: $0.value.total) }
            .sorted { $0.total > $1.total }
    }
    
    /// Grand total of all allocations
    private var grandTotal: Decimal {
        allocationBySource.reduce(0) { $0 + $1.total }
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Fund Allocation")
                .font(.headline)
            
            if allocationBySource.isEmpty {
                Text("No expenses recorded")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(allocationBySource.enumerated()), id: \.element.source) { index, item in
                        HStack(spacing: 10) {
                            Image(systemName: item.icon)
                                .font(.subheadline)
                                .foregroundStyle(Color(hex: item.colorHex))
                                .frame(width: 24)
                            
                            Text(item.source)
                                .font(.subheadline)
                            
                            Spacer()
                            
                            Text("S$\(NSDecimalNumber(decimal: item.total).doubleValue, specifier: "%.2f")")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            
                            // Percentage
                            let pct = grandTotal > 0
                                ? NSDecimalNumber(decimal: item.total / grandTotal * 100).doubleValue
                                : 0
                            Text("\(pct, specifier: "%.0f")%")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(width: 36, alignment: .trailing)
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 14)
                        
                        if index < allocationBySource.count - 1 {
                            Divider().padding(.horizontal, 14)
                        }
                    }
                    
                    // Total row
                    Divider()
                    HStack {
                        Text("Total")
                            .font(.subheadline)
                            .fontWeight(.bold)
                        Spacer()
                        Text("S$\(NSDecimalNumber(decimal: grandTotal).doubleValue, specifier: "%.2f")")
                            .font(.subheadline)
                            .fontWeight(.bold)
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 14)
                }
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
    }
}
