// Presentation/Screens/Budget/GroceryEntrySheet.swift
// SpendSnap

import SwiftUI
import SwiftData
import PhotosUI

/// Grocery purchase entry screen with receipt capture.
struct GroceryEntrySheet: View {
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let group: ExpenseGroup
    let month: Int
    let year: Int
    
    @Query(filter: #Predicate<PaymentSource> { $0.isActive }, sort: \PaymentSource.sortOrder) private var sources: [PaymentSource]
    
    @StateObject private var cameraService = CameraService()
    @State private var capturedImage: UIImage?
    @State private var showCamera = false
    @State private var showImagePicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    
    @State private var shopName = ""
    @State private var amountString = ""
    @State private var selectedCurrency: Currency = .sgd
    @State private var itemList = ""
    @State private var selectedSource: PaymentSource?
    @State private var note = ""
    @State private var entryDate: Date = Date()
    @State private var isSaving = false
    
    private var canSave: Bool { !amountString.isEmpty && (Decimal(string: amountString) ?? 0) > 0 }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    photoSection
                    if !showCamera { formSection }
                }
            }
            .navigationTitle("Add Grocery").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { cameraService.stopSession(); dismiss() } } }
            .onChange(of: cameraService.capturedImage) { _, img in
                if let img { capturedImage = img; showCamera = false; cameraService.stopSession() }
            }
            .onChange(of: selectedPhotoItem) { _, item in loadPhoto(item) }
            .photosPicker(isPresented: $showImagePicker, selection: $selectedPhotoItem, matching: .images)
            .onAppear {
                if let sid = group.defaultPaymentSourceID { selectedSource = sources.first { $0.id.uuidString == sid } }
            }
            .onDisappear { cameraService.stopSession() }
        }
    }
    
    @ViewBuilder
    private var photoSection: some View {
        if showCamera {
            ZStack(alignment: .bottom) {
                CameraPreviewView(session: cameraService.session)
                    .frame(maxWidth: .infinity).frame(height: UIScreen.main.bounds.height * 0.40)
                    .clipShape(RoundedRectangle(cornerRadius: 16)).padding(.horizontal)
                HStack(spacing: 40) {
                    Button(action: { showImagePicker = true }) {
                        Image(systemName: "photo.on.rectangle").font(.title2).foregroundStyle(.white)
                            .frame(width: 50, height: 50).background(.ultraThinMaterial).clipShape(Circle())
                    }
                    Button(action: { cameraService.capturePhoto() }) {
                        Circle().fill(.white).frame(width: 72, height: 72)
                            .overlay(Circle().stroke(.white.opacity(0.5), lineWidth: 4).frame(width: 82, height: 82))
                    }
                    Button(action: { showCamera = false; cameraService.stopSession() }) {
                        VStack(spacing: 4) { Image(systemName: "forward.fill").font(.title3); Text("Skip").font(.caption2) }
                            .foregroundStyle(.white).frame(width: 50, height: 50).background(.ultraThinMaterial).clipShape(Circle())
                    }
                }.padding(.bottom, 24)
            }
        } else if let image = capturedImage {
            ZStack(alignment: .topTrailing) {
                Image(uiImage: image).resizable().scaledToFill().frame(height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: 16)).padding(.horizontal)
                Button(action: retakePhoto) {
                    Image(systemName: "camera.rotate.fill").font(.title3).foregroundStyle(.white)
                        .padding(10).background(.black.opacity(0.5)).clipShape(Circle())
                }.padding(.top, 12).padding(.trailing, 24)
            }
        } else {
            HStack(spacing: 20) {
                Button(action: retakePhoto) {
                    VStack(spacing: 4) { Image(systemName: "camera.fill").font(.system(size: 22)); Text("Receipt").font(.caption).fontWeight(.semibold) }
                        .frame(width: 80, height: 56).background(Color.blue.opacity(0.15)).foregroundStyle(.blue).clipShape(RoundedRectangle(cornerRadius: 12))
                }
                Button(action: { showImagePicker = true }) {
                    VStack(spacing: 4) { Image(systemName: "photo.fill").font(.system(size: 22)); Text("Library").font(.caption).fontWeight(.semibold) }
                        .frame(width: 80, height: 56).background(Color.green.opacity(0.15)).foregroundStyle(.green).clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }.frame(maxWidth: .infinity).padding(.vertical, 12)
        }
    }
    
    private var formSection: some View {
        VStack(spacing: 14) {
            fieldSection("Shop") {
                TextField("e.g., FairPrice, Giant, Cold Storage", text: $shopName)
                    .font(.body).padding(12).background(Color(.systemGray6)).clipShape(RoundedRectangle(cornerRadius: 8))
            }
            fieldSection("Amount") {
                HStack(spacing: 10) {
                    Menu {
                        ForEach(Currency.allCases, id: \.self) { cur in
                            Button(action: { selectedCurrency = cur }) { Text("\(cur.flag) \(cur.rawValue)") }
                        }
                    } label: {
                        HStack(spacing: 4) { Text(selectedCurrency.flag); Text(selectedCurrency.rawValue).font(.caption).fontWeight(.semibold) }
                            .padding(.horizontal, 10).padding(.vertical, 10).background(Color(.systemGray5)).clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    TextField("0.00", text: $amountString)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                }
            }
            fieldSection("Items Purchased") {
                TextEditor(text: $itemList).font(.body).frame(minHeight: 80).padding(8)
                    .background(Color(.systemGray6)).clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(Group {
                        if itemList.isEmpty {
                            Text("e.g., Milk, Bread, Eggs...").foregroundStyle(.tertiary)
                                .padding(.horizontal, 12).padding(.vertical, 16)
                        }
                    }, alignment: .topLeading)
            }
            
            // Date picker
            fieldSection("Date") {
                DatePicker("", selection: $entryDate, displayedComponents: .date)
                    .labelsHidden().frame(maxWidth: .infinity, alignment: .leading)
            }
            
            if !sources.isEmpty {
                fieldSection("Paid Via") { PaymentSourcePicker(sources: sources, selected: $selectedSource) }
            }
            fieldSection("Note (Optional)") {
                TextField("Optional note", text: $note)
                    .font(.body).padding(12).background(Color(.systemGray6)).clipShape(RoundedRectangle(cornerRadius: 8))
            }
            Button(action: save) {
                HStack {
                    if isSaving { ProgressView().tint(.white) }
                    else { Image(systemName: "basket.fill"); Text("Save Grocery Entry") }
                }
                .font(.headline).foregroundStyle(.white).frame(maxWidth: .infinity).padding(.vertical, 16)
                .background(canSave ? Color(hex: "#48DBFB") : Color.gray.opacity(0.4))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(!canSave || isSaving).padding(.horizontal).padding(.bottom, 30)
        }
    }
    
    private func fieldSection<C: View>(_ label: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.subheadline).fontWeight(.semibold).foregroundStyle(.secondary).padding(.horizontal, 4)
            content()
        }.padding(.horizontal)
    }
    private func retakePhoto() {
        capturedImage = nil; showCamera = true; cameraService.resetCapture(); cameraService.checkPermissionAndSetup()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { cameraService.startSession() }
    }
    private func loadPhoto(_ item: PhotosPickerItem?) {
        guard let item else { return }
        Task { if let d = try? await item.loadTransferable(type: Data.self), let img = UIImage(data: d) {
            await MainActor.run { capturedImage = img; showCamera = false; cameraService.stopSession() } } }
    }
    
    private func save() {
        guard let amount = Decimal(string: amountString), amount > 0 else { return }
        isSaving = true
        var photoFile: String? = nil
        if let img = capturedImage { photoFile = try? PhotoStorageService.savePhoto(img) }
        let entry = MonthlyExpenseEntry(
            name: shopName.isEmpty ? "Groceries" : shopName,
            amount: amount, currency: selectedCurrency.rawValue,
            month: month, year: year, isPaid: true, paidDate: entryDate,
            expenseGroup: group, paymentSource: selectedSource,
            note: note.isEmpty ? nil : note, photoFileName: photoFile,
            vendor: shopName.isEmpty ? nil : shopName, entryType: "grocery",
            itemNotes: itemList.isEmpty ? nil : itemList, createdAt: entryDate
        )
        modelContext.insert(entry); try? modelContext.save()
        cameraService.stopSession(); dismiss()
    }
}
