// Presentation/Screens/ExpenseEntry/ExpenseEntryScreen.swift
// SpendSnap

import SwiftUI
import SwiftData
import PhotosUI

/// Main expense entry screen.
/// Flow: Camera capture (or photo library / skip) → Category selection → Amount entry → Save
struct ExpenseEntryScreen: View {
    
    // MARK: - Environment
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - State
    
    @State private var viewModel = ExpenseEntryViewModel()
    @StateObject private var cameraService = CameraService()
    @State private var showCamera = false
    @State private var showPhotoOptions = false
    @State private var showImagePicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedCurrency: Currency = .sgd
    @Query(
    filter: #Predicate<ExpenseGroup> { $0.groupType == "daily" && $0.isVisible },
    sort: \ExpenseGroup.sortOrder
    ) private var dailyGroups: [ExpenseGroup]
    
    @Query(
    filter: #Predicate<PaymentSource> { $0.isActive },
    sort: \PaymentSource.sortOrder
    ) private var paymentSources: [PaymentSource]
    
    @State private var selectedPaymentSource: PaymentSource?
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollViewReader { scrollProxy in
                ScrollView {
                    VStack(spacing: 20) {
                        
                        // ── Photo Section ──
                        photoSection
                        
                        if !showCamera {
                            formSection
                                .id("formSection")
                            
                            
                        }
                    }
                }
                .onChange(of: viewModel.selectedCategory) { _, newCategory in
                    if newCategory != nil {
                        // Auto-scroll to amount when category is selected
                        withAnimation {
                            scrollProxy.scrollTo("amountSection", anchor: .top)
                        }
                    }
                }
            }
            .navigationTitle("New Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") { }
            } message: {
                Text(viewModel.errorMessage)
            }
            .onChange(of: viewModel.didSaveSuccessfully) { _, success in
                if success { dismiss() }
            }
            .onChange(of: cameraService.capturedImage) { _, newImage in
                if let image = newImage {
                    viewModel.capturedImage = image
                    showCamera = false
                    cameraService.stopSession()
                    viewModel.detectLocation()
                }
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                loadSelectedPhoto(newItem)
            }
            .photosPicker(isPresented: $showImagePicker,
                         selection: $selectedPhotoItem,
                         matching: .images)
            .onDisappear {
                cameraService.stopSession()
            }
            
            .onAppear {
            // Auto-select default payment source from Daily Expense group
            if selectedPaymentSource == nil,
            let dailyGroup = dailyGroups.first,
            let sourceID = dailyGroup.defaultPaymentSourceID {
            selectedPaymentSource = paymentSources.first { $0.id.uuidString == sourceID }
            }
            }
        }
    }
    
    // MARK: - Photo Section
    
    @ViewBuilder
    private var photoSection: some View {
        if showCamera {
            // Live camera preview
            ZStack(alignment: .bottom) {
                CameraPreviewView(session: cameraService.session)
                    .frame(maxWidth: .infinity)
                    .frame(height: UIScreen.main.bounds.height * 0.55)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                
                // Bottom controls
                HStack(spacing: 40) {
                    // Photo library
                    Button(action: { showImagePicker = true }) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .frame(width: 50, height: 50)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    
                    // Capture
                    Button(action: capturePhoto) {
                        Circle()
                            .fill(.white)
                            .frame(width: 72, height: 72)
                            .overlay(
                                Circle()
                                    .stroke(.white.opacity(0.5), lineWidth: 4)
                                    .frame(width: 82, height: 82)
                            )
                    }
                    
                    // Skip photo
                    Button(action: skipPhoto) {
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
            .alert("Camera", isPresented: $cameraService.showAlert) {
                Button("OK") { }
            } message: {
                Text(cameraService.alertMessage)
            }
        } else if let image = viewModel.capturedImage {
            // Photo preview (after capture or selection)
            ZStack(alignment: .topTrailing) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                
                // Retake / change photo
                Menu {
                    Button(action: retakePhoto) {
                        Label("Retake Photo", systemImage: "camera")
                    }
                    Button(action: { showImagePicker = true }) {
                        Label("Choose from Library", systemImage: "photo.on.rectangle")
                    }
                    Button(action: removePhoto) {
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
            // No photo — show option to add one
            VStack(spacing: 12) {
                Image(systemName: "camera.badge.clock.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.secondary)
                Text("No photo")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 24) {
                    Button(action: retakePhoto) {
                        VStack(spacing: 6) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 28))
                            Text("Camera")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                        .frame(width: 90, height: 70)
                        .background(Color.blue.opacity(0.15))
                        .foregroundStyle(.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    Button(action: { showImagePicker = true }) {
                        VStack(spacing: 6) {
                            Image(systemName: "photo.fill")
                                .font(.system(size: 28))
                            Text("Library")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                        .frame(width: 90, height: 70)
                        .background(Color.green.opacity(0.15))
                        .foregroundStyle(.green)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 160)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)
        }
    }
    
    // MARK: - Form Section
    
    private var formSection: some View {
        VStack(spacing: 20) {
           

            // Location (auto-detected)
            HStack {
                Image(systemName: "location.fill")
                    .foregroundStyle(.blue)
                    .font(.caption)
                if let city = viewModel.locationCity {
                    let country = viewModel.locationCountry ?? ""
                    Text("\(city)\(country.isEmpty ? "" : ", \(country)")")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Detecting location...")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                }
                Spacer()
            }
            .padding(.top, 4)
            
            // ── Category Selection ──
            VStack(alignment: .leading, spacing: 8) {
                sectionLabel("Category")
                CategoryGridView(selectedCategory: $viewModel.selectedCategory)
            }
            .padding(.horizontal)
            
            // ── Amount Input ──
            VStack(alignment: .leading, spacing: 8) {
                sectionLabel("Amount")
                AmountInputView(amount: $viewModel.amountString, selectedCurrency: $selectedCurrency)
            }
            .padding(.horizontal)
            .id("amountSection")
            
            
            
            // ── Optional Fields ──
            VStack(alignment: .leading, spacing: 8) {
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
                
                sectionLabel("Details (Optional)")
                
                TextField("Vendor / Shop name", text: $viewModel.vendor)
                    .font(.body)
                    .padding(14)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(.systemGray4), lineWidth: 0.5))

                TextField("Notes", text: $viewModel.note)
                    .font(.body)
                    .padding(14)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(.systemGray4), lineWidth: 0.5))
                
                DatePicker("Date", selection: $viewModel.expenseDate, displayedComponents: .date)
            }
            .padding(.horizontal)
            
            // ── Save Button ──
            Button(action: save) {
                HStack {
                    if viewModel.isSaving {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Save Expense")
                    }
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(canSave ? Color.blue : Color.gray.opacity(0.4))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            
            
            .disabled(!canSave || viewModel.isSaving)
            .padding(.horizontal)
            .padding(.bottom, 30)
        }
    }
    
    // MARK: - Helpers
    
    /// Photo is now optional — only category and amount required
    private var canSave: Bool {
        viewModel.selectedCategory != nil
        && !viewModel.amountString.isEmpty
        && (Decimal(string: viewModel.amountString) ?? 0) > 0
    }
    
    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 4)
    }
    
    // MARK: - Actions
    
    private func capturePhoto() {
        cameraService.capturePhoto()
        viewModel.detectLocation()
    }
    
    private func retakePhoto() {
        viewModel.capturedImage = nil
        showCamera = true
        cameraService.resetCapture()
        cameraService.checkPermissionAndSetup()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            cameraService.startSession()
        }
    }
    
    private func removePhoto() {
        viewModel.capturedImage = nil
        // Stay on form, don't go back to camera
    }
    
    private func skipPhoto() {
        showCamera = false
        cameraService.stopSession()
        viewModel.detectLocation()
        // No image — user will enter expense without photo
    }
    
    private func loadSelectedPhoto(_ item: PhotosPickerItem?) {
        guard let item = item else { return }
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    viewModel.capturedImage = image
                    showCamera = false
                    viewModel.detectLocation()
                    cameraService.stopSession()
                }
            }
        }
    }
    
    private func save() {
        
        viewModel.currency = selectedCurrency.rawValue
        viewModel.selectedPaymentSource = selectedPaymentSource 
        viewModel.saveExpense(modelContext: modelContext)
        
    }
}
