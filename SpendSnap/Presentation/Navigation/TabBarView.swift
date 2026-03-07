// Presentation/Navigation/TabBarView.swift
// SpendSnap

import SwiftUI

/// Main tab bar navigation for the app.
/// Centre tab opens expense entry as a full-screen sheet.
struct TabBarView: View {
    
    // MARK: - State
    
    @State private var selectedTab: Tab = .dashboard
    @State private var showExpenseEntry = false
    
    // MARK: - Tab Enum
    
    enum Tab: Int {
        case dashboard
        case history
        case add       // Dummy tab — triggers sheet
        case reports
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
            
            MonthlyReportScreen()
                .tabItem {
                    Label("Reports", systemImage: "doc.text.fill")
                }
                .tag(Tab.reports)
            
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
