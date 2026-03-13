// Presentation/Screens/Budget/MaintenanceEntrySheet.swift
// SpendSnap

import SwiftUI
import SwiftData

/// Vehicle maintenance entry based on mileage.
/// User enters total distance traveled and cost per km rate.
/// Amount is auto-calculated: distance × rate.
struct MaintenanceEntrySheet: View {
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let group: ExpenseGroup
    let month: Int
    let year: Int
    
    @Query(filter: #Predicate<PaymentSource> { $0.isActive }, sort: \PaymentSource.sortOrder) private var sources: [PaymentSource]
    
    @State private var distanceString = ""
    @State private var costPerKmString = "0.20"   // Default rate
    @State private var selectedCurrency: Currency = .sgd
    @State private var selectedSource: PaymentSource?
    @State private var note = ""
    @State private var entryDate: Date = Date()
    
    /// Auto-calculated maintenance cost
    private var calculatedAmount: Decimal? {
        guard let distance = Decimal(string: distanceString),
              let rate = Decimal(string: costPerKmString),
              distance > 0, rate > 0 else { return nil }
        return distance * rate
    }
    
    private var canSave: Bool {
        calculatedAmount != nil && calculatedAmount! > 0
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text("Total Distance (km)")
                        Spacer()
                        TextField("e.g., 2000", text: $distanceString)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                    }
                    
                    HStack {
                        Text("Cost per km")
                        Spacer()
                        TextField("0.20", text: $costPerKmString)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                    }
                    
                    Picker("Currency", selection: $selectedCurrency) {
                        ForEach(Currency.allCases, id: \.self) { c in
                            Text("\(c.flag) \(c.rawValue)").tag(c)
                        }
                    }
                } header: {
                    Text("Maintenance Calculation")
                }
                
                // Calculated amount display
                if let amount = calculatedAmount {
                    Section("Calculated Cost") {
                        HStack {
                            if let dist = Decimal(string: distanceString),
                               let rate = Decimal(string: costPerKmString) {
                                Text("\(formatDecimal(dist)) km × \(selectedCurrency.symbol)\(formatDecimal(rate))/km")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("\(selectedCurrency.symbol)\(formatDecimal(amount))")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(Color.primary)
                        }
                    }
                }
                
                Section("Date") {
                    DatePicker("Date", selection: $entryDate, displayedComponents: .date)
                }
                
                Section("Payment Source") {
                    if sources.isEmpty {
                        Text("No payment sources").font(.caption).foregroundStyle(.secondary)
                    } else {
                        Picker("Paid Via", selection: $selectedSource) {
                            Text("None").tag(nil as PaymentSource?)
                            ForEach(sources, id: \.id) { s in
                                HStack { Image(systemName: s.icon); Text(s.name) }.tag(s as PaymentSource?)
                            }
                        }
                    }
                }
                
                Section("Note (Optional)") {
                    TextField("Optional note", text: $note)
                }
            }
            .navigationTitle("Add Maintenance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!canSave)
                }
            }
            .onAppear {
                if let sid = group.defaultPaymentSourceID {
                    selectedSource = sources.first { $0.id.uuidString == sid }
                }
            }
        }
    }
    
    private func save() {
        guard let amount = calculatedAmount else { return }
        
        let distanceNote = "Distance: \(distanceString)km, Rate: \(costPerKmString)/km"
        let fullNote = note.isEmpty ? distanceNote : "\(distanceNote) | \(note)"
        
        let entry = MonthlyExpenseEntry(
            name: "Maintenance",
            amount: amount,
            currency: selectedCurrency.rawValue,
            month: month,
            year: year,
            isPaid: false,
            paidDate: entryDate,
            expenseGroup: group,
            paymentSource: selectedSource,
            note: fullNote,
            entryType: "fixed",
            createdAt: entryDate
        )
        modelContext.insert(entry)
        try? modelContext.save()
        dismiss()
    }
    
    private func formatDecimal(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        formatter.groupingSeparator = ""
        return formatter.string(from: NSDecimalNumber(decimal: value)) ?? "0"
    }
}
