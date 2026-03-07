// Infrastructure/Camera/CameraService.swift
// SpendSnap

import AVFoundation
import UIKit

/// AVFoundation camera wrapper providing live preview and photo capture.
/// Designed as ObservableObject for SwiftUI integration.
///
/// Usage:
///   1. Call startSession() when camera view appears
///   2. Use previewLayer for live camera feed
///   3. Call capturePhoto() to take a photo
///   4. Observe capturedImage for the result
///
final class CameraService: NSObject, ObservableObject {
    
    // MARK: - Published State
    
    @Published var capturedImage: UIImage?
    @Published var isSessionRunning = false
    @Published var showAlert = false
    @Published var alertMessage = ""
    
    // MARK: - AVFoundation Properties
    
    let session = AVCaptureSession()
    private let output = AVCapturePhotoOutput()
    private var currentDevice: AVCaptureDevice?
    private var isCaptureInProgress = false
    
    
    // MARK: - Session Setup
    
    /// Checks camera authorisation and configures the capture session.
    func checkPermissionAndSetup() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    DispatchQueue.main.async {
                        self?.setupSession()
                    }
                } else {
                    DispatchQueue.main.async {
                        self?.alertMessage = "Camera access is required to capture expense photos."
                        self?.showAlert = true
                    }
                }
            }
        case .denied, .restricted:
            DispatchQueue.main.async {
                self.alertMessage = "Camera access denied. Please enable it in Settings > SpendSnap."
                self.showAlert = true
            }
        @unknown default:
            break
        }
    }
    
    private func setupSession() {
        session.beginConfiguration()
        session.sessionPreset = .photo
        
        // Add camera input
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            alertMessage = "No camera available on this device."
            showAlert = true
            session.commitConfiguration()
            return
        }
        
        currentDevice = device
        
        do {
            let input = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(input) {
                session.addInput(input)
            }
        } catch {
            alertMessage = "Failed to access camera: \(error.localizedDescription)"
            showAlert = true
            session.commitConfiguration()
            return
        }
        
        // Add photo output
        if session.canAddOutput(output) {
            session.addOutput(output)
        }
        
        session.commitConfiguration()
    }
    
    // MARK: - Session Control
    
    /// Start the camera session on a background thread.
    func startSession() {
        guard !session.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.startRunning()
            DispatchQueue.main.async {
                self?.isSessionRunning = self?.session.isRunning ?? false
            }
        }
    }
    
    /// Stop the camera session.
    func stopSession() {
        guard session.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.stopRunning()
            DispatchQueue.main.async {
                self?.isSessionRunning = false
            }
        }
    }
    
    // MARK: - Photo Capture
    
    /// Capture a photo. Result delivered via capturedImage published property.

    func capturePhoto() {
        guard !isCaptureInProgress else { return }
        isCaptureInProgress = true
        let settings = AVCapturePhotoSettings()
        output.capturePhoto(with: settings, delegate: self)
    }
    
    /// Reset captured image to allow retaking.
    func resetCapture() {
        capturedImage = nil
        isCaptureInProgress = false 
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension CameraService: AVCapturePhotoCaptureDelegate {
    
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        
        if let error = error {
            DispatchQueue.main.async {
                self.alertMessage = "Photo capture failed: \(error.localizedDescription)"
                self.showAlert = true
                self.isCaptureInProgress = false
            }
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            DispatchQueue.main.async {
                self.alertMessage = "Failed to process captured photo."
                self.showAlert = true
            }
            return
        }
        
        DispatchQueue.main.async {
            self.capturedImage = image
            self.isCaptureInProgress = false
        }
    }
}
