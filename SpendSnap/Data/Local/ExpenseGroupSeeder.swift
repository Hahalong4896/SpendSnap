// Data/Local/ExpenseGroupSeeder.swift
// SpendSnap

import Foundation
import SwiftData

/// Seeds the database with default expense groups on first launch.
/// Groups are editable — users can rename, reorder, hide, or add new ones.
///
struct ExpenseGroupSeeder {
    
    // MARK: - Default Group Definitions
    
    /// Each tuple: (name, icon, colorHex, sortOrder, groupType)
    static let defaults: [(name: String, icon: String, colorHex: String, sortOrder: Int, groupType: String)] = [
        ("Daily Expense",   "cart.fill",                        "#FF6B6B",  0, "daily"),
        ("Housing",         "house.fill",                       "#0984e3",  1, "recurring"),
        ("Transport",       "car.fill",                         "#00b894",  2, "recurring"),
        ("Insurance",       "shield.fill",                      "#6c5ce7",  3, "recurring"),
        ("Family",          "person.2.fill",                    "#e17055",  4, "recurring"),
        ("Investment",      "chart.line.uptrend.xyaxis",        "#fdcb6e",  5, "recurring"),
        ("Special",         "star.fill",                        "#b2bec3",  6, "recurring"),
    ]
    
    // MARK: - Seed Method
    
    /// Seeds default expense groups on first launch.
    /// Checks if groups already exist to avoid duplicates.
    static func seedIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<ExpenseGroup>()
        let existingCount = (try? context.fetchCount(descriptor)) ?? 0
        
        guard existingCount == 0 else { return }
        
        for item in defaults {
            let group = ExpenseGroup(
                name: item.name,
                icon: item.icon,
                colorHex: item.colorHex,
                sortOrder: item.sortOrder,
                groupType: item.groupType,
                isDefault: true,
                isVisible: true
            )
            context.insert(group)
        }
        
        try? context.save()
    }
}
