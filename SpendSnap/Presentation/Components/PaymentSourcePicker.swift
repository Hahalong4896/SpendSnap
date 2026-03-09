// Presentation/Components/PaymentSourcePicker.swift
// SpendSnap

import SwiftUI

/// Horizontal scrollable chip picker for selecting a payment source.
/// Used across ExpenseEntryScreen, EditExpenseScreen, and budget forms.
///
/// Usage:
/// PaymentSourcePicker(sources: paymentSources, selected: $selectedSource)
///
struct PaymentSourcePicker: View {
    
    let sources: [PaymentSource]
    @Binding var selected: PaymentSource?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                // "None" option
                chipButton(
                    label: "None",
                    icon: "xmark.circle",
                    colorHex: "#b2bec3",
                    isSelected: selected == nil
                ) {
                    selected = nil
                }
                
                ForEach(sources, id: \.id) { source in
                    chipButton(
                        label: source.name,
                        icon: source.icon,
                        colorHex: source.colorHex,
                        isSelected: selected?.id == source.id
                    ) {
                        selected = source
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }
    
    // MARK: - Chip Button
    
    private func chipButton(
        label: String,
        icon: String,
        colorHex: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.15)) { action() }
        }) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(label)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                isSelected
                ? Color(hex: colorHex).opacity(0.15)
                : Color(.systemGray6)
            )
            .foregroundStyle(isSelected ? Color(hex: colorHex) : .primary)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color(hex: colorHex) : .clear, lineWidth: 1.5)
            )
        }
    }
}
