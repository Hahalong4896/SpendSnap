// Presentation/Navigation/TabBarView.swift 
// SpendSnap

import SwiftUI

/// Main tab bar navigation for the app.
/// Phase 2.5: Budget tab replaces Reports tab position.
/// Reports functionality is now inside the Budget screen.
struct TabBarView: View {
    
    // MARK: - State
    
    @State private var selectedTab: Tab = .dashboard
    @State private var showExpenseEntry = false
    
    // MARK: - Tab Enum
    
    enum Tab: Int {
        case dashboard
        case history
        case add        // Dummy tab — triggers sheet
        case budget     // NEW: Monthly budget workspace
        case settings
    }
    
    // MARK: - Body
    
    var body: some View {
        TabView(selection: $selectedTab) {
            
            DashboardScreen(showExpenseEntry: $showExpenseEntry)
                .tabItem {
                    Label("Dashboard", systemImage: "chart.pie.fill")
                }
                .tag(Tab.dashboard)
            
            HistoryScreen()
                .tabItem {
                    Label("History", systemImage: "clock.fill")
                }
                .tag(Tab.history)
            
            // Centre "+" tab — placeholder that triggers the sheet
            Color.clear
                .tabItem {
                    Label("Add", systemImage: "plus.circle.fill")
                }
                .tag(Tab.add)
            
            MonthlyBudgetScreen()
                .tabItem {
                    Label("Budget", systemImage: "wallet.bifold.fill")
                }
                .tag(Tab.budget)
            
            SettingsScreen()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(Tab.settings)
        }
        .onChange(of: selectedTab) { oldTab, newTab in
            if newTab == .add {
                showExpenseEntry = true
                // Bounce back to previous tab
                selectedTab = oldTab
            }
        }
        .fullScreenCover(isPresented: $showExpenseEntry) {
            ExpenseEntryScreen()
        }
    }
}
