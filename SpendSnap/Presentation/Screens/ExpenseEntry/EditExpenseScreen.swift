// Presentation/Screens/ExpenseEntry/EditExpenseScreen.swift
// SpendSnap

import SwiftUI
import SwiftData

/// Screen for editing an existing expense's details.
/// Photo cannot be changed — only category, amount, notes, vendor, and date.
struct EditExpenseScreen: View {
    
    // MARK: - Environment
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Properties
    
    let expense: Expense
    
    @State private var selectedCategory: Category?
    @State private var amountString: String = ""
    @State private var vendor: String = ""
    @State private var note: String = ""
    @State private var expenseDate: Date = Date()
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var selectedCurrency: Currency = .sgd
    
    // MARK: - Body
    
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
                        Text("Category")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                        CategoryGridView(selectedCategory: $selectedCategory)
                    }
                    .padding(.horizontal)
                    
                    // ── Amount ──
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Amount")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                        AmountInputView(amount: $amountString, selectedCurrency: $selectedCurrency)

                    }
                    .padding(.horizontal)
                    
                    // ── Details ──
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Details")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                        
                        TextField("Vendor / Shop name", text: $vendor)
                            .textFieldStyle(.roundedBorder)
                        
                        TextField("Notes", text: $note)
                            .textFieldStyle(.roundedBorder)
                        
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
                // Pre-fill with existing data
                selectedCategory = expense.category
                amountString = "\(NSDecimalNumber(decimal: expense.amount).doubleValue)"
                vendor = expense.vendor ?? ""
                note = expense.note ?? ""
                expenseDate = expense.date
                selectedCurrency = Currency(rawValue: expense.currency) ?? .sgd
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Validation
    
    private var canSave: Bool {
        selectedCategory != nil
        && !amountString.isEmpty
        && (Decimal(string: amountString) ?? 0) > 0
    }
    
    // MARK: - Save
    
    private func saveChanges() {
        expense.currency = selectedCurrency.rawValue
        guard let category = selectedCategory,
              let amount = Decimal(string: amountString) else {
            errorMessage = "Please fill in all required fields."
            showError = true
            return
        }
        
        expense.category = category
        expense.amount = amount
        expense.vendor = vendor.isEmpty ? nil : vendor
        expense.note = note.isEmpty ? nil : note
        expense.date = expenseDate
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
