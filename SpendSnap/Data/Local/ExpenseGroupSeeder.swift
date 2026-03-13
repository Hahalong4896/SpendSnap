// Data/Local/ExpenseGroupSeeder.swift
// SpendSnap

import Foundation
import SwiftData

/// Seeds default expense groups on first launch.
/// Phase 2.5b: Added Groceries group, Transport has hasItemisedEntries = true.
struct ExpenseGroupSeeder {
    
    // MARK: - Default Group Definitions
    // (name, icon, colorHex, sortOrder, groupType, hasItemisedEntries)
    
    static let defaults: [(name: String, icon: String, colorHex: String, sortOrder: Int, groupType: String, hasItemised: Bool)] = [
        ("Daily Expense",   "cart.fill",                        "#FF6B6B",  0, "daily",     false),
        ("Housing",         "house.fill",                       "#0984e3",  1, "recurring", false),
        ("Transport",       "car.fill",                         "#00b894",  2, "recurring", true),   // Petrol tracking
        ("Groceries",       "basket.fill",                      "#48DBFB",  3, "recurring", true),   // Grocery tracking
        ("Insurance",       "shield.fill",                      "#6c5ce7",  4, "recurring", false),
        ("Family",          "person.2.fill",                    "#e17055",  5, "recurring", false),
        ("Investment",      "chart.line.uptrend.xyaxis",        "#fdcb6e",  6, "recurring", false),
        ("Special",         "star.fill",                        "#b2bec3",  7, "recurring", false),
    ]
    
    // MARK: - Seed Method
    
    static func seedIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<ExpenseGroup>()
        let existingCount = (try? context.fetchCount(descriptor)) ?? 0
        
        guard existingCount == 0 else {
            // If groups exist, just ensure Transport and Groceries have the flag
            updateExistingGroups(context: context)
            return
        }
        
        for item in defaults {
            let group = ExpenseGroup(
                name: item.name,
                icon: item.icon,
                colorHex: item.colorHex,
                sortOrder: item.sortOrder,
                groupType: item.groupType,
                isDefault: true,
                isVisible: true,
                hasItemisedEntries: item.hasItemised
            )
            context.insert(group)
        }
        
        try? context.save()
    }
    
    /// Update existing groups to add hasItemisedEntries flag and Groceries group
    /// Called on app update when groups already exist
    private static func updateExistingGroups(context: ModelContext) {
        let descriptor = FetchDescriptor<ExpenseGroup>(
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        guard let groups = try? context.fetch(descriptor) else { return }
        
        // Ensure Transport has hasItemisedEntries = true
        if let transport = groups.first(where: { $0.name == "Transport" }) {
            if !transport.hasItemisedEntries {
                transport.hasItemisedEntries = true
            }
        }
        
        // Add Groceries group if it doesn't exist
        let hasGroceries = groups.contains(where: { $0.name == "Groceries" })
        if !hasGroceries {
            let groceries = ExpenseGroup(
                name: "Groceries",
                icon: "basket.fill",
                colorHex: "#48DBFB",
                sortOrder: groups.count,
                groupType: "recurring",
                isDefault: true,
                isVisible: true,
                hasItemisedEntries: true
            )
            context.insert(groceries)
        }
        
        try? context.save()
    }
}
