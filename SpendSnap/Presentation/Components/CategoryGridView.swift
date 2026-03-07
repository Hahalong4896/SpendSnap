// Presentation/Components/CategoryGridView.swift
// SpendSnap

import SwiftUI
import SwiftData

/// A 3-column tappable grid displaying spending categories.
/// Supports single selection with visual feedback.
///
/// Usage:
///   CategoryGridView(selectedCategory: $selectedCategory)
///
struct CategoryGridView: View {
    
    // MARK: - Properties
    
    @Binding var selectedCategory: Category?
    @Query(filter: #Predicate<Category> { $0.isVisible },
           sort: \Category.sortOrder)
    private var categories: [Category]
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)
    
    // MARK: - Body
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(categories, id: \.id) { category in
                CategoryCell(
                    category: category,
                    isSelected: selectedCategory?.id == category.id
                )
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        selectedCategory = category
                    }
                }
            }
        }
    }
}

// MARK: - Category Cell

/// Individual category cell with icon, label, and selection state.
private struct CategoryCell: View {
    
    let category: Category
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: category.icon)
                .font(.title2)
                .foregroundStyle(Color(hex: category.colorHex))
            
            Text(category.name)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundStyle(isSelected ? Color(hex: category.colorHex) : .primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected
                      ? Color(hex: category.colorHex).opacity(0.15)
                      : Color(.systemGray6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color(hex: category.colorHex) : .clear, lineWidth: 2)
        )
    }
}
