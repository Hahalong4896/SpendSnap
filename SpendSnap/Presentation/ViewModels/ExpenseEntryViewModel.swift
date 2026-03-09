// Presentation/ViewModels/ExpenseEntryViewModel.swift
// SpendSnap

import SwiftUI
import SwiftData

/// ViewModel for the Expense Entry screen.
/// Manages the state for photo, category, amount, and saving.
@Observable
final class ExpenseEntryViewModel {
    
    // MARK: - State
    
    var capturedImage: UIImage?
    var selectedCategory: Category?
    var amountString: String = ""
    var note: String = ""
    var expenseDate: Date = Date()
    var vendor: String = ""
    
    var isSaving = false
    var showError = false
    var errorMessage = ""
    var didSaveSuccessfully = false
    var currency: String = "SGD"
    
    var locationCity: String?
    var locationCountry: String?
    
    var selectedPaymentSource: PaymentSource?
    
    // MARK: - Validation
    
    /// Whether the form has enough data to save
    var canSave: Bool {
        selectedCategory != nil
        && !amountString.isEmpty
        && (Decimal(string: amountString) ?? 0) > 0
    }
    
    // MARK: - Save
    
    /// Saves the expense to the repository.
    /// - Parameter modelContext: The SwiftData model context.
    func saveExpense(modelContext: ModelContext) {
        guard let category = selectedCategory,
              let amount = Decimal(string: amountString),
              amount > 0 else {
            errorMessage = "Please select a category and enter an amount."
            showError = true
            return
        }
        
        isSaving = true
        
        do {
            // 1. Save photo if one exists
            var fileName = "no_photo"
            if let image = capturedImage {
                fileName = try PhotoStorageService.savePhoto(image)
            }
            
            // 2. Create expense record
            let expense = Expense(
                amount: amount,
                currency: currency,
                category: category,
                vendor: vendor.isEmpty ? nil : vendor,
                note: note.isEmpty ? nil : note,
                photoFileName: fileName,
                date: expenseDate,
                locationCity: locationCity,
                locationCountry: locationCountry
            )
            
            // 3. Assign payment source (AFTER creating the expense, not inside the init)
            expense.paymentSource = selectedPaymentSource
            
            // 4. Save to SwiftData
            let repository = ExpenseRepository(modelContext: modelContext)
            try repository.saveExpense(expense)
            
            // 5. Success
            didSaveSuccessfully = true
            
        } catch {
            errorMessage = "Failed to save expense: \(error.localizedDescription)"
            showError = true
        }
        
        isSaving = false
    }
    
    // MARK: - Reset
    
    /// Resets all fields for a new expense entry.
    func reset() {
        capturedImage = nil
        selectedCategory = nil
        amountString = ""
        note = ""
        vendor = ""
        expenseDate = Date()
        didSaveSuccessfully = false
        locationCity = nil
        locationCountry = nil
        selectedPaymentSource = nil
    }
    
    /// Auto-detect current location
    func detectLocation() {
        LocationService.shared.detectLocation { [weak self] city, country in
            self?.locationCity = city
            self?.locationCountry = country
        }
    }
}
