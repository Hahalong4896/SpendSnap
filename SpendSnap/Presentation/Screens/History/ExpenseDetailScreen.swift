// Presentation/Screens/History/ExpenseDetailScreen.swift
// SpendSnap

import SwiftUI
import SwiftData

/// Full detail view for a single expense.
/// Shows the full photo, all fields, and allows editing or deletion.
struct ExpenseDetailScreen: View {
    
    // MARK: - Environment
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Properties
    
    let expense: Expense
    @State private var showEditSheet = false
    @State private var showDeleteAlert = false
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                
                // ── Photo ──
                if expense.photoFileName != "no_photo",
                   let image = PhotoStorageService.loadPhoto(named: expense.photoFileName) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)
                } else {
                    // No photo placeholder
                    VStack(spacing: 8) {
                        Image(systemName: expense.category?.icon ?? "ellipsis.circle")
                            .font(.system(size: 40))
                            .foregroundStyle(Color(hex: expense.category?.colorHex ?? "#B2BEC3"))
                        Text("No photo")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 150)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                }
                
                // ── Amount ──
                VStack(spacing: 4) {
                    Text("\(currencySymbol)\(NSDecimalNumber(decimal: expense.amount).doubleValue, specifier: "%.2f")")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                    
                    if let category = expense.category {
                        HStack(spacing: 6) {
                            Image(systemName: category.icon)
                                .foregroundStyle(Color(hex: category.colorHex))
                            Text(category.name)
                                .foregroundStyle(.secondary)
                        }
                        .font(.subheadline)
                    }
                }
                
                // ── Details Card ──
                VStack(spacing: 0) {
                    detailRow(label: "Date", value: expense.date.formatted(date: .long, time: .shortened))
                    
                    Divider().padding(.horizontal)
                    
                    if let vendor = expense.vendor, !vendor.isEmpty {
                        detailRow(label: "Vendor", value: vendor)
                        Divider().padding(.horizontal)
                    }
                    
                    if let note = expense.note, !note.isEmpty {
                        detailRow(label: "Notes", value: note)
                        Divider().padding(.horizontal)
                    }
                    
                    detailRow(label: "Currency", value: expense.currency)
                    
                    Divider().padding(.horizontal)
                    
                    detailRow(label: "Recorded", value: expense.createdAt.formatted(date: .abbreviated, time: .shortened))
                }
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal)
                
                // ── Action Buttons ──
                VStack(spacing: 12) {
                    Button(action: { showEditSheet = true }) {
                        Label("Edit Expense", systemImage: "pencil")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.blue)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    Button(role: .destructive, action: { showDeleteAlert = true }) {
                        Label("Delete Expense", systemImage: "trash")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.red.opacity(0.1))
                            .foregroundStyle(.red)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
            .padding(.top)
        }
        .navigationTitle("Expense Detail")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showEditSheet) {
            EditExpenseScreen(expense: expense)
        }
        .alert("Delete Expense?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteExpense()
            }
        } message: {
            Text("This will permanently delete this expense and its photo.")
        }
    }
    
    // MARK: - Detail Row
    
    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    // MARK: - Actions
    
    private func deleteExpense() {
        let repository = ExpenseRepository(modelContext: modelContext)
        try? repository.deleteExpense(expense)
        dismiss()
    }
    
    private var currencySymbol: String {
        (Currency(rawValue: expense.currency) ?? .sgd).symbol
    }
    
}

