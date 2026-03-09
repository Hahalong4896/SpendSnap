// Presentation/Screens/Budget/MonthlyBudgetScreen.swift
// SpendSnap

import SwiftUI
import SwiftData

/// Monthly Budget Workspace — the primary new screen in Phase 2.5.
struct MonthlyBudgetScreen: View {
    
    // MARK: - Environment
    
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Expense.date, order: .reverse) private var allDailyExpenses: [Expense]
    @Query(sort: \MonthlyExpenseEntry.createdAt) private var allEntries: [MonthlyExpenseEntry]
    @Query(sort: \IncomeEntry.createdAt) private var allIncome: [IncomeEntry]
    @Query(
        filter: #Predicate<ExpenseGroup> { $0.isVisible },
        sort: \ExpenseGroup.sortOrder
    ) private var groups: [ExpenseGroup]
    
    // MARK: - State
    
    @State private var selectedMonth: Date = Date()
    @State private var showIncomeSheet = false
    @State private var editingIncome: IncomeEntry?
    @State private var showAddEntrySheet = false
    @State private var showReceiptCapture = false
    @State private var addEntryGroup: ExpenseGroup?
    @State private var editingEntry: MonthlyExpenseEntry?
    @State private var showTemplateSheet = false
    
    // MARK: - Calendar Helpers
    
    private var calendar: Calendar { Calendar.current }
    private var currentMonth: Int { calendar.component(.month, from: selectedMonth) }
    private var currentYear: Int { calendar.component(.year, from: selectedMonth) }
    
    // MARK: - Filtered Data
    
    private var monthIncome: [IncomeEntry] {
        allIncome.filter { $0.month == currentMonth && $0.year == currentYear }
    }
    
    private var monthEntries: [MonthlyExpenseEntry] {
        allEntries.filter { $0.month == currentMonth && $0.year == currentYear }
    }
    
    private var monthDailyExpenses: [Expense] {
        allDailyExpenses.filter {
            calendar.isDate($0.date, equalTo: selectedMonth, toGranularity: .month)
        }
    }
    
    private var recurringGroups: [ExpenseGroup] {
        groups.filter { $0.type == .recurring }
    }
    
    // MARK: - Totals (SGD)
    
    private var totalIncome: Decimal {
        let cs = CurrencyService.shared
        return monthIncome.reduce(0) { $0 + cs.convertToSGD(amount: $1.amount, from: $1.currency) }
    }
    
    private var totalRecurring: Decimal {
        let cs = CurrencyService.shared
        return monthEntries.reduce(0) { $0 + cs.convertToSGD(amount: $1.amount, from: $1.currency) }
    }
    
    private var totalDaily: Decimal {
        let cs = CurrencyService.shared
        return monthDailyExpenses.reduce(0) { $0 + cs.convertToSGD(amount: $1.amount, from: $1.currency) }
    }
    
    private var totalExpenses: Decimal { totalRecurring + totalDaily }
    private var balance: Decimal { totalIncome - totalExpenses }
    
    private var monthTitle: String {
        selectedMonth.formatted(.dateTime.month(.wide).year())
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    monthSelector
                    balanceCard
                    incomeSection
                    
                    ForEach(recurringGroups, id: \.id) { group in
                        recurringGroupSection(group)
                    }
                    
                    dailyExpenseSummary
                    
                    FundAllocationView(
                        recurringEntries: monthEntries,
                        dailyExpenses: monthDailyExpenses,
                        incomeEntries: monthIncome
                    )
                    .padding(.horizontal)
                }
                .padding(.top)
                .padding(.bottom, 30)
            }
            .navigationTitle("Budget")
            .toolbar(content: {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(action: { showTemplateSheet = true }) {
                            Label("Manage Templates", systemImage: "doc.text.below.ecg")
                        }
                        Button(action: regenerateEntries) {
                            Label("Re-generate from Templates", systemImage: "arrow.clockwise")
                        }
                        Divider()
                        Button(action: exportPDF) {
                            Label("Export PDF Report", systemImage: "square.and.arrow.up")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            })
            .sheet(isPresented: $showIncomeSheet) {
                IncomeEntryScreen(month: currentMonth, year: currentYear, existingEntry: nil)
            }
            .sheet(item: $editingIncome) { income in
                IncomeEntryScreen(month: currentMonth, year: currentYear, existingEntry: income)
            }
            .sheet(item: $editingEntry) { entry in
                MonthlyEntryEditSheet(entry: entry)
            }
            .sheet(isPresented: $showAddEntrySheet) {
                if let group = addEntryGroup {
                    MonthlyEntryAddSheet(group: group, month: currentMonth, year: currentYear)
                }
            }
            .sheet(isPresented: $showReceiptCapture) {
                if let group = addEntryGroup {
                    BudgetReceiptCaptureSheet(group: group, month: currentMonth, year: currentYear)
                }
            }
            .sheet(isPresented: $showTemplateSheet) {
                NavigationStack {
                    RecurringTemplateScreen()
                        .toolbar(content: {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Done") { showTemplateSheet = false }
                            }
                        })
                }
            }
            .onAppear { initializeBudget() }
            .onChange(of: selectedMonth) { _, _ in initializeBudget() }
        }
    }
    
    // MARK: - Initialize Budget
    
    private func initializeBudget() {
        MonthlyBudgetService.ensureBudget(month: currentMonth, year: currentYear, context: modelContext)
    }
    
    private func regenerateEntries() {
        let existing = monthEntries.filter { $0.templateID != nil }
        for entry in existing {
            modelContext.delete(entry)
        }
        try? modelContext.save()
        initializeBudget()
    }
    
    // MARK: - Export PDF
    
    private func exportPDF() {
        let generator = BudgetPDFGenerator()
        if let url = generator.generateBudgetPDF(
            monthTitle: monthTitle,
            incomeEntries: monthIncome,
            recurringEntries: monthEntries,
            dailyExpenses: monthDailyExpenses,
            groups: recurringGroups,
            totalIncome: totalIncome,
            totalRecurring: totalRecurring,
            totalDaily: totalDaily,
            balance: balance
        ) {
            DispatchQueue.main.async {
                guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                      let rootVC = windowScene.windows.first?.rootViewController else { return }
                var topVC = rootVC
                while let presented = topVC.presentedViewController { topVC = presented }
                let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                if let popover = activityVC.popoverPresentationController {
                    popover.sourceView = topVC.view
                    popover.sourceRect = CGRect(x: topVC.view.bounds.midX, y: 60, width: 0, height: 0)
                }
                topVC.present(activityVC, animated: true)
            }
        }
    }
    
    // MARK: - Month Selector
    
    private var monthSelector: some View {
        HStack {
            Button(action: {
                if let newDate = calendar.date(byAdding: .month, value: -1, to: selectedMonth) {
                    selectedMonth = newDate
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            Spacer()
            Text(monthTitle)
                .font(.title3)
                .fontWeight(.semibold)
            Spacer()
            Button(action: {
                if let newDate = calendar.date(byAdding: .month, value: 1, to: selectedMonth) {
                    selectedMonth = newDate
                }
            }) {
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .fontWeight(.semibold)
            }
        }
        .padding(.horizontal, 24)
    }
    
    // MARK: - Balance Card
    
    private var balanceCard: some View {
        VStack(spacing: 12) {
            Text("Balance")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text("S$\(NSDecimalNumber(decimal: balance).doubleValue, specifier: "%.2f")")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(balance >= 0 ? Color.primary : Color.red)
            
            HStack(spacing: 24) {
                VStack(spacing: 2) {
                    Text("S$\(NSDecimalNumber(decimal: totalIncome).doubleValue, specifier: "%.2f")")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.green)
                    Text("Income")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                VStack(spacing: 2) {
                    Text("S$\(NSDecimalNumber(decimal: totalExpenses).doubleValue, specifier: "%.2f")")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.red)
                    Text("Expenses")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal)
    }
    
    // MARK: - Income Section
    
    private var incomeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "arrow.down.circle.fill")
                    .foregroundColor(Color.green)
                Text("Income")
                    .font(.headline)
                Spacer()
                Button(action: { showIncomeSheet = true }) {
                    Image(systemName: "plus.circle")
                        .font(.title3)
                }
            }
            .padding(.horizontal)
            
            if monthIncome.isEmpty {
                Text("No income entries — tap + to add")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(monthIncome.enumerated()), id: \.element.id) { index, income in
                        HStack(spacing: 10) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(income.name)
                                    .font(.subheadline)
                                if let source = income.paymentSource {
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
                            let sym = Currency.symbol(for: income.currency)
                            Text("\(sym)\(NSDecimalNumber(decimal: income.amount).doubleValue, specifier: "%.2f")")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 14)
                        .contentShape(Rectangle())
                        .onTapGesture { editingIncome = income }
                        
                        if index < monthIncome.count - 1 {
                            Divider().padding(.horizontal, 14)
                        }
                    }
                    
                    Divider()
                    HStack {
                        Text("Total Income")
                            .font(.subheadline)
                            .fontWeight(.bold)
                        Spacer()
                        Text("S$\(NSDecimalNumber(decimal: totalIncome).doubleValue, specifier: "%.2f")")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(Color.green)
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 14)
                }
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Recurring Group Section
    
    private func recurringGroupSection(_ group: ExpenseGroup) -> some View {
        let groupEntries = monthEntries
            .filter { $0.expenseGroup?.id == group.id }
            .sorted { $0.createdAt < $1.createdAt }
        
        let cs = CurrencyService.shared
        let groupTotal = groupEntries.reduce(Decimal(0)) { $0 + cs.convertToSGD(amount: $1.amount, from: $1.currency) }
        
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: group.icon)
                    .foregroundStyle(Color(hex: group.colorHex))
                Text(group.name)
                    .font(.headline)
                
                Spacer()
                
                Text("S$\(NSDecimalNumber(decimal: groupTotal).doubleValue, specifier: "%.2f")")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                
                // ── + Menu: Quick Add or Capture Receipt ──
                Menu {
                    Button(action: {
                        addEntryGroup = group
                        showAddEntrySheet = true
                    }) {
                        Label("Quick Add", systemImage: "plus.circle")
                    }
                    Button(action: {
                        addEntryGroup = group
                        showReceiptCapture = true
                    }) {
                        Label("Capture Receipt", systemImage: "camera.fill")
                    }
                } label: {
                    Image(systemName: "plus.circle")
                        .font(.title3)
                }
            }
            .padding(.horizontal)
            
            if groupEntries.isEmpty {
                Text("No entries")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(groupEntries.enumerated()), id: \.element.id) { index, entry in
                        entryRow(entry)
                        if index < groupEntries.count - 1 {
                            Divider().padding(.horizontal, 14)
                        }
                    }
                }
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Entry Row
    
    private func entryRow(_ entry: MonthlyExpenseEntry) -> some View {
        HStack(spacing: 10) {
            Button(action: {
                entry.isPaid.toggle()
                entry.paidDate = entry.isPaid ? Date() : nil
                try? modelContext.save()
            }) {
                Image(systemName: entry.isPaid ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(entry.isPaid ? Color.green : Color.secondary)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(entry.name)
                        .font(.subheadline)
                        .strikethrough(entry.isPaid, color: .secondary)
                    
                    // Show camera icon if has receipt photo
                    if entry.photoFileName != nil {
                        Image(systemName: "camera.fill")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                
                if let source = entry.paymentSource {
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
            
            let sym = Currency.symbol(for: entry.currency)
            Text("\(sym)\(NSDecimalNumber(decimal: entry.amount).doubleValue, specifier: "%.2f")")
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .contentShape(Rectangle())
        .onTapGesture { editingEntry = entry }
    }
    
    // MARK: - Daily Expense Summary
    
    private var dailyExpenseSummary: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "cart.fill")
                    .foregroundStyle(Color(hex: "#FF6B6B"))
                Text("Daily Expenses")
                    .font(.headline)
                Spacer()
                Text("\(monthDailyExpenses.count) items")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            
            HStack {
                Text("Total")
                    .font(.subheadline)
                Spacer()
                Text("S$\(NSDecimalNumber(decimal: totalDaily).doubleValue, specifier: "%.2f")")
                    .font(.subheadline)
                    .fontWeight(.bold)
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 14)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal)
        }
    }
}

// MARK: - Monthly Entry Edit Sheet

struct MonthlyEntryEditSheet: View {
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let entry: MonthlyExpenseEntry
    
    @Query(
        filter: #Predicate<PaymentSource> { $0.isActive },
        sort: \PaymentSource.sortOrder
    ) private var sources: [PaymentSource]
    
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
                        ForEach(Currency.allCases, id: \.self) { currency in
                            Text("\(currency.flag) \(currency.rawValue)").tag(currency.rawValue)
                        }
                    }
                }
                Section("Payment Source") {
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
                Section("Note (Optional)") {
                    TextField("Note", text: $note)
                }
            }
            .navigationTitle("Edit Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        entry.name = name
                        entry.amount = Decimal(string: amountString) ?? 0
                        entry.currency = selectedCurrency
                        entry.paymentSource = selectedSource
                        entry.note = note.isEmpty ? nil : note
                        try? modelContext.save()
                        dismiss()
                    }
                }
            }
            .onAppear {
                name = entry.name
                amountString = "\(NSDecimalNumber(decimal: entry.amount).doubleValue)"
                selectedCurrency = entry.currency
                selectedSource = entry.paymentSource
                note = entry.note ?? ""
            }
        }
    }
}

// MARK: - Monthly Entry Add Sheet

struct MonthlyEntryAddSheet: View {
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let group: ExpenseGroup
    let month: Int
    let year: Int
    
    @Query(
        filter: #Predicate<PaymentSource> { $0.isActive },
        sort: \PaymentSource.sortOrder
    ) private var sources: [PaymentSource]
    
    @State private var name = ""
    @State private var amountString = ""
    @State private var selectedCurrency = "SGD"
    @State private var selectedSource: PaymentSource?
    @State private var note = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Name (e.g., Aircon Repair)", text: $name)
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
                Section("Payment Source") {
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
                Section("Note (Optional)") {
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
                            note: note.isEmpty ? nil : note
                        )
                        modelContext.insert(entry)
                        try? modelContext.save()
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || amountString.isEmpty)
                }
            }
            .onAppear {
                // Auto-select group's default payment source
                if let sourceID = group.defaultPaymentSourceID {
                    selectedSource = sources.first { $0.id.uuidString == sourceID }
                }
            }
        }
    }
}
