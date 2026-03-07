// Domain/Models/Category.swift
// SpendSnap

import Foundation
import SwiftData

@Model
final class Category {
    
    // MARK: - Properties
    
    var id: UUID
    var name: String
    var icon: String          // SF Symbol name (e.g., "fork.knife")
    var colorHex: String      // Chart colour (e.g., "#FF6B6B")
    var isDefault: Bool       // true = system-provided, false = user-created
    var sortOrder: Int        // Display order in category grid
    var isVisible: Bool       // Allow user to hide unused categories
    
    // MARK: - Relationships
    
    @Relationship(deleteRule: .nullify)
    var expenses: [Expense]?
    
    // MARK: - Init
    
    init(
        id: UUID = UUID(),
        name: String,
        icon: String,
        colorHex: String,
        isDefault: Bool = true,
        sortOrder: Int,
        isVisible: Bool = true
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.isDefault = isDefault
        self.sortOrder = sortOrder
        self.isVisible = isVisible
    }
}
