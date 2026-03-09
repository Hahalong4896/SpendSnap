// Presentation/Screens/Settings/PaymentSourceScreen.swift
// SpendSnap

import SwiftUI
import SwiftData

/// CRUD screen for managing payment sources (banks, wallets, cash).
/// Accessed from Settings. Users create all their own sources here.
struct PaymentSourceScreen: View {
    
    // MARK: - Environment
    
    @Environment(\.modelContext) private var modelContext
    @Query(
        filter: #Predicate<PaymentSource> { $0.isActive },
        sort: \PaymentSource.sortOrder
    ) private var sources: [PaymentSource]
    
    // MARK: - State
    
    @State private var showAddSheet = false
    @State private var editingSource: PaymentSource?
    
    // MARK: - Body
    
    var body: some View {
        List {
            if sources.isEmpty {
                emptyState
            } else {
                ForEach(sources, id: \.id) { source in
                    sourceRow(source)
                        .onTapGesture { editingSource = source }
                }
                .onMove(perform: moveSource)
            }
        }
        .navigationTitle("Payment Sources")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { showAddSheet = true }) {
                    Image(systemName: "plus.circle.fill")
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            PaymentSourceFormSheet(source: nil) { name, icon, colorHex, note in
                addSource(name: name, icon: icon, colorHex: colorHex, note: note)
            }
        }
        .sheet(item: $editingSource) { source in
            PaymentSourceFormSheet(source: source) { name, icon, colorHex, note in
                updateSource(source, name: name, icon: icon, colorHex: colorHex, note: note)
            }
        }
    }
    
    // MARK: - Source Row
    
    private func sourceRow(_ source: PaymentSource) -> some View {
        HStack(spacing: 12) {
            Image(systemName: source.icon)
                .font(.title3)
                .foregroundStyle(Color(hex: source.colorHex))
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(source.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if let note = source.note, !note.isEmpty {
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                deactivateSource(source)
            } label: {
                Label("Remove", systemImage: "trash")
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "building.columns")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text("No payment sources yet")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("Add your bank accounts, e-wallets, and cash sources")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
            
            Button(action: { showAddSheet = true }) {
                Label("Add First Source", systemImage: "plus")
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
    
    private func addSource(name: String, icon: String, colorHex: String, note: String?) {
        let source = PaymentSource(
            name: name,
            icon: icon,
            colorHex: colorHex,
            sortOrder: sources.count,
            note: note
        )
        modelContext.insert(source)
        try? modelContext.save()
    }
    
    private func updateSource(_ source: PaymentSource, name: String, icon: String, colorHex: String, note: String?) {
        source.name = name
        source.icon = icon
        source.colorHex = colorHex
        source.note = note
        try? modelContext.save()
    }
    
    private func deactivateSource(_ source: PaymentSource) {
        source.isActive = false
        try? modelContext.save()
    }
    
    private func moveSource(from offsets: IndexSet, to destination: Int) {
        var items = sources.sorted { $0.sortOrder < $1.sortOrder }
        items.move(fromOffsets: offsets, toOffset: destination)
        for (index, item) in items.enumerated() {
            item.sortOrder = index
        }
        try? modelContext.save()
    }
}

// MARK: - Add/Edit Form Sheet

struct PaymentSourceFormSheet: View {
    
    let source: PaymentSource?
    let onSave: (String, String, String, String?) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var selectedIcon: String = "building.columns"
    @State private var selectedColor: String = "#636e72"
    @State private var note: String = ""
    
    // Curated icon list for banks/finance
    private let iconOptions = [
        "building.columns", "building.columns.fill",
        "building.2", "building.2.fill",
        "banknote", "banknote.fill",
        "creditcard", "creditcard.fill",
        "wallet.bifold", "wallet.bifold.fill",
        "arrow.left.arrow.right",
        "dollarsign.circle", "dollarsign.circle.fill",
        "lock.shield", "lock.shield.fill",
        "person.circle", "person.circle.fill",
        "globe", "globe.americas",
        "briefcase", "briefcase.fill",
        "gift", "gift.fill",
    ]
    
    // Colour palette
    private let colorOptions = [
        "#0984e3", "#00b894", "#6c5ce7", "#e17055",
        "#fdcb6e", "#636e72", "#d63031", "#e84393",
        "#00cec9", "#2d3436", "#74b9ff", "#55efc4",
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("e.g., OCBC, Cash, TransferWise", text: $name)
                }
                
                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(iconOptions, id: \.self) { icon in
                            Image(systemName: icon)
                                .font(.title3)
                                .frame(width: 40, height: 40)
                                .background(
                                    selectedIcon == icon
                                    ? Color(hex: selectedColor).opacity(0.2)
                                    : Color(.systemGray6)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(selectedIcon == icon ? Color(hex: selectedColor) : .clear, lineWidth: 2)
                                )
                                .onTapGesture { selectedIcon = icon }
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                Section("Colour") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(colorOptions, id: \.self) { color in
                            Circle()
                                .fill(Color(hex: color))
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Circle()
                                        .stroke(.white, lineWidth: selectedColor == color ? 3 : 0)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(Color(hex: color), lineWidth: selectedColor == color ? 2 : 0)
                                        .scaleEffect(1.2)
                                )
                                .onTapGesture { selectedColor = color }
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                Section("Note (Optional)") {
                    TextField("e.g., Account ending 1234", text: $note)
                }
            }
            .navigationTitle(source == nil ? "Add Source" : "Edit Source")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(name, selectedIcon, selectedColor, note.isEmpty ? nil : note)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if let source = source {
                    name = source.name
                    selectedIcon = source.icon
                    selectedColor = source.colorHex
                    note = source.note ?? ""
                }
            }
        }
    }
}
