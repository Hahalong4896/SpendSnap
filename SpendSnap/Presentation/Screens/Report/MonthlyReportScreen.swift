// Presentation/Screens/Report/MonthlyReportScreen.swift
// SpendSnap

import SwiftUI
import SwiftData

/// Monthly spending report with summary, charts, and PDF export.
struct MonthlyReportScreen: View {
    
    // MARK: - Environment
    
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Expense.date, order: .reverse) private var allExpenses: [Expense]
    
    // MARK: - State
    
    @State private var selectedMonth: Date = Date()
    @State private var pdfURL: URL?
    
    // MARK: - Computed
    
    private var calendar: Calendar { Calendar.current }
    
    private var monthExpenses: [Expense] {
        allExpenses.filter {
            calendar.isDate($0.date, equalTo: selectedMonth, toGranularity: .month)
        }
    }
    
    private var totalSpend: Decimal {
        let cs = CurrencyService.shared
        return monthExpenses.reduce(0) { $0 + cs.convertToSGD(amount: $1.amount, from: $1.currency) }
    }
    
    private var transactionCount: Int {
        monthExpenses.count
    }
    
    private var dailyAverage: Decimal {
        let daysInMonth = calendar.range(of: .day, in: .month, for: selectedMonth)?.count ?? 30
        let currentDay = calendar.isDate(selectedMonth, equalTo: Date(), toGranularity: .month)
            ? calendar.component(.day, from: Date())
            : daysInMonth
        guard currentDay > 0 else { return 0 }
        return totalSpend / Decimal(currentDay)
    }
    
    private var categoryBreakdown: [(name: String, colorHex: String, total: Decimal)] {
        var dict: [String: (colorHex: String, total: Decimal)] = [:]
        let cs = CurrencyService.shared
        
        for expense in monthExpenses {
            let name = expense.category?.name ?? "Others"
            let color = expense.category?.colorHex ?? "#B2BEC3"
            let sgdAmount = cs.convertToSGD(amount: expense.amount, from: expense.currency)
            let existing = dict[name] ?? (colorHex: color, total: 0)
            dict[name] = (colorHex: color, total: existing.total + sgdAmount)
        }
        
        return dict.map { (name: $0.key, colorHex: $0.value.colorHex, total: $0.value.total) }
            .sorted { $0.total > $1.total }
    }
    
    private var topExpenses: [Expense] {
        monthExpenses.sorted { $0.amount > $1.amount }
    }
    
    private var previousMonthTotal: Decimal {
        guard let prevMonth = calendar.date(byAdding: .month, value: -1, to: selectedMonth) else { return 0 }
        let cs = CurrencyService.shared
        return allExpenses
            .filter { calendar.isDate($0.date, equalTo: prevMonth, toGranularity: .month) }
            .reduce(0) { $0 + cs.convertToSGD(amount: $1.amount, from: $1.currency) }
    }
    
    private var monthOverMonthChange: Decimal {
        guard previousMonthTotal > 0 else { return 0 }
        return ((totalSpend - previousMonthTotal) / previousMonthTotal) * 100
    }
    
    private var monthTitle: String {
        selectedMonth.formatted(.dateTime.month(.wide).year())
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    
                    // ── Month Selector ──
                    monthSelector
                    
                    if monthExpenses.isEmpty {
                        emptyReportState
                    } else {
                        // ── Summary Card ──
                        summaryCard
                        
                        // ── Category Breakdown ──
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Category Breakdown")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            CategoryDonutChart(data: categoryBreakdown, total: totalSpend)
                                .frame(height: 240)
                                .padding(.horizontal)
                            
                            categoryRankedList
                        }
                        
                        // ── Top Expenses ──
                        if !topExpenses.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("All Expenses")
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                ForEach(Array(topExpenses.enumerated()), id: \.element.id) { index, expense in
                                    HStack(spacing: 12) {
                                        Text("#\(index + 1)")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundStyle(.secondary)
                                            .frame(width: 24)
                                        
                                        ExpenseRow(expense: expense)
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                        
                        // ── Month-over-Month ──
                        if previousMonthTotal > 0 {
                            monthComparisonCard
                        }
                        
                        // ── Export Button ──
                        Button(action: generateAndSharePDF) {
                            Label("Export as PDF", systemImage: "square.and.arrow.up")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.blue)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 30)
                    }
                }
                .padding(.top)
            }
            .navigationTitle("Reports")
        }
    }
    
    // MARK: - Month Selector
    
    private var monthSelector: some View {
        HStack {
            Button(action: previousMonth) {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            
            Spacer()
            
            Text(monthTitle)
                .font(.title3)
                .fontWeight(.semibold)
            
            Spacer()
            
            Button(action: nextMonth) {
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            .disabled(calendar.isDate(selectedMonth, equalTo: Date(), toGranularity: .month))
        }
        .padding(.horizontal, 24)
    }
    
    // MARK: - Summary Card
    
    private var summaryCard: some View {
        VStack(spacing: 16) {
            Text("S$\(NSDecimalNumber(decimal: totalSpend).doubleValue, specifier: "%.2f")")
                .font(.system(size: 36, weight: .bold, design: .rounded))
            
            HStack(spacing: 24) {
                VStack(spacing: 4) {
                    Text("\(transactionCount)")
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text("Transactions")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                VStack(spacing: 4) {
                    Text("S$\(NSDecimalNumber(decimal: dailyAverage).doubleValue, specifier: "%.2f")")
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text("Daily Avg")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal)
    }
    
    // MARK: - Category Ranked List
    
    private var categoryRankedList: some View {
        VStack(spacing: 0) {
            ForEach(Array(categoryBreakdown.enumerated()), id: \.element.name) { index, item in
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color(hex: item.colorHex))
                        .frame(width: 12, height: 12)
                    
                    Text(item.name)
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Text("S$\(NSDecimalNumber(decimal: item.total).doubleValue, specifier: "%.2f")")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    let pct = totalSpend > 0
                        ? NSDecimalNumber(decimal: item.total / totalSpend * 100).doubleValue
                        : 0
                    Text("\(pct, specifier: "%.1f")%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 45, alignment: .trailing)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                if index < categoryBreakdown.count - 1 {
                    Divider().padding(.horizontal)
                }
            }
        }
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal)
    }
    
    // MARK: - Month Comparison
    
    private var monthComparisonCard: some View {
        VStack(spacing: 8) {
            Text("vs. Previous Month")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            HStack(spacing: 4) {
                Image(systemName: monthOverMonthChange >= 0 ? "arrow.up.right" : "arrow.down.right")
                    .foregroundStyle(monthOverMonthChange >= 0 ? .red : .green)
                
                Text("\(abs(NSDecimalNumber(decimal: monthOverMonthChange).doubleValue), specifier: "%.1f")%")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(monthOverMonthChange >= 0 ? .red : .green)
                
                Text(monthOverMonthChange >= 0 ? "more" : "less")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal)
    }
    
    // MARK: - Empty State
    
    private var emptyReportState: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No expenses for \(monthTitle)")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("Start logging expenses to see your report")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 80)
    }
    
    // MARK: - Actions
    
    private func previousMonth() {
        if let newDate = calendar.date(byAdding: .month, value: -1, to: selectedMonth) {
            selectedMonth = newDate
        }
    }
    
    private func nextMonth() {
        if let newDate = calendar.date(byAdding: .month, value: 1, to: selectedMonth) {
            if newDate <= Date() {
                selectedMonth = newDate
            }
        }
    }
    
    private func generateAndSharePDF() {
        let reportData = PDFReportGenerator.ReportData(
            monthTitle: monthTitle,
            totalSpend: totalSpend,
            transactionCount: transactionCount,
            dailyAverage: dailyAverage,
            categoryBreakdown: categoryBreakdown,
            topExpenses: topExpenses,
            previousMonthTotal: previousMonthTotal,
            monthOverMonthChange: monthOverMonthChange
        )
        
        guard let url = PDFReportGenerator.generateReport(data: reportData) else { return }
        
        // Use UIKit directly for reliable sharing
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else { return }
        
        // Find the topmost presented controller
        var topVC = rootVC
        while let presented = topVC.presentedViewController {
            topVC = presented
        }
        
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        
        // iPad support
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = topVC.view
            popover.sourceRect = CGRect(x: topVC.view.bounds.midX, y: topVC.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        topVC.present(activityVC, animated: true)
    }
}
