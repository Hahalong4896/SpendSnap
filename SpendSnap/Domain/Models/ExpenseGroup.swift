// Domain/Models/ExpenseGroup.swift
// SpendSnap

import Foundation
import SwiftData

/// High-level expense grouping (e.g., Daily Expense, Housing, Transport).
///
/// groupType: "daily" or "recurring"
/// hasItemisedEntries: If true, group supports frequent itemised entries
/// (e.g., Transport/Petrol, Groceries) with receipt capture.
///
@Model
final class ExpenseGroup {
    
    // MARK: - Properties
    
    var id: UUID
    var name: String
    var icon: String
    var colorHex: String
    var sortOrder: Int
    var groupType: String
    var isDefault: Bool
    var isVisible: Bool
    var defaultPaymentSourceID: String?
    
    /// When true, group shows "Add Petrol" / "Add Grocery" style capture button
    /// and displays itemised entries separately from fixed entries.
    var hasItemisedEntries: Bool
    
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
        defaultPaymentSourceID: String? = nil,
        hasItemisedEntries: Bool = false
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
        self.hasItemisedEntries = hasItemisedEntries
    }
}

// MARK: - GroupType Enum

enum ExpenseGroupType: String, Codable, CaseIterable {
    case daily
    case recurring
}

extension ExpenseGroup {
    var type: ExpenseGroupType {
        get { ExpenseGroupType(rawValue: groupType) ?? .recurring }
        set { groupType = newValue.rawValue }
    }
}
