// Presentation/Screens/Budget/IncomeEntryScreen.swift
// SpendSnap

import SwiftUI
import SwiftData

/// Form sheet for adding or editing an income entry for a specific month.
struct IncomeEntryScreen: View {
    
    // MARK: - Environment
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Properties
    
    let month: Int
    let year: Int
    let existingEntry: IncomeEntry?     // nil = adding new, non-nil = editing
    
    @Query(
        filter: #Predicate<PaymentSource> { $0.isActive },
        sort: \PaymentSource.sortOrder
    ) private var sources: [PaymentSource]
    
    // MARK: - State
    
    @State private var name = ""
    @State private var amountString = ""
    @State private var selectedCurrency = "SGD"
    @State private var selectedSource: PaymentSource?
    @State private var note = ""
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Income Details") {
                    TextField("Name (e.g., Salary, Part Time)", text: $name)
                    
                    HStack {
                        Text("Amount")
                        Spacer()
                        TextField("0.00", text: $amountString)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 140)
                    }
                    
                    Picker("Currency", selection: $selectedCurrency) {
                        ForEach(Currency.allCases, id: \.self) { currency in
                            Text("\(currency.flag) \(currency.rawValue)").tag(currency.rawValue)
                        }
                    }
                }
                
                Section("Received Into") {
                    if sources.isEmpty {
                        Text("No payment sources — add them in Settings")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Picker("Account", selection: $selectedSource) {
                            Text("None").tag(nil as PaymentSource?)
                            ForEach(sources, id: \.id) { source in
                                HStack {
                                    Image(systemName: source.icon)
                                    Text(source.name)
                                }
                                .tag(source as PaymentSource?)
                            }
                        }
                    }
                }
                
                Section("Note (Optional)") {
                    TextField("Optional note", text: $note)
                }
            }
            .navigationTitle(existingEntry == nil ? "Add Income" : "Edit Income")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || amountString.isEmpty)
                }
            }
            .onAppear {
                if let entry = existingEntry {
                    name = entry.name
                    amountString = "\(NSDecimalNumber(decimal: entry.amount).doubleValue)"
                    selectedCurrency = entry.currency
                    selectedSource = entry.paymentSource
                    note = entry.note ?? ""
                }
            }
        }
    }
    
    // MARK: - Save
    
    private func save() {
        let amount = Decimal(string: amountString) ?? 0
        
        if let entry = existingEntry {
            // Update existing
            entry.name = name
            entry.amount = amount
            entry.currency = selectedCurrency
            entry.paymentSource = selectedSource
            entry.note = note.isEmpty ? nil : note
        } else {
            // Create new
            let entry = IncomeEntry(
                name: name,
                amount: amount,
                currency: selectedCurrency,
                month: month,
                year: year,
                paymentSource: selectedSource,
                note: note.isEmpty ? nil : note
            )
            modelContext.insert(entry)
        }
        
        try? modelContext.save()
    }
}
