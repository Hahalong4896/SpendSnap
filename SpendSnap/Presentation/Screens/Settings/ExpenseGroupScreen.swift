// Presentation/Screens/Settings/ExpenseGroupScreen.swift
// SpendSnap

import SwiftUI
import SwiftData

/// Screen for managing expense groups (add, edit, reorder, hide).
/// Now includes default payment source assignment per group.
struct ExpenseGroupScreen: View {
    
    // MARK: - Environment
    
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ExpenseGroup.sortOrder) private var groups: [ExpenseGroup]
    @Query(
        filter: #Predicate<PaymentSource> { $0.isActive },
        sort: \PaymentSource.sortOrder
    ) private var sources: [PaymentSource]
    
    // MARK: - State
    
    @State private var showAddSheet = false
    @State private var editingGroup: ExpenseGroup?
    
    // MARK: - Body
    
    var body: some View {
        List {
            ForEach(groups, id: \.id) { group in
                groupRow(group)
                    .onTapGesture { editingGroup = group }
            }
            .onMove(perform: moveGroup)
        }
        .navigationTitle("Expense Groups")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { showAddSheet = true }) {
                    Image(systemName: "plus.circle.fill")
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            ExpenseGroupFormSheet(group: nil, sources: sources) { name, icon, colorHex, groupType, sourceID in
                addGroup(name: name, icon: icon, colorHex: colorHex, groupType: groupType, defaultSourceID: sourceID)
            }
        }
        .sheet(item: $editingGroup) { group in
            ExpenseGroupFormSheet(group: group, sources: sources) { name, icon, colorHex, groupType, sourceID in
                updateGroup(group, name: name, icon: icon, colorHex: colorHex, groupType: groupType, defaultSourceID: sourceID)
            }
        }
    }
    
    // MARK: - Group Row
    
    private func groupRow(_ group: ExpenseGroup) -> some View {
        HStack(spacing: 12) {
            Image(systemName: group.icon)
                .font(.title3)
                .foregroundStyle(Color(hex: group.colorHex))
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(group.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack(spacing: 6) {
                    Text(group.type == .daily ? "Daily (ad-hoc)" : "Recurring (monthly)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    // Show default source if set
                    if let sourceID = group.defaultPaymentSourceID,
                       let source = sources.first(where: { $0.id.uuidString == sourceID }) {
                        HStack(spacing: 3) {
                            Image(systemName: source.icon)
                                .font(.caption2)
                            Text(source.name)
                                .font(.caption)
                        }
                        .foregroundStyle(Color(hex: source.colorHex))
                    }
                }
            }
            
            Spacer()
            
            Toggle("", isOn: Binding(
                get: { group.isVisible },
                set: { newValue in
                    group.isVisible = newValue
                    try? modelContext.save()
                }
            ))
            .labelsHidden()
        }
    }
    
    // MARK: - Actions
    
    private func addGroup(name: String, icon: String, colorHex: String, groupType: String, defaultSourceID: String?) {
        let group = ExpenseGroup(
            name: name,
            icon: icon,
            colorHex: colorHex,
            sortOrder: groups.count,
            groupType: groupType,
            isDefault: false,
            isVisible: true,
            defaultPaymentSourceID: defaultSourceID
        )
        modelContext.insert(group)
        try? modelContext.save()
    }
    
    private func updateGroup(_ group: ExpenseGroup, name: String, icon: String, colorHex: String, groupType: String, defaultSourceID: String?) {
        group.name = name
        group.icon = icon
        group.colorHex = colorHex
        group.groupType = groupType
        group.defaultPaymentSourceID = defaultSourceID
        try? modelContext.save()
    }
    
    private func moveGroup(from offsets: IndexSet, to destination: Int) {
        var items = groups.sorted { $0.sortOrder < $1.sortOrder }
        items.move(fromOffsets: offsets, toOffset: destination)
        for (index, item) in items.enumerated() {
            item.sortOrder = index
        }
        try? modelContext.save()
    }
}

// MARK: - Add/Edit Form Sheet

struct ExpenseGroupFormSheet: View {
    
    let group: ExpenseGroup?
    let sources: [PaymentSource]
    let onSave: (String, String, String, String, String?) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var selectedIcon = "folder.fill"
    @State private var selectedColor = "#636e72"
    @State private var selectedType = "recurring"
    @State private var selectedSourceID: String? = nil
    
    private let iconOptions = [
        "house.fill", "car.fill", "shield.fill", "cart.fill",
        "person.2.fill", "chart.line.uptrend.xyaxis", "star.fill",
        "airplane", "gift.fill", "heart.fill", "book.fill",
        "briefcase.fill", "fork.knife", "tshirt.fill",
        "wrench.fill", "phone.fill", "wifi", "bolt.fill",
    ]
    
    private let colorOptions = [
        "#FF6B6B", "#0984e3", "#00b894", "#6c5ce7",
        "#e17055", "#fdcb6e", "#b2bec3", "#d63031",
        "#00cec9", "#a29bfe", "#55efc4", "#ff78c4",
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("e.g., Housing, Medical", text: $name)
                }
                
                Section("Type") {
                    Picker("Group Type", selection: $selectedType) {
                        Text("Recurring (monthly fixed)").tag("recurring")
                        Text("Daily (ad-hoc)").tag("daily")
                    }
                    .pickerStyle(.segmented)
                }
                
                // ── Default Payment Source ──
                Section {
                    Picker("Default Source", selection: $selectedSourceID) {
                        Text("None").tag(nil as String?)
                        ForEach(sources, id: \.id) { source in
                            HStack(spacing: 6) {
                                Image(systemName: source.icon)
                                Text(source.name)
                            }
                            .tag(source.id.uuidString as String?)
                        }
                    }
                } header: {
                    Text("Default Payment Source")
                } footer: {
                    Text("New expenses in this group will auto-select this payment source")
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
                                .onTapGesture { selectedColor = color }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle(group == nil ? "Add Group" : "Edit Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(name, selectedIcon, selectedColor, selectedType, selectedSourceID)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if let group = group {
                    name = group.name
                    selectedIcon = group.icon
                    selectedColor = group.colorHex
                    selectedType = group.groupType
                    selectedSourceID = group.defaultPaymentSourceID
                }
            }
        }
    }
}
