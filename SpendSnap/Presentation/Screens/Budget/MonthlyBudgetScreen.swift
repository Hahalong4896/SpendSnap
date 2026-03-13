// Presentation/Screens/Budget/MonthlyBudgetScreen.swift
// SpendSnap

import SwiftUI
import SwiftData

struct SheetGroup: Identifiable {
    let id: UUID
    let group: ExpenseGroup
    let mode: SheetMode
    enum SheetMode { case quickAdd, petrol, grocery, maintenance }
    init(_ group: ExpenseGroup, mode: SheetMode) { self.id = UUID(); self.group = group; self.mode = mode }
}

struct MonthlyBudgetScreen: View {
    
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Expense.date, order: .reverse) private var allDailyExpenses: [Expense]
    @Query(sort: \MonthlyExpenseEntry.createdAt) private var allEntries: [MonthlyExpenseEntry]
    @Query(sort: \IncomeEntry.createdAt) private var allIncome: [IncomeEntry]
    @Query(filter: #Predicate<ExpenseGroup> { $0.isVisible }, sort: \ExpenseGroup.sortOrder) private var groups: [ExpenseGroup]
    
    @State private var selectedMonth: Date = Date()
    @State private var showIncomeSheet = false
    @State private var editingIncome: IncomeEntry?
    @State private var editingEntry: MonthlyExpenseEntry?
    @State private var showTemplateSheet = false
    @State private var activeGroupSheet: SheetGroup?
    
    private var calendar: Calendar { Calendar.current }
    private var currentMonth: Int { calendar.component(.month, from: selectedMonth) }
    private var currentYear: Int { calendar.component(.year, from: selectedMonth) }
    
    private var monthIncome: [IncomeEntry] { allIncome.filter { $0.month == currentMonth && $0.year == currentYear } }
    private var monthEntries: [MonthlyExpenseEntry] { allEntries.filter { $0.month == currentMonth && $0.year == currentYear } }
    private var monthDailyExpenses: [Expense] { allDailyExpenses.filter { calendar.isDate($0.date, equalTo: selectedMonth, toGranularity: .month) } }
    private var recurringGroups: [ExpenseGroup] { groups.filter { $0.type == .recurring } }
    
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
    private var monthTitle: String { selectedMonth.formatted(.dateTime.month(.wide).year()) }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    monthSelector
                    balanceCard
                    incomeSection
                    ForEach(recurringGroups, id: \.id) { group in
                        if group.hasItemisedEntries { itemisedGroupSection(group) }
                        else { simpleGroupSection(group) }
                    }
                    dailyExpenseSummary
                    FundAllocationView(recurringEntries: monthEntries, dailyExpenses: monthDailyExpenses, incomeEntries: monthIncome).padding(.horizontal)
                }
                .padding(.top).padding(.bottom, 30)
            }
            .navigationTitle("Budget")
            .toolbar(content: {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(action: { showTemplateSheet = true }) { Label("Manage Templates", systemImage: "doc.text.below.ecg") }
                        Button(action: regenerateEntries) { Label("Re-generate from Templates", systemImage: "arrow.clockwise") }
                        Divider()
                        Button(action: exportPDF) { Label("Export PDF Report", systemImage: "square.and.arrow.up") }
                    } label: { Image(systemName: "ellipsis.circle") }
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
            .sheet(item: $activeGroupSheet) { sheetItem in
                switch sheetItem.mode {
                case .quickAdd: MonthlyEntryAddSheet(group: sheetItem.group, month: currentMonth, year: currentYear)
                case .petrol: PetrolEntrySheet(group: sheetItem.group, month: currentMonth, year: currentYear)
                case .grocery: GroceryEntrySheet(group: sheetItem.group, month: currentMonth, year: currentYear)
                case .maintenance: MaintenanceEntrySheet(group: sheetItem.group, month: currentMonth, year: currentYear)
                }
            }
            .sheet(isPresented: $showTemplateSheet) {
                NavigationStack {
                    RecurringTemplateScreen()
                        .toolbar(content: { ToolbarItem(placement: .cancellationAction) { Button("Done") { showTemplateSheet = false } } })
                }
            }
            .onAppear { initializeBudget() }
            .onChange(of: selectedMonth) { _, _ in initializeBudget() }
        }
    }
    
    // MARK: - Actions
    
    private func initializeBudget() {
        MonthlyBudgetService.ensureBudget(month: currentMonth, year: currentYear, context: modelContext)
    }
    
    private func regenerateEntries() {
        MonthlyBudgetService.regenerateFromTemplates(month: currentMonth, year: currentYear, context: modelContext)
    }
    
    private func deleteEntry(_ entry: MonthlyExpenseEntry) {
        modelContext.delete(entry)
        try? modelContext.save()
    }
    
    private func deleteIncome(_ income: IncomeEntry) {
        modelContext.delete(income)
        try? modelContext.save()
    }
    
    private func exportPDF() {
        let generator = BudgetPDFGenerator()
        if let url = generator.generateBudgetPDF(monthTitle: monthTitle, incomeEntries: monthIncome, recurringEntries: monthEntries, dailyExpenses: monthDailyExpenses, groups: recurringGroups, totalIncome: totalIncome, totalRecurring: totalRecurring, totalDaily: totalDaily, balance: balance) {
            DispatchQueue.main.async {
                guard let ws = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                      let root = ws.windows.first?.rootViewController else { return }
                var top = root
                while let p = top.presentedViewController { top = p }
                let vc = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                if let pop = vc.popoverPresentationController {
                    pop.sourceView = top.view
                    pop.sourceRect = CGRect(x: top.view.bounds.midX, y: 60, width: 0, height: 0)
                }
                top.present(vc, animated: true)
            }
        }
    }
    
    // MARK: - Month Selector
    
    private var monthSelector: some View {
        HStack {
            Button(action: { if let d = calendar.date(byAdding: .month, value: -1, to: selectedMonth) { selectedMonth = d } }) {
                Image(systemName: "chevron.left").font(.title3).fontWeight(.semibold)
            }
            Spacer()
            Text(monthTitle).font(.title3).fontWeight(.semibold)
            Spacer()
            Button(action: { if let d = calendar.date(byAdding: .month, value: 1, to: selectedMonth) { selectedMonth = d } }) {
                Image(systemName: "chevron.right").font(.title3).fontWeight(.semibold)
            }
        }.padding(.horizontal, 24)
    }
    
    // MARK: - Balance Card
    
    private var balanceCard: some View {
        VStack(spacing: 12) {
            Text("Balance").font(.caption).foregroundStyle(.secondary)
            Text("S$\(NSDecimalNumber(decimal: balance).doubleValue, specifier: "%.2f")")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(balance >= 0 ? Color.primary : Color.red)
            HStack(spacing: 24) {
                VStack(spacing: 2) {
                    Text("S$\(NSDecimalNumber(decimal: totalIncome).doubleValue, specifier: "%.2f")")
                        .font(.subheadline).fontWeight(.semibold).foregroundColor(Color.green)
                    Text("Income").font(.caption2).foregroundStyle(.secondary)
                }
                VStack(spacing: 2) {
                    Text("S$\(NSDecimalNumber(decimal: totalExpenses).doubleValue, specifier: "%.2f")")
                        .font(.subheadline).fontWeight(.semibold).foregroundColor(Color.red)
                    Text("Expenses").font(.caption2).foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity).padding(.vertical, 20)
        .background(Color(.systemGray6)).clipShape(RoundedRectangle(cornerRadius: 14)).padding(.horizontal)
    }
    
    // MARK: - Income Section
    
    private var incomeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "arrow.down.circle.fill").foregroundColor(Color.green)
                Text("Income").font(.headline)
                Spacer()
                Button(action: { showIncomeSheet = true }) { Image(systemName: "plus.circle").font(.title3) }
            }.padding(.horizontal)
            
            if monthIncome.isEmpty {
                Text("No income entries — tap + to add").font(.caption).foregroundStyle(.secondary).padding(.horizontal)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(monthIncome.enumerated()), id: \.element.id) { index, income in
                        incomeRow(income)
                        if index < monthIncome.count - 1 { Divider().padding(.horizontal, 14) }
                    }
                    Divider()
                    HStack {
                        Text("Total Income").font(.subheadline).fontWeight(.bold)
                        Spacer()
                        Text("S$\(NSDecimalNumber(decimal: totalIncome).doubleValue, specifier: "%.2f")")
                            .font(.subheadline).fontWeight(.bold).foregroundColor(Color.green)
                    }.padding(.vertical, 10).padding(.horizontal, 14)
                }.background(Color(.systemGray6)).clipShape(RoundedRectangle(cornerRadius: 14)).padding(.horizontal)
            }
        }
    }
    
    private func incomeRow(_ income: IncomeEntry) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(income.name).font(.subheadline)
                if let src = income.paymentSource {
                    HStack(spacing: 4) { Image(systemName: src.icon).font(.caption2); Text(src.name).font(.caption) }
                        .foregroundStyle(Color(hex: src.colorHex))
                }
            }
            Spacer()
            let sym = Currency.symbol(for: income.currency)
            Text("\(sym)\(NSDecimalNumber(decimal: income.amount).doubleValue, specifier: "%.2f")")
                .font(.subheadline).fontWeight(.semibold)
        }
        .padding(.vertical, 10).padding(.horizontal, 14).contentShape(Rectangle())
        .onTapGesture { editingIncome = income }
        .contextMenu {
            Button(role: .destructive) { deleteIncome(income) } label: { Label("Delete", systemImage: "trash") }
        }
    }
    
    // MARK: - Simple Group (Housing, Insurance, Family, etc.)
    
    private func simpleGroupSection(_ group: ExpenseGroup) -> some View {
        let entries = monthEntries.filter { $0.expenseGroup?.id == group.id }.sorted { $0.createdAt < $1.createdAt }
        let cs = CurrencyService.shared
        let total = entries.reduce(Decimal(0)) { $0 + cs.convertToSGD(amount: $1.amount, from: $1.currency) }
        
        return VStack(alignment: .leading, spacing: 10) {
            groupHeader(group, total: total, showAdd: { activeGroupSheet = SheetGroup(group, mode: .quickAdd) })
            if entries.isEmpty {
                Text("No entries").font(.caption).foregroundStyle(.secondary).padding(.horizontal)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(entries.enumerated()), id: \.element.id) { i, entry in
                        fixedEntryRow(entry)
                        if i < entries.count - 1 { Divider().padding(.horizontal, 14) }
                    }
                }.background(Color(.systemGray6)).clipShape(RoundedRectangle(cornerRadius: 14)).padding(.horizontal)
            }
        }
    }
    
    // MARK: - Itemised Group (Transport, Groceries)
    
    private func itemisedGroupSection(_ group: ExpenseGroup) -> some View {
        let all = monthEntries.filter { $0.expenseGroup?.id == group.id }
        let fixed = all.filter { $0.entryType == "fixed" }.sorted { $0.createdAt < $1.createdAt }
        let itemised = all.filter { $0.entryType != "fixed" }.sorted { $0.createdAt > $1.createdAt }
        let cs = CurrencyService.shared
        let total = all.reduce(Decimal(0)) { $0 + cs.convertToSGD(amount: $1.amount, from: $1.currency) }
        let isTransport = group.name.lowercased().contains("transport")
        
        return VStack(alignment: .leading, spacing: 10) {
            groupHeader(group, total: total, showAdd: { activeGroupSheet = SheetGroup(group, mode: .quickAdd) })
            
            // Fixed items
            if !fixed.isEmpty {
                VStack(spacing: 0) {
                    ForEach(Array(fixed.enumerated()), id: \.element.id) { i, entry in
                        fixedEntryRow(entry)
                        if i < fixed.count - 1 { Divider().padding(.horizontal, 14) }
                    }
                }.background(Color(.systemGray6)).clipShape(RoundedRectangle(cornerRadius: 14)).padding(.horizontal)
            }
            
            // Itemised entries
            if !itemised.isEmpty {
                VStack(spacing: 0) {
                    ForEach(Array(itemised.enumerated()), id: \.element.id) { i, entry in
                        itemisedEntryRow(entry)
                        if i < itemised.count - 1 { Divider().padding(.horizontal, 14) }
                    }
                }.background(Color(.systemGray6)).clipShape(RoundedRectangle(cornerRadius: 14)).padding(.horizontal)
            }
            
            // Action buttons — Transport gets Petrol + Maintenance, others get Grocery
            if isTransport {
                HStack(spacing: 12) {
                    Button(action: { activeGroupSheet = SheetGroup(group, mode: .petrol) }) {
                        HStack(spacing: 6) {
                            Image(systemName: "fuelpump.fill")
                            Text("Add Petrol").fontWeight(.semibold)
                        }
                        .font(.subheadline)
                        .foregroundColor(Color(hex: group.colorHex))
                        .frame(maxWidth: .infinity).padding(.vertical, 12)
                        .background(Color(hex: group.colorHex).opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    Button(action: { activeGroupSheet = SheetGroup(group, mode: .maintenance) }) {
                        HStack(spacing: 6) {
                            Image(systemName: "wrench.fill")
                            Text("Maintenance").fontWeight(.semibold)
                        }
                        .font(.subheadline)
                        .foregroundColor(Color(hex: group.colorHex))
                        .frame(maxWidth: .infinity).padding(.vertical, 12)
                        .background(Color(hex: group.colorHex).opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.horizontal)
            } else {
                Button(action: { activeGroupSheet = SheetGroup(group, mode: .grocery) }) {
                    HStack(spacing: 8) {
                        Image(systemName: "basket.fill")
                        Text("Add Grocery").fontWeight(.semibold)
                    }
                    .font(.subheadline)
                    .foregroundColor(Color(hex: group.colorHex))
                    .frame(maxWidth: .infinity).padding(.vertical, 12)
                    .background(Color(hex: group.colorHex).opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Group Header
    
    private func groupHeader(_ group: ExpenseGroup, total: Decimal, showAdd: @escaping () -> Void) -> some View {
        HStack {
            Image(systemName: group.icon).foregroundStyle(Color(hex: group.colorHex))
            Text(group.name).font(.headline)
            Spacer()
            Text("S$\(NSDecimalNumber(decimal: total).doubleValue, specifier: "%.2f")")
                .font(.subheadline).fontWeight(.semibold).foregroundStyle(.secondary)
            Button(action: showAdd) { Image(systemName: "plus.circle").font(.title3) }
        }.padding(.horizontal)
    }
    
    // MARK: - Fixed Entry Row
    
    private func fixedEntryRow(_ entry: MonthlyExpenseEntry) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.name).font(.subheadline)
                if let src = entry.paymentSource {
                    HStack(spacing: 4) { Image(systemName: src.icon).font(.caption2); Text(src.name).font(.caption) }
                        .foregroundStyle(Color(hex: src.colorHex))
                }
            }
            Spacer()
            let sym = Currency.symbol(for: entry.currency)
            Text("\(sym)\(NSDecimalNumber(decimal: entry.amount).doubleValue, specifier: "%.2f")")
                .font(.subheadline).fontWeight(.semibold)
        }
        .padding(.vertical, 10).padding(.horizontal, 14).contentShape(Rectangle())
        .onTapGesture { editingEntry = entry }
        .contextMenu {
            Button(role: .destructive) { deleteEntry(entry) } label: { Label("Delete", systemImage: "trash") }
        }
    }
    
    // MARK: - Itemised Entry Row
    
    private func itemisedEntryRow(_ entry: MonthlyExpenseEntry) -> some View {
        HStack(spacing: 10) {
            Image(systemName: entry.type == .petrol ? "fuelpump.fill" : "basket.fill")
                .font(.caption)
                .foregroundColor(Color(hex: entry.expenseGroup?.colorHex ?? "#999999"))
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(entry.name).font(.subheadline)
                    if entry.photoFileName != nil {
                        Image(systemName: "camera.fill").font(.caption2).foregroundStyle(.tertiary)
                    }
                }
                HStack(spacing: 8) {
                    if let src = entry.paymentSource {
                        HStack(spacing: 3) { Image(systemName: src.icon).font(.caption2); Text(src.name).font(.caption) }
                            .foregroundStyle(Color(hex: src.colorHex))
                    }
                    if entry.type == .petrol {
                        if let l = entry.litersFilled { Text("\(String(format: "%.1f", l))L").font(.caption).foregroundStyle(.secondary) }
                        if let o = entry.odometerReading { Text("\(String(format: "%.0f", o))km").font(.caption).foregroundStyle(.secondary) }
                    }
                }
                Text(entry.createdAt.formatted(date: .abbreviated, time: .omitted)).font(.caption2).foregroundStyle(.tertiary)
            }
            
            Spacer()
            
            let sym = Currency.symbol(for: entry.currency)
            Text("\(sym)\(NSDecimalNumber(decimal: entry.amount).doubleValue, specifier: "%.2f")")
                .font(.subheadline).fontWeight(.semibold)
        }
        .padding(.vertical, 10).padding(.horizontal, 14).contentShape(Rectangle())
        .onTapGesture { editingEntry = entry }
        .contextMenu {
            Button(role: .destructive) { deleteEntry(entry) } label: { Label("Delete", systemImage: "trash") }
        }
    }
    
    // MARK: - Daily Expense Summary
    
    private var dailyExpenseSummary: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "cart.fill").foregroundStyle(Color(hex: "#FF6B6B"))
                Text("Daily Expenses").font(.headline)
                Spacer()
                Text("\(monthDailyExpenses.count) items").font(.caption).foregroundStyle(.secondary)
            }.padding(.horizontal)
            HStack {
                Text("Total").font(.subheadline)
                Spacer()
                Text("S$\(NSDecimalNumber(decimal: totalDaily).doubleValue, specifier: "%.2f")")
                    .font(.subheadline).fontWeight(.bold)
            }
            .padding(.vertical, 14).padding(.horizontal, 14)
            .background(Color(.systemGray6)).clipShape(RoundedRectangle(cornerRadius: 14)).padding(.horizontal)
        }
    }
}
