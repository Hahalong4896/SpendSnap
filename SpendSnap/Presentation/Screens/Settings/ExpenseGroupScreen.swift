// Presentation/Screens/Settings/ExpenseGroupScreen.swift
// SpendSnap

import SwiftUI
import SwiftData

struct ExpenseGroupScreen: View {
    
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ExpenseGroup.sortOrder) private var groups: [ExpenseGroup]
    @Query(filter: #Predicate<PaymentSource> { $0.isActive }, sort: \PaymentSource.sortOrder) private var sources: [PaymentSource]
    
    @State private var showAddSheet = false
    @State private var editingGroup: ExpenseGroup?
    
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
                Button(action: { showAddSheet = true }) { Image(systemName: "plus.circle.fill") }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            ExpenseGroupFormSheet(group: nil, sources: sources) { data in
                addGroup(data)
            }
        }
        .sheet(item: $editingGroup) { group in
            ExpenseGroupFormSheet(group: group, sources: sources) { data in
                updateGroup(group, with: data)
            }
        }
    }
    
    private func groupRow(_ group: ExpenseGroup) -> some View {
        HStack(spacing: 12) {
            Image(systemName: group.icon)
                .font(.title3).foregroundStyle(Color(hex: group.colorHex))
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(group.name).font(.subheadline).fontWeight(.medium)
                HStack(spacing: 6) {
                    Text(group.type == .daily ? "Daily (ad-hoc)" : "Recurring (monthly)")
                        .font(.caption).foregroundStyle(.secondary)
                    if group.hasItemisedEntries {
                        Text("+ Itemised").font(.caption2)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color(hex: group.colorHex).opacity(0.15))
                            .foregroundStyle(Color(hex: group.colorHex))
                            .clipShape(Capsule())
                    }
                    if let sid = group.defaultPaymentSourceID,
                       let src = sources.first(where: { $0.id.uuidString == sid }) {
                        HStack(spacing: 3) {
                            Image(systemName: src.icon).font(.caption2)
                            Text(src.name).font(.caption)
                        }.foregroundStyle(Color(hex: src.colorHex))
                    }
                }
            }
            Spacer()
            Toggle("", isOn: Binding(
                get: { group.isVisible },
                set: { group.isVisible = $0; try? modelContext.save() }
            )).labelsHidden()
        }
    }
    
    private func addGroup(_ data: GroupFormData) {
        let g = ExpenseGroup(name: data.name, icon: data.icon, colorHex: data.colorHex,
            sortOrder: groups.count, groupType: data.groupType, isDefault: false, isVisible: true,
            defaultPaymentSourceID: data.defaultSourceID, hasItemisedEntries: data.hasItemised)
        modelContext.insert(g); try? modelContext.save()
    }
    
    private func updateGroup(_ group: ExpenseGroup, with data: GroupFormData) {
        group.name = data.name; group.icon = data.icon; group.colorHex = data.colorHex
        group.groupType = data.groupType; group.defaultPaymentSourceID = data.defaultSourceID
        group.hasItemisedEntries = data.hasItemised
        try? modelContext.save()
    }
    
    private func moveGroup(from offsets: IndexSet, to destination: Int) {
        var items = groups.sorted { $0.sortOrder < $1.sortOrder }
        items.move(fromOffsets: offsets, toOffset: destination)
        for (i, item) in items.enumerated() { item.sortOrder = i }
        try? modelContext.save()
    }
}

// MARK: - Form Data

struct GroupFormData {
    var name: String
    var icon: String
    var colorHex: String
    var groupType: String
    var defaultSourceID: String?
    var hasItemised: Bool
}

// MARK: - Form Sheet

struct ExpenseGroupFormSheet: View {
    let group: ExpenseGroup?
    let sources: [PaymentSource]
    let onSave: (GroupFormData) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var selectedIcon = "folder.fill"
    @State private var selectedColor = "#636e72"
    @State private var selectedType = "recurring"
    @State private var selectedSourceID: String? = nil
    @State private var hasItemised = false
    
    private let iconOptions = [
        "house.fill", "car.fill", "shield.fill", "cart.fill",
        "basket.fill", "person.2.fill", "chart.line.uptrend.xyaxis", "star.fill",
        "airplane", "gift.fill", "heart.fill", "book.fill",
        "briefcase.fill", "fork.knife", "tshirt.fill",
        "wrench.fill", "phone.fill", "wifi", "bolt.fill", "fuelpump.fill",
    ]
    private let colorOptions = [
        "#FF6B6B", "#0984e3", "#00b894", "#6c5ce7",
        "#e17055", "#fdcb6e", "#b2bec3", "#d63031",
        "#00cec9", "#a29bfe", "#55efc4", "#ff78c4", "#48DBFB",
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("e.g., Housing, Groceries", text: $name)
                }
                Section("Type") {
                    Picker("Group Type", selection: $selectedType) {
                        Text("Recurring (monthly fixed)").tag("recurring")
                        Text("Daily (ad-hoc)").tag("daily")
                    }.pickerStyle(.segmented)
                }
                Section {
                    Picker("Default Source", selection: $selectedSourceID) {
                        Text("None").tag(nil as String?)
                        ForEach(sources, id: \.id) { s in
                            HStack(spacing: 6) { Image(systemName: s.icon); Text(s.name) }
                                .tag(s.id.uuidString as String?)
                        }
                    }
                } header: { Text("Default Payment Source") }
                footer: { Text("New expenses in this group auto-select this source") }
                
                Section {
                    Toggle("Enable Itemised Entries", isOn: $hasItemised)
                } header: { Text("Itemised Tracking") }
                footer: { Text("Turn on for groups like Transport (petrol) or Groceries where individual purchases are tracked with receipts") }
                
                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(iconOptions, id: \.self) { icon in
                            Image(systemName: icon).font(.title3)
                                .frame(width: 40, height: 40)
                                .background(selectedIcon == icon ? Color(hex: selectedColor).opacity(0.2) : Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(selectedIcon == icon ? Color(hex: selectedColor) : .clear, lineWidth: 2))
                                .onTapGesture { selectedIcon = icon }
                        }
                    }.padding(.vertical, 4)
                }
                Section("Colour") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(colorOptions, id: \.self) { color in
                            Circle().fill(Color(hex: color)).frame(width: 36, height: 36)
                                .overlay(Circle().stroke(.white, lineWidth: selectedColor == color ? 3 : 0))
                                .onTapGesture { selectedColor = color }
                        }
                    }.padding(.vertical, 4)
                }
            }
            .navigationTitle(group == nil ? "Add Group" : "Edit Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(GroupFormData(name: name, icon: selectedIcon, colorHex: selectedColor,
                            groupType: selectedType, defaultSourceID: selectedSourceID, hasItemised: hasItemised))
                        dismiss()
                    }.disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if let g = group {
                    name = g.name; selectedIcon = g.icon; selectedColor = g.colorHex
                    selectedType = g.groupType; selectedSourceID = g.defaultPaymentSourceID
                    hasItemised = g.hasItemisedEntries
                }
            }
        }
    }
}
