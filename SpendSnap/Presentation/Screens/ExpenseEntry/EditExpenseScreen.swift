// Presentation/Screens/ExpenseEntry/EditExpenseScreen.swift
// SpendSnap

import SwiftUI
import SwiftData

/// Screen for editing an existing expense's details.
struct EditExpenseScreen: View {
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let expense: Expense
    
    @State private var selectedCategory: Category?
    @State private var amountString: String = ""
    @State private var vendor: String = ""
    @State private var note: String = ""
    @State private var expenseDate: Date = Date()
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var selectedCurrency: Currency = .sgd
    @State private var selectedPaymentSource: PaymentSource?
    
    @Query(
        filter: #Predicate<PaymentSource> { $0.isActive },
        sort: \PaymentSource.sortOrder
    ) private var paymentSources: [PaymentSource]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    
                    // ── Photo (read-only) ──
                    if let image = PhotoStorageService.loadPhoto(named: expense.photoFileName) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 180)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal)
                    }
                    
                    // ── Category ──
                    VStack(alignment: .leading, spacing: 8) {
                        sectionLabel("Category")
                        CategoryGridView(selectedCategory: $selectedCategory)
                    }
                    .padding(.horizontal)
                    
                    // ── Amount ──
                    VStack(alignment: .leading, spacing: 8) {
                        sectionLabel("Amount")
                        AmountInputView(amount: $amountString, selectedCurrency: $selectedCurrency)
                    }
                    .padding(.horizontal)
                    
                    // ── Payment Source ──
                    if !paymentSources.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            sectionLabel("Paid Via")
                            PaymentSourcePicker(
                                sources: paymentSources,
                                selected: $selectedPaymentSource
                            )
                        }
                        .padding(.horizontal)
                    }
                    
                    // ── Details ──
                    VStack(alignment: .leading, spacing: 8) {
                        sectionLabel("Details")
                        
                        TextField("Vendor / Shop name", text: $vendor)
                            .font(.body)
                            .padding(14)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(.systemGray4), lineWidth: 0.5))
                        
                        TextField("Notes", text: $note)
                            .font(.body)
                            .padding(14)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(.systemGray4), lineWidth: 0.5))
                        
                        DatePicker("Date", selection: $expenseDate, displayedComponents: .date)
                    }
                    .padding(.horizontal)
                    
                    // ── Save Button ──
                    Button(action: saveChanges) {
                        Text("Save Changes")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(canSave ? Color.blue : Color.gray.opacity(0.4))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(!canSave)
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Edit Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                selectedCategory = expense.category
                amountString = formatDecimal(expense.amount)
                vendor = expense.vendor ?? ""
                note = expense.note ?? ""
                expenseDate = expense.date
                selectedCurrency = Currency(rawValue: expense.currency) ?? .sgd
                selectedPaymentSource = expense.paymentSource
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Helpers
    
    private var canSave: Bool {
        selectedCategory != nil
        && !amountString.isEmpty
        && (Decimal(string: amountString) ?? 0) > 0
    }
    
    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 4)
    }
    
    /// Formats Decimal cleanly without floating point artifacts
    private func formatDecimal(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        formatter.groupingSeparator = ""
        return formatter.string(from: NSDecimalNumber(decimal: value)) ?? "0"
    }
    
    // MARK: - Save
    
    private func saveChanges() {
        guard let category = selectedCategory,
              let amount = Decimal(string: amountString) else {
            errorMessage = "Please fill in all required fields."
            showError = true
            return
        }
        
        expense.category = category
        expense.amount = amount
        expense.currency = selectedCurrency.rawValue
        expense.vendor = vendor.isEmpty ? nil : vendor
        expense.note = note.isEmpty ? nil : note
        expense.date = expenseDate
        expense.paymentSource = selectedPaymentSource
        expense.updatedAt = Date()
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = "Failed to save: \(error.localizedDescription)"
            showError = true
        }
    }
}
