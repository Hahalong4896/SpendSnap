// Presentation/Screens/Budget/MonthlyEntryEditSheet.swift
// SpendSnap
//
// IMPORTANT: This replaces the MonthlyEntryEditSheet struct that was at the
// bottom of MonthlyBudgetScreen.swift. You can either:
// (a) Replace the struct inside MonthlyBudgetScreen.swift, OR
// (b) Move it to its own file and delete it from MonthlyBudgetScreen.swift
//
// Fix: Decimal formatting (no more 32.0199999...) + date picker added

import SwiftUI
import SwiftData

struct MonthlyEntryEditSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let entry: MonthlyExpenseEntry
    
    @Query(filter: #Predicate<PaymentSource> { $0.isActive }, sort: \PaymentSource.sortOrder) private var sources: [PaymentSource]
    
    @State private var name = ""
    @State private var amountString = ""
    @State private var selectedCurrency = "SGD"
    @State private var selectedSource: PaymentSource?
    @State private var note = ""
    @State private var entryDate: Date = Date()
    
    // Petrol-specific
    @State private var odometerString = ""
    @State private var litersString = ""
    
    // Grocery-specific
    @State private var itemNotes = ""
    @State private var vendor = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Name", text: $name)
                    
                    HStack {
                        Text("Amount")
                        Spacer()
                        TextField("0.00", text: $amountString)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 140)
                    }
                    
                    Picker("Currency", selection: $selectedCurrency) {
                        ForEach(Currency.allCases, id: \.self) { c in
                            Text("\(c.flag) \(c.rawValue)").tag(c.rawValue)
                        }
                    }
                    
                    DatePicker("Date", selection: $entryDate, displayedComponents: .date)
                }
                
                // Petrol fields
                if entry.entryType == "petrol" {
                    Section("Petrol Details") {
                        HStack {
                            Text("Odometer (km)")
                            Spacer()
                            TextField("0", text: $odometerString)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 120)
                        }
                        HStack {
                            Text("Liters")
                            Spacer()
                            TextField("0.00", text: $litersString)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 120)
                        }
                        if let ppl = computedPricePerLiter {
                            HStack {
                                Text("Price/Liter")
                                Spacer()
                                Text(String(format: "%.3f", NSDecimalNumber(decimal: ppl).doubleValue))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                
                // Grocery fields
                if entry.entryType == "grocery" {
                    Section("Grocery Details") {
                        TextField("Shop Name", text: $vendor)
                        VStack(alignment: .leading) {
                            Text("Items").font(.caption).foregroundStyle(.secondary)
                            TextEditor(text: $itemNotes)
                                .frame(minHeight: 60)
                        }
                    }
                }
                
                Section("Payment Source") {
                    Picker("Paid Via", selection: $selectedSource) {
                        Text("None").tag(nil as PaymentSource?)
                        ForEach(sources, id: \.id) { s in
                            HStack { Image(systemName: s.icon); Text(s.name) }.tag(s as PaymentSource?)
                        }
                    }
                }
                
                Section("Note") {
                    TextField("Note", text: $note)
                }
            }
            .navigationTitle("Edit Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveChanges() }
                }
            }
            .onAppear { loadEntry() }
        }
    }
    
    private var computedPricePerLiter: Decimal? {
        guard let amount = Decimal(string: amountString),
              let liters = Double(litersString), liters > 0 else { return nil }
        return amount / Decimal(liters)
    }
    
    private func loadEntry() {
        name = entry.name
        // FIX: Use String(format:) to avoid floating point display issues
        amountString = formatDecimal(entry.amount)
        selectedCurrency = entry.currency
        selectedSource = entry.paymentSource
        note = entry.note ?? ""
        entryDate = entry.paidDate ?? entry.createdAt
        
        // Petrol
        if let odo = entry.odometerReading { odometerString = String(format: "%.0f", odo) }
        if let lit = entry.litersFilled { litersString = String(format: "%.2f", lit) }
        
        // Grocery
        vendor = entry.vendor ?? ""
        itemNotes = entry.itemNotes ?? ""
    }
    
    private func saveChanges() {
        entry.name = name
        entry.amount = Decimal(string: amountString) ?? 0
        entry.currency = selectedCurrency
        entry.paymentSource = selectedSource
        entry.note = note.isEmpty ? nil : note
        entry.paidDate = entryDate
        entry.createdAt = entryDate
        
        // Petrol
        if entry.entryType == "petrol" {
            entry.odometerReading = Double(odometerString)
            entry.litersFilled = Double(litersString)
            entry.pricePerLiter = computedPricePerLiter
        }
        
        // Grocery
        if entry.entryType == "grocery" {
            entry.vendor = vendor.isEmpty ? nil : vendor
            entry.itemNotes = itemNotes.isEmpty ? nil : itemNotes
        }
        
        try? modelContext.save()
        dismiss()
    }
    
    /// Formats Decimal to clean string without floating point artifacts
    private func formatDecimal(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        formatter.groupingSeparator = ""
        return formatter.string(from: NSDecimalNumber(decimal: value)) ?? "0"
    }
}
