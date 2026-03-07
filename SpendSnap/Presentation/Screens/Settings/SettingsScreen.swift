// Presentation/Screens/Settings/SettingsScreen.swift
// SpendSnap

import SwiftUI
import SwiftData

/// App settings screen.
/// Phase 2: Basic info and data management.
/// Phase 3+: Account, sync, budget settings.
struct SettingsScreen: View {
    
    // MARK: - Environment
    
    @Environment(\.modelContext) private var modelContext
    @Query private var allExpenses: [Expense]
    
    // MARK: - State
    
    @State private var showDeleteAllAlert = false
    @State private var notificationsEnabled = true
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            List {
                // ── App Info ──
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Total Expenses")
                        Spacer()
                        Text("\(allExpenses.count)")
                            .foregroundStyle(.secondary)
                    }
                }
                
                // ── Notifications ──
                Section("Notifications") {
                    Toggle("Monthly Report Reminder", isOn: $notificationsEnabled)
                        .onChange(of: notificationsEnabled) { _, enabled in
                            if enabled {
                                NotificationService.scheduleMonthlyReportReminder()
                            } else {
                                NotificationService.cancelMonthlyReminder()
                            }
                        }
                    
                    Text("Receive a reminder on the 1st of each month")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                // ── Show exchange rates ──
                Section("Exchange Rates") {
                    let cs = CurrencyService.shared
                    
                    if let lastUpdated = cs.lastUpdated {
                        HStack {
                            Text("Last Updated")
                            Spacer()
                            Text(lastUpdated.formatted(date: .abbreviated, time: .shortened))
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    ForEach(Currency.allCases.filter { $0 != .sgd }, id: \.self) { currency in
                        HStack {
                            Text("\(currency.flag) \(currency.rawValue)")
                            Spacer()
                            if let rate = cs.rates[currency.rawValue] {
                                Text(String(format: "1 %@ = %.4f SGD", currency.rawValue, rate))
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                            } else {
                                Text("N/A")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    
                    Button(action: {
                        Task {
                            await CurrencyService.shared.fetchRates()
                        }
                    }) {
                        HStack {
                            Label("Refresh Rates", systemImage: "arrow.clockwise")
                            if CurrencyService.shared.isLoading {
                                Spacer()
                                ProgressView()
                            }
                        }
                    }
                }
                
                // ── Data Management ──
                Section("Data") {
                    Button(role: .destructive) {
                        showDeleteAllAlert = true
                    } label: {
                        Label("Delete All Expenses", systemImage: "trash")
                    }
                }
                
            }
            .navigationTitle("Settings")
            .alert("Delete All Expenses?", isPresented: $showDeleteAllAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete All", role: .destructive) {
                    deleteAllExpenses()
                }
            } message: {
                Text("This will permanently delete all expenses and photos. This cannot be undone.")
            }
        }
    }
    
    // MARK: - Actions
    
    private func deleteAllExpenses() {
        let repository = ExpenseRepository(modelContext: modelContext)
        do {
            let expenses = try repository.fetchExpenses()
            for expense in expenses {
                try repository.deleteExpense(expense)
            }
        } catch {
            print("Failed to delete all: \(error)")
        }
    }
}
