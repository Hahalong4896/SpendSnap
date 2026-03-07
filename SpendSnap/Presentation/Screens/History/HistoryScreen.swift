// Presentation/Screens/History/HistoryScreen.swift
// SpendSnap

import SwiftUI
import SwiftData

/// Chronological list of all expenses with search and filter capabilities.
struct HistoryScreen: View {
    
    // MARK: - Environment
    
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Expense.date, order: .reverse) private var allExpenses: [Expense]
    @Query(sort: \Category.sortOrder) private var categories: [Category]
    @State private var showExpenseEntry = false
    
    // MARK: - State
    
    @State private var searchText = ""
    @State private var selectedCategoryFilter: Category?
    @State private var showFilterSheet = false
    
    // MARK: - Filtered Data
    
    private var filteredExpenses: [Expense] {
        var result = allExpenses
        
        // Search filter
        if !searchText.isEmpty {
            result = result.filter { expense in
                let categoryMatch = expense.category?.name.localizedCaseInsensitiveContains(searchText) ?? false
                let vendorMatch = expense.vendor?.localizedCaseInsensitiveContains(searchText) ?? false
                let noteMatch = expense.note?.localizedCaseInsensitiveContains(searchText) ?? false
                return categoryMatch || vendorMatch || noteMatch
            }
        }
        
        // Category filter
        if let filter = selectedCategoryFilter {
            result = result.filter { $0.category?.id == filter.id }
        }
        
        return result
    }
    
    /// Group expenses by date for section headers
    private var groupedExpenses: [(date: String, expenses: [Expense])] {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        
        let grouped = Dictionary(grouping: filteredExpenses) { expense in
            formatter.string(from: expense.date)
        }
        
        return grouped
            .map { (date: $0.key, expenses: $0.value) }
            .sorted { ($0.expenses.first?.date ?? Date()) > ($1.expenses.first?.date ?? Date()) }
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            Group {
                if allExpenses.isEmpty {
                    emptyState
                } else {
                    List {
                        // Active filter indicator
                        if selectedCategoryFilter != nil {
                            filterBanner
                        }
                        
                        ForEach(groupedExpenses, id: \.date) { group in
                            Section(header: Text(group.date)) {
                                ForEach(group.expenses, id: \.id) { expense in
                                    NavigationLink(destination: ExpenseDetailScreen(expense: expense)) {
                                        ExpenseRow(expense: expense)
                                    }
                                }
                                .onDelete { indexSet in
                                    deleteExpenses(in: group.expenses, at: indexSet)
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("History")
            .searchable(text: $searchText, prompt: "Search by category, vendor, notes...")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { showExpenseEntry = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showFilterSheet = true }) {
                        Image(systemName: selectedCategoryFilter != nil
                              ? "line.3.horizontal.decrease.circle.fill"
                              : "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .fullScreenCover(isPresented: $showExpenseEntry) {
                ExpenseEntryScreen()
            }
            .sheet(isPresented: $showFilterSheet) {
                filterSheet
            }
        }
    }
    
    // MARK: - Filter Banner
    
    private var filterBanner: some View {
        HStack {
            if let filter = selectedCategoryFilter {
                Image(systemName: filter.icon)
                    .foregroundStyle(Color(hex: filter.colorHex))
                Text("Filtered: \(filter.name)")
                    .font(.subheadline)
            }
            Spacer()
            Button("Clear") {
                selectedCategoryFilter = nil
            }
            .font(.caption)
            .fontWeight(.semibold)
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Filter Sheet
    
    private var filterSheet: some View {
        NavigationStack {
            List {
                Button(action: {
                    selectedCategoryFilter = nil
                    showFilterSheet = false
                }) {
                    HStack {
                        Text("All Categories")
                        Spacer()
                        if selectedCategoryFilter == nil {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.blue)
                        }
                    }
                }
                
                ForEach(categories, id: \.id) { category in
                    Button(action: {
                        selectedCategoryFilter = category
                        showFilterSheet = false
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: category.icon)
                                .foregroundStyle(Color(hex: category.colorHex))
                                .frame(width: 24)
                            Text(category.name)
                            Spacer()
                            if selectedCategoryFilter?.id == category.id {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                    .tint(.primary)
                }
            }
            .navigationTitle("Filter by Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { showFilterSheet = false }
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No expenses recorded")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Actions
    
    private func deleteExpenses(in expenses: [Expense], at offsets: IndexSet) {
        let repository = ExpenseRepository(modelContext: modelContext)
        for index in offsets {
            try? repository.deleteExpense(expenses[index])
        }
    }
}

