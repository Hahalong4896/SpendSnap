// Data/Local/CategorySeeder.swift
// SpendSnap

import Foundation
import SwiftData

/// Seeds the database with default spending categories on first launch.
/// Categories are defined as data (not hardcoded in UI) for easy modification.
struct CategorySeeder {
    
    // MARK: - Default Category Definitions
    
    /// Each tuple: (name, SF Symbol icon, chart colour hex, sort order)
    static let defaults: [(name: String, icon: String, colorHex: String, sortOrder: Int)] = [
        ("Breakfast",       "sun.horizon.fill",     "#FF9F43", 0),
        ("Lunch",           "fork.knife",           "#FF6B6B", 1),
        ("Dinner",          "moon.stars.fill",       "#EE5A24", 2),
        ("Snacks & Drinks", "cup.and.saucer.fill",  "#FECA57", 3),
        ("Groceries",       "cart.fill",            "#48DBFB", 4),
        ("Transport",       "bus.fill",             "#0ABDE3", 5),
        ("Shopping",        "bag.fill",             "#FF78C4", 6),
        ("Entertainment",   "film.fill",            "#A29BFE", 7),
        ("Health",          "heart.fill",           "#55EFC4", 8),
        ("Bills",           "bolt.fill",            "#FDCB6E", 9),
        ("Education",       "book.fill",            "#74B9FF", 10),
        ("Personal Care",   "scissors",             "#DFE6E9", 11),
        ("Gifts",           "gift.fill",            "#E17055", 12),
        ("Travel",          "airplane",             "#00CEC9", 13),
        ("Others",          "ellipsis.circle.fill", "#B2BEC3", 14),
    ]
    
    // MARK: - Seed Method
    
    /// Call this on first launch to populate default categories.
    /// Checks if categories already exist to avoid duplicates.
    static func seedIfNeeded(context: ModelContext) {
        // Check if categories already exist
        let descriptor = FetchDescriptor<Category>()
        let existingCount = (try? context.fetchCount(descriptor)) ?? 0
        
        guard existingCount == 0 else { return }
        
        // Insert all default categories
        for item in defaults {
            let category = Category(
                name: item.name,
                icon: item.icon,
                colorHex: item.colorHex,
                isDefault: true,
                sortOrder: item.sortOrder,
                isVisible: true
            )
            context.insert(category)
        }
        
        // Save
        try? context.save()
    }
}
