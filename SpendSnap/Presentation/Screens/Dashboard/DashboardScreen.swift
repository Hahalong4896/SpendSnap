// Presentation/Screens/Dashboard/DashboardScreen.swift
// SpendSnap

import SwiftUI
import SwiftData

/// Main dashboard showing spending summary, charts, and recent expenses.
struct DashboardScreen: View {
    
    // MARK: - Environment
    
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Expense.date, order: .reverse) private var allExpenses: [Expense]
    @Binding var showExpenseEntry: Bool
    
    // MARK: - State
    
    @State private var selectedPeriod: TimePeriod = .month
    
    enum TimePeriod: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
    }
    
    // MARK: - Computed
    
    private var currentMonthExpenses: [Expense] {
        let calendar = Calendar.current
        let now = Date()
        return allExpenses.filter {
            calendar.isDate($0.date, equalTo: now, toGranularity: .month)
        }
    }
    
    private var todayTotal: Decimal {
        let calendar = Calendar.current
        return allExpenses
            .filter { calendar.isDateInToday($0.date) }
            .reduce(0) { $0 + $1.amount }
    }
    
    private var monthTotal: Decimal {
        let cs = CurrencyService.shared
        return currentMonthExpenses
            .reduce(0) { $0 + cs.convertToSGD(amount: $1.amount, from: $1.currency) }
    }
    
    private var transactionCount: Int {
        currentMonthExpenses.count
    }
    
    private var dailyAverage: Decimal {
        let calendar = Calendar.current
        let day = calendar.component(.day, from: Date())
        guard day > 0 else { return 0 }
        return monthTotal / Decimal(day)
    }
    
    /// Category breakdown for charts: [(categoryName, colorHex, total)]
    private var categoryBreakdown: [(name: String, colorHex: String, total: Decimal)] {
        var dict: [String: (colorHex: String, total: Decimal)] = [:]
        let cs = CurrencyService.shared
        
        for expense in currentMonthExpenses {
            let name = expense.category?.name ?? "Others"
            let color = expense.category?.colorHex ?? "#B2BEC3"
            let sgdAmount = cs.convertToSGD(amount: expense.amount, from: expense.currency)
            let existing = dict[name] ?? (colorHex: color, total: 0)
            dict[name] = (colorHex: color, total: existing.total + sgdAmount)
        }
        
        return dict.map { (name: $0.key, colorHex: $0.value.colorHex, total: $0.value.total) }
            .sorted { $0.total > $1.total }
    }
    
    /// Daily spending for bar chart: [(day, total)]
    private var dailySpending: [(day: Int, total: Decimal)] {
        let calendar = Calendar.current
        let cs = CurrencyService.shared
        var dict: [Int: Decimal] = [:]
        
        for expense in currentMonthExpenses {
            let day = calendar.component(.day, from: expense.date)
            dict[day, default: 0] += cs.convertToSGD(amount: expense.amount, from: expense.currency)
        }
        
        let currentDay = calendar.component(.day, from: Date())
        return (1...currentDay).map { day in
            (day: day, total: dict[day] ?? 0)
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    
                    // ── Summary Cards ──
                    summarySection
                    
                    // ── Category Donut Chart ──
                    if !categoryBreakdown.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Spending by Category")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            CategoryDonutChart(data: categoryBreakdown, total: monthTotal)
                                .frame(height: 240)
                                .padding(.horizontal)
                        }
                    }
                    
                    // ── Daily Bar Chart ──
                    if !dailySpending.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Daily Spending")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            DailyBarChart(data: dailySpending)
                                .frame(height: 180)
                                .padding(.horizontal)
                        }
                    }
                    
                    // ── Recent Expenses ──
                    recentExpensesSection
                }
                .padding(.top)
                .padding(.bottom, 20)
            }
            .navigationTitle("SpendSnap")
        }
    }
    
    // MARK: - Summary Section
    
    private var summarySection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                SummaryCard(title: "Today", amount: todayTotal,
                           icon: "calendar.circle.fill", color: .blue)
                SummaryCard(title: "This Month", amount: monthTotal,
                           icon: "chart.pie.fill", color: .purple)
            }
            HStack(spacing: 12) {
                SummaryCard(title: "Transactions", amount: Decimal(transactionCount),
                           icon: "number.circle.fill", color: .green, isCount: true)
                SummaryCard(title: "Daily Avg", amount: dailyAverage,
                           icon: "divide.circle.fill", color: .orange)
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Recent Expenses
    
    private var recentExpensesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Expenses")
                    .font(.headline)
                Spacer()
                // This could navigate to History tab
            }
            .padding(.horizontal)
            
            if allExpenses.isEmpty {
                emptyState
            } else {
                ForEach(allExpenses.prefix(5), id: \.id) { expense in
                    NavigationLink(destination: ExpenseDetailScreen(expense: expense)) {
                        ExpenseRow(expense: expense)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) {
                            deleteExpense(expense)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No expenses yet")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("Tap + to capture your first expense")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
    
    // MARK: - Actions
    
    private func deleteExpense(_ expense: Expense) {
        let repository = ExpenseRepository(modelContext: modelContext)
        try? repository.deleteExpense(expense)
    }
}

// MARK: - Summary Card

struct SummaryCard: View {
    let title: String
    let amount: Decimal
    let icon: String
    let color: Color
    var isCount: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            if isCount {
                Text("\(NSDecimalNumber(decimal: amount).intValue)")
                    .font(.title2)
                    .fontWeight(.bold)
            } else {
                Text("S$\(NSDecimalNumber(decimal: amount).doubleValue, specifier: "%.2f")")
                    .font(.title2)
                    .fontWeight(.bold)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Expense Row

struct ExpenseRow: View {
    let expense: Expense
    
    var body: some View {
        HStack(spacing: 12) {
            // Photo thumbnail
            if expense.photoFileName != "no_photo",
               let image = PhotoStorageService.loadPhoto(named: expense.photoFileName) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                // No photo — show category icon instead
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(hex: expense.category?.colorHex ?? "#B2BEC3").opacity(0.15))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: expense.category?.icon ?? "ellipsis.circle")
                            .font(.title3)
                            .foregroundStyle(Color(hex: expense.category?.colorHex ?? "#B2BEC3"))
                    )
            }
            
            // Details
            VStack(alignment: .leading, spacing: 4) {
                Text(expense.category?.name ?? "Uncategorised")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if let vendor = expense.vendor, !vendor.isEmpty {
                    Text(vendor)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text(expense.date, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            // Amount
            Text("\((Currency(rawValue: expense.currency) ?? .sgd).symbol)\(NSDecimalNumber(decimal: expense.amount).doubleValue, specifier: "%.2f")")
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .padding(.vertical, 4)
    }
}
