// App/SpendSnapApp.swift
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
                Expense.self,
                Category.self,
                MonthlyReport.self,
            ])
            let config = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false  // Persist to disk
            )
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [config]
            )
            
            // Seed default categories on first launch
            let context = ModelContext(modelContainer)
            CategorySeeder.seedIfNeeded(context: context)
            
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
        
        // Request notification permission
        NotificationService.requestPermission()

        // Schedule monthly report reminder
        NotificationService.scheduleMonthlyReportReminder()
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
