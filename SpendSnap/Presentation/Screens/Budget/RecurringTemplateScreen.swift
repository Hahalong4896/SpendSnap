// Presentation/Screens/Budget/RecurringTemplateScreen.swift
// SpendSnap

import SwiftUI
import SwiftData

/// Screen for managing recurring expense templates.
/// Templates are grouped by ExpenseGroup and define fixed monthly costs.
struct RecurringTemplateScreen: View {
    
    // MARK: - Environment
    
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RecurringTemplate.sortOrder) private var templates: [RecurringTemplate]
    @Query(
        filter: #Predicate<ExpenseGroup> { $0.groupType == "recurring" && $0.isVisible },
        sort: \ExpenseGroup.sortOrder
    ) private var groups: [ExpenseGroup]
    @Query(
        filter: #Predicate<PaymentSource> { $0.isActive },
        sort: \PaymentSource.sortOrder
    ) private var sources: [PaymentSource]
    
    // MARK: - State
    
    @State private var showAddSheet = false
    @State private var editingTemplate: RecurringTemplate?
    
    // MARK: - Body
    
    var body: some View {
        List {
            if templates.isEmpty {
                emptyState
            } else {
                ForEach(groups, id: \.id) { group in
                    let groupTemplates = templates.filter { $0.expenseGroup?.id == group.id }
                    if !groupTemplates.isEmpty {
                        Section {
                            ForEach(groupTemplates, id: \.id) { template in
                                templateRow(template)
                                    .onTapGesture { editingTemplate = template }
                            }
                            .onDelete { offsets in
                                deleteTemplates(groupTemplates, at: offsets)
                            }
                        } header: {
                            HStack(spacing: 6) {
                                Image(systemName: group.icon)
                                    .foregroundStyle(Color(hex: group.colorHex))
                                Text(group.name)
                            }
                        }
                    }
                }
                
                // Templates without a group
                let ungrouped = templates.filter { $0.expenseGroup == nil }
                if !ungrouped.isEmpty {
                    Section("Ungrouped") {
                        ForEach(ungrouped, id: \.id) { template in
                            templateRow(template)
                                .onTapGesture { editingTemplate = template }
                        }
                    }
                }
            }
        }
        .navigationTitle("Recurring Templates")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { showAddSheet = true }) {
                    Image(systemName: "plus.circle.fill")
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            RecurringTemplateFormSheet(template: nil, groups: groups, sources: sources) { data in
                addTemplate(data)
            }
        }
        .sheet(item: $editingTemplate) { template in
            RecurringTemplateFormSheet(template: template, groups: groups, sources: sources) { data in
                updateTemplate(template, with: data)
            }
        }
    }
    
    // MARK: - Template Row
    
    private func templateRow(_ template: RecurringTemplate) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(template.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if let source = template.paymentSource {
                    HStack(spacing: 4) {
                        Image(systemName: source.icon)
                            .font(.caption2)
                        Text(source.name)
                            .font(.caption)
                    }
                    .foregroundStyle(Color(hex: source.colorHex))
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                let symbol = Currency.symbol(for: template.currency)
                Text("\(symbol)\(NSDecimalNumber(decimal: template.defaultAmount).doubleValue, specifier: "%.2f")")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(template.currency)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            // Active toggle
            Circle()
                .fill(template.isActive ? Color.green : Color.gray.opacity(0.3))
                .frame(width: 10, height: 10)
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text.below.ecg")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text("No recurring templates")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("Add your fixed monthly expenses like rent, insurance, and utilities")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
            
            Button(action: { showAddSheet = true }) {
                Label("Add Template", systemImage: "plus")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .listRowBackground(Color.clear)
    }
    
    // MARK: - Actions
    
    private func addTemplate(_ data: TemplateFormData) {
        let template = RecurringTemplate(
            name: data.name,
            defaultAmount: data.amount,
            currency: data.currency,
            expenseGroup: data.group,
            paymentSource: data.source,
            sortOrder: templates.count,
            note: data.note
        )
        modelContext.insert(template)
        try? modelContext.save()
    }
    
    private func updateTemplate(_ template: RecurringTemplate, with data: TemplateFormData) {
        template.name = data.name
        template.defaultAmount = data.amount
        template.currency = data.currency
        template.expenseGroup = data.group
        template.paymentSource = data.source
        template.note = data.note
        try? modelContext.save()
    }
    
    private func deleteTemplates(_ items: [RecurringTemplate], at offsets: IndexSet) {
        for index in offsets {
            items[index].isActive = false
        }
        try? modelContext.save()
    }
}

// MARK: - Form Data

struct TemplateFormData {
    var name: String
    var amount: Decimal
    var currency: String
    var group: ExpenseGroup?
    var source: PaymentSource?
    var note: String?
}

// MARK: - Template Form Sheet

struct RecurringTemplateFormSheet: View {
    
    let template: RecurringTemplate?
    let groups: [ExpenseGroup]
    let sources: [PaymentSource]
    let onSave: (TemplateFormData) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var amountString = ""
    @State private var selectedCurrency = "SGD"
    @State private var selectedGroup: ExpenseGroup?
    @State private var selectedSource: PaymentSource?
    @State private var note = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Name (e.g., Rent Installment)", text: $name)
                    
                    HStack {
                        Text("Amount")
                        Spacer()
                        TextField("0.00", text: $amountString)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                    }
                    
                    Picker("Currency", selection: $selectedCurrency) {
                        ForEach(Currency.allCases, id: \.self) { currency in
                            Text("\(currency.flag) \(currency.rawValue)").tag(currency.rawValue)
                        }
                    }
                }
                
                Section("Group") {
                    Picker("Expense Group", selection: $selectedGroup) {
                        Text("None").tag(nil as ExpenseGroup?)
                        ForEach(groups, id: \.id) { group in
                            HStack {
                                Image(systemName: group.icon)
                                Text(group.name)
                            }
                            .tag(group as ExpenseGroup?)
                        }
                    }
                }
                
                Section("Payment Source") {
                    if sources.isEmpty {
                        Text("No payment sources — add them in Settings first")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Picker("Paid Via", selection: $selectedSource) {
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
            .navigationTitle(template == nil ? "Add Template" : "Edit Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let amount = Decimal(string: amountString) ?? 0
                        let data = TemplateFormData(
                            name: name,
                            amount: amount,
                            currency: selectedCurrency,
                            group: selectedGroup,
                            source: selectedSource,
                            note: note.isEmpty ? nil : note
                        )
                        onSave(data)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || amountString.isEmpty)
                }
            }
            .onAppear {
                if let t = template {
                    name = t.name
                    amountString = "\(NSDecimalNumber(decimal: t.defaultAmount).doubleValue)"
                    selectedCurrency = t.currency
                    selectedGroup = t.expenseGroup
                    selectedSource = t.paymentSource
                    note = t.note ?? ""
                }
            }
        }
    }
}
