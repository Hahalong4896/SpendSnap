// Presentation/Screens/Camera/CameraPreviewView.swift
// SpendSnap

import SwiftUI
import AVFoundation

/// UIViewRepresentable wrapper for AVCaptureVideoPreviewLayer.
/// Displays the live camera feed in a SwiftUI view.
struct CameraPreviewView: UIViewRepresentable {
    
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> VideoPreviewUIView {
        let view = VideoPreviewUIView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }
    
    func updateUIView(_ uiView: VideoPreviewUIView, context: Context) {
        // No updates needed — session handles everything
    }
}

/// Custom UIView subclass that uses AVCaptureVideoPreviewLayer as its layer.
class VideoPreviewUIView: UIView {
    
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }
    
    var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }
}
