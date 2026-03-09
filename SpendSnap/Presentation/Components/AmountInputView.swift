// Presentation/Components/AmountInputView.swift
// SpendSnap

import SwiftUI

// NOTE: Currency enum has been moved to Domain/Models/Currency+Helpers.swift
// Do NOT define it here — it lives in Currency+Helpers.swift as the single source of truth.

/// Custom amount input field with currency selector.
struct AmountInputView: View {
    
    // MARK: - Properties
    
    @Binding var amount: String
    @Binding var selectedCurrency: Currency
    @FocusState private var isFieldFocused: Bool
    @State private var showCurrencyPicker = false
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 8) {
            // Currency selector button
            Button(action: { showCurrencyPicker = true }) {
                HStack(spacing: 6) {
                    Text(selectedCurrency.flag)
                        .font(.title3)
                    Text(selectedCurrency.rawValue)
                        .font(.caption)
                        .fontWeight(.semibold)
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                }
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(.systemGray5))
                .clipShape(Capsule())
            }
            
            // Amount display
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(selectedCurrency.symbol)
                    .font(.title2)
                    .foregroundStyle(.secondary)
                
                TextField("0.00", text: $amount)
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .focused($isFieldFocused)
                    .minimumScaleFactor(0.5)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 16)
       
        .sheet(isPresented: $showCurrencyPicker) {
            CurrencyPickerSheet(selectedCurrency: $selectedCurrency)
                .presentationDetents([.medium])
        }
    }
}

// MARK: - Currency Picker Sheet

private struct CurrencyPickerSheet: View {
    @Binding var selectedCurrency: Currency
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List(Currency.allCases) { currency in
                Button(action: {
                    selectedCurrency = currency
                    dismiss()
                }) {
                    HStack(spacing: 12) {
                        Text(currency.flag)
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(currency.rawValue)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text(currency.name)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Text(currency.symbol)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        if currency == selectedCurrency {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.blue)
                        }
                    }
                }
                .tint(.primary)
            }
            .navigationTitle("Select Currency")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var amount = ""
    @Previewable @State var currency = Currency.sgd
    AmountInputView(amount: $amount, selectedCurrency: $currency)
}
