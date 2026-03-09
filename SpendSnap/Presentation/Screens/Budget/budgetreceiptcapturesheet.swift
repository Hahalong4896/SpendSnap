// Presentation/Screens/Budget/BudgetReceiptCaptureSheet.swift
// SpendSnap

import SwiftUI
import SwiftData
import PhotosUI

/// Receipt capture flow for budget items (groceries, petrol, etc.)
/// Similar to ExpenseEntryScreen but saves as MonthlyExpenseEntry
/// linked to an ExpenseGroup instead of a daily expense Category.
struct BudgetReceiptCaptureSheet: View {
    
    // MARK: - Environment
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Properties
    
    let group: ExpenseGroup
    let month: Int
    let year: Int
    
    @Query(
        filter: #Predicate<PaymentSource> { $0.isActive },
        sort: \PaymentSource.sortOrder
    ) private var sources: [PaymentSource]
    
    // MARK: - State
    
    @StateObject private var cameraService = CameraService()
    @State private var showCamera = false
    @State private var capturedImage: UIImage?
    @State private var showImagePicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    
    @State private var name = ""
    @State private var amountString = ""
    @State private var selectedCurrency: Currency = .sgd
    @State private var selectedSource: PaymentSource?
    @State private var vendor = ""
    @State private var note = ""
    @State private var isSaving = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // ── Photo Section ──
                    photoSection
                    
                    if !showCamera {
                        formSection
                    }
                }
            }
            .navigationTitle("Add to \(group.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        cameraService.stopSession()
                        dismiss()
                    }
                }
            }
            .onChange(of: cameraService.capturedImage) { _, newImage in
                if let image = newImage {
                    capturedImage = image
                    showCamera = false
                    cameraService.stopSession()
                }
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                loadSelectedPhoto(newItem)
            }
            .photosPicker(isPresented: $showImagePicker,
                         selection: $selectedPhotoItem,
                         matching: .images)
            .onAppear {
                // Auto-select group's default payment source
                if let sourceID = group.defaultPaymentSourceID {
                    selectedSource = sources.first { $0.id.uuidString == sourceID }
                }
            }
            .onDisappear {
                cameraService.stopSession()
            }
        }
    }
    
    // MARK: - Photo Section
    
    @ViewBuilder
    private var photoSection: some View {
        if showCamera {
            ZStack(alignment: .bottom) {
                CameraPreviewView(session: cameraService.session)
                    .frame(maxWidth: .infinity)
                    .frame(height: UIScreen.main.bounds.height * 0.45)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                
                HStack(spacing: 40) {
                    Button(action: { showImagePicker = true }) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .frame(width: 50, height: 50)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    
                    Button(action: { cameraService.capturePhoto() }) {
                        Circle()
                            .fill(.white)
                            .frame(width: 72, height: 72)
                            .overlay(
                                Circle()
                                    .stroke(.white.opacity(0.5), lineWidth: 4)
                                    .frame(width: 82, height: 82)
                            )
                    }
                    
                    Button(action: {
                        showCamera = false
                        cameraService.stopSession()
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: "forward.fill")
                                .font(.title3)
                            Text("Skip")
                                .font(.caption2)
                        }
                        .foregroundStyle(.white)
                        .frame(width: 50, height: 50)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                    }
                }
                .padding(.bottom, 24)
            }
        } else if let image = capturedImage {
            ZStack(alignment: .topTrailing) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                
                Menu {
                    Button(action: retakePhoto) {
                        Label("Retake Photo", systemImage: "camera")
                    }
                    Button(action: { showImagePicker = true }) {
                        Label("Choose from Library", systemImage: "photo.on.rectangle")
                    }
                    Button(action: { capturedImage = nil }) {
                        Label("Remove Photo", systemImage: "xmark.circle")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle.fill")
                        .font(.title2)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, .black.opacity(0.5))
                }
                .padding(.top, 12)
                .padding(.trailing, 24)
            }
        } else {
            // No photo — show options
            HStack(spacing: 20) {
                Button(action: retakePhoto) {
                    VStack(spacing: 6) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 24))
                        Text("Camera")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .frame(width: 80, height: 60)
                    .background(Color.blue.opacity(0.15))
                    .foregroundStyle(.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                Button(action: { showImagePicker = true }) {
                    VStack(spacing: 6) {
                        Image(systemName: "photo.fill")
                            .font(.system(size: 24))
                        Text("Library")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .frame(width: 80, height: 60)
                    .background(Color.green.opacity(0.15))
                    .foregroundStyle(.green)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
        }
    }
    
    // MARK: - Form Section
    
    private var formSection: some View {
        VStack(spacing: 16) {
            // Name
            VStack(alignment: .leading, spacing: 6) {
                sectionLabel("Item Name")
                TextField("e.g., Petrol Shell, NTUC Groceries", text: $name)
                    .font(.body)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .padding(.horizontal)
            
            // Amount + Currency
            VStack(alignment: .leading, spacing: 6) {
                sectionLabel("Amount")
                HStack(spacing: 10) {
                    // Currency button
                    Menu {
                        ForEach(Currency.allCases, id: \.self) { cur in
                            Button(action: { selectedCurrency = cur }) {
                                Text("\(cur.flag) \(cur.rawValue)")
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(selectedCurrency.flag)
                            Text(selectedCurrency.rawValue)
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 10)
                        .background(Color(.systemGray5))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    
                    TextField("0.00", text: $amountString)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
            }
            .padding(.horizontal)
            
            // Payment Source
            if !sources.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    sectionLabel("Paid Via")
                    PaymentSourcePicker(sources: sources, selected: $selectedSource)
                }
                .padding(.horizontal)
            }
            
            // Vendor
            VStack(alignment: .leading, spacing: 6) {
                sectionLabel("Shop / Station (Optional)")
                TextField("e.g., Shell Jurong, FairPrice", text: $vendor)
                    .font(.body)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .padding(.horizontal)
            
            // Note
            VStack(alignment: .leading, spacing: 6) {
                sectionLabel("Note (Optional)")
                TextField("Note", text: $note)
                    .font(.body)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .padding(.horizontal)
            
            // Save Button
            Button(action: save) {
                HStack {
                    if isSaving {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Save")
                    }
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(canSave ? Color.blue : Color.gray.opacity(0.4))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(!canSave || isSaving)
            .padding(.horizontal)
            .padding(.bottom, 30)
        }
    }
    
    // MARK: - Helpers
    
    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
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
    
    private func retakePhoto() {
        capturedImage = nil
        showCamera = true
        cameraService.resetCapture()
        cameraService.checkPermissionAndSetup()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            cameraService.startSession()
        }
    }
    
    private func loadSelectedPhoto(_ item: PhotosPickerItem?) {
        guard let item = item else { return }
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    capturedImage = image
                    showCamera = false
                    cameraService.stopSession()
                }
            }
        }
    }
    
    private func save() {
        guard let amount = Decimal(string: amountString), amount > 0 else { return }
        isSaving = true
        
        // Save photo if captured
        var photoFile: String? = nil
        if let image = capturedImage {
            photoFile = try? PhotoStorageService.savePhoto(image)
        }
        
        let entry = MonthlyExpenseEntry(
            name: name,
            amount: amount,
            currency: selectedCurrency.rawValue,
            month: month,
            year: year,
            isPaid: true,
            paidDate: Date(),
            expenseGroup: group,
            paymentSource: selectedSource,
            note: note.isEmpty ? nil : note,
            photoFileName: photoFile,
            vendor: vendor.isEmpty ? nil : vendor
        )
        modelContext.insert(entry)
        try? modelContext.save()
        
        cameraService.stopSession()
        dismiss()
    }
}
