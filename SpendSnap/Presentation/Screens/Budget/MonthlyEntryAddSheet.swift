// Presentation/Screens/Budget/MonthlyEntryAddSheet.swift
// SpendSnap

import SwiftUI
import SwiftData

/// Quick-add form for adding a fixed monthly expense entry to a group.
struct MonthlyEntryAddSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let group: ExpenseGroup
    let month: Int
    let year: Int
    
    @Query(filter: #Predicate<PaymentSource> { $0.isActive }, sort: \PaymentSource.sortOrder) private var sources: [PaymentSource]
    
    @State private var name = ""
    @State private var amountString = ""
    @State private var selectedCurrency = "SGD"
    @State private var selectedSource: PaymentSource?
    @State private var note = ""
    
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
            .navigationTitle("Add to \(group.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let entry = MonthlyExpenseEntry(
                            name: name,
                            amount: Decimal(string: amountString) ?? 0,
                            currency: selectedCurrency,
                            month: month,
                            year: year,
                            expenseGroup: group,
                            paymentSource: selectedSource,
                            note: note.isEmpty ? nil : note,
                            entryType: "fixed"
                        )
                        modelContext.insert(entry)
                        try? modelContext.save()
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || amountString.isEmpty)
                }
            }
            .onAppear {
                if let sid = group.defaultPaymentSourceID {
                    selectedSource = sources.first { $0.id.uuidString == sid }
                }
            }
        }
    }
}
