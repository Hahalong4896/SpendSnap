// Infrastructure/PhotoStorage/PhotoStorageService.swift
// SpendSnap

import UIKit

/// Manages photo storage in the app's local Documents directory.
/// Photos are saved as compressed JPEG files with unique filenames.
///
/// File naming: "expense_{UUID}.jpg"
/// Storage location: Documents/ExpensePhotos/
///
struct PhotoStorageService {
    
    // MARK: - Configuration
    
    /// Subdirectory within Documents for expense photos
    private static let photoDirectory = "ExpensePhotos"
    
    /// JPEG compression quality (0.0 to 1.0)
    /// 0.7 provides good balance of quality and file size (~200-400KB per photo)
    private static let compressionQuality: CGFloat = 0.7
    
    // MARK: - Directory Management
    
    /// Returns the URL for the photo storage directory, creating it if needed.
    private static func photoDirectoryURL() throws -> URL {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let photosURL = documentsURL.appendingPathComponent(photoDirectory)
        
        if !FileManager.default.fileExists(atPath: photosURL.path) {
            try FileManager.default.createDirectory(at: photosURL, withIntermediateDirectories: true)
        }
        
        return photosURL
    }
    
    // MARK: - Save
    
    /// Saves a UIImage to disk and returns the filename.
    /// - Parameter image: The photo to save.
    /// - Returns: The filename (not full path) for storage in the Expense model.
    @discardableResult
    static func savePhoto(_ image: UIImage) throws -> String {
        let fileName = "expense_\(UUID().uuidString).jpg"
        let directoryURL = try photoDirectoryURL()
        let fileURL = directoryURL.appendingPathComponent(fileName)
        
        guard let data = image.jpegData(compressionQuality: compressionQuality) else {
            throw PhotoStorageError.compressionFailed
        }
        
        try data.write(to: fileURL)
        return fileName
    }
    
    // MARK: - Load
    
    /// Loads a photo from disk by filename.
    /// - Parameter fileName: The filename stored in the Expense model.
    /// - Returns: The loaded UIImage, or nil if not found.
    static func loadPhoto(named fileName: String) -> UIImage? {
        guard let directoryURL = try? photoDirectoryURL() else { return nil }
        let fileURL = directoryURL.appendingPathComponent(fileName)
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return UIImage(data: data)
    }
    
    // MARK: - Delete
    
    /// Deletes a photo from disk.
    /// - Parameter fileName: The filename to delete.
    static func deletePhoto(named fileName: String) {
        guard let directoryURL = try? photoDirectoryURL() else { return }
        let fileURL = directoryURL.appendingPathComponent(fileName)
        try? FileManager.default.removeItem(at: fileURL)
    }
    
    // MARK: - Thumbnail
    
    /// Creates a smaller thumbnail version of an image for list display.
    /// - Parameters:
    ///   - image: The original image.
    ///   - maxDimension: Maximum width or height in points (default: 200).
    /// - Returns: A resized UIImage.
    static func createThumbnail(from image: UIImage, maxDimension: CGFloat = 200) -> UIImage {
        let scale = min(maxDimension / image.size.width, maxDimension / image.size.height)
        
        // Don't upscale small images
        guard scale < 1.0 else { return image }
        
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

// MARK: - Errors

enum PhotoStorageError: LocalizedError {
    case compressionFailed
    case saveFailed
    
    var errorDescription: String? {
        switch self {
        case .compressionFailed: return "Failed to compress photo."
        case .saveFailed: return "Failed to save photo to disk."
        }
    }
}
