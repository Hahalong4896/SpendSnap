// App/SpendSnapApp.swift — FULL REPLACEMENT
// SpendSnap

import SwiftUI
import SwiftData

@main
struct SpendSnapApp: App {
    
    // MARK: - SwiftData Container
    
    let modelContainer: ModelContainer
    
    init() {
        do {
            let schema = Schema([
                // Phase 1-2 models
                Expense.self,
                Category.self,
                MonthlyReport.self,
                // Phase 2.5 models
                PaymentSource.self,
                ExpenseGroup.self,
                RecurringTemplate.self,
                MonthlyBudget.self,
                IncomeEntry.self,
                MonthlyExpenseEntry.self,
            ])
            let config = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [config]
            )
            
            // Seed defaults on first launch
            let context = ModelContext(modelContainer)
            CategorySeeder.seedIfNeeded(context: context)
            ExpenseGroupSeeder.seedIfNeeded(context: context)
            
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
    
    // MARK: - Body
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    await CurrencyService.shared.fetchRates()
                }
        }
        .modelContainer(modelContainer)
    }
}
