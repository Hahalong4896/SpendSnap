// Presentation/Screens/Dashboard/ContentView.swift
// SpendSnap

import SwiftUI

/// Root view — loads the main tab bar navigation.
struct ContentView: View {
    var body: some View {
        TabBarView()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Category.self, Expense.self, MonthlyReport.self], inMemory: true)
}
