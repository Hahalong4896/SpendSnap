// Domain/Models/ExpenseGroup.swift
// SpendSnap

import Foundation
import SwiftData

/// High-level expense grouping (e.g., Daily Expense, Housing, Transport).
/// Maps to the major sections in a monthly financial spreadsheet.
///
/// groupType determines behaviour:
/// - "daily": Contains sub-categories, expenses captured ad-hoc (existing flow)
/// - "recurring": Contains RecurringTemplates, auto-populated monthly
///
@Model
final class ExpenseGroup {
    
    // MARK: - Properties
    
    var id: UUID
    var name: String                // Group name (e.g., "Housing", "Transport")
    var icon: String                // SF Symbol name
    var colorHex: String            // Theme colour
    var sortOrder: Int              // Display order
    var groupType: String           // "daily" or "recurring"
    var isDefault: Bool             // System-provided vs user-created
    var isVisible: Bool             // Allow hiding unused groups
    
    // MARK: - Optional default payment source for the group
    // Stored as UUID string to avoid circular relationship issues
    var defaultPaymentSourceID: String?
    
    // MARK: - Init
    
    init(
        id: UUID = UUID(),
        name: String,
        icon: String,
        colorHex: String,
        sortOrder: Int,
        groupType: String = "recurring",
        isDefault: Bool = true,
        isVisible: Bool = true,
        defaultPaymentSourceID: String? = nil
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.sortOrder = sortOrder
        self.groupType = groupType
        self.isDefault = isDefault
        self.isVisible = isVisible
        self.defaultPaymentSourceID = defaultPaymentSourceID
    }
}

// MARK: - GroupType Enum (type-safe accessor)

enum ExpenseGroupType: String, Codable, CaseIterable {
    case daily      // Ad-hoc expenses using existing Category system
    case recurring  // Fixed monthly expenses using RecurringTemplate system
}

extension ExpenseGroup {
    /// Type-safe accessor for groupType
    var type: ExpenseGroupType {
        get { ExpenseGroupType(rawValue: groupType) ?? .recurring }
        set { groupType = newValue.rawValue }
    }
}
