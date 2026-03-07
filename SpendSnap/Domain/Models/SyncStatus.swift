// Domain/Models/SyncStatus.swift
// SpendSnap

import Foundation

/// Tracks the sync state of each record for future cloud integration (Phase 3).
/// Designed to be extensible — add more cases as sync logic evolves.
enum SyncStatus: String, Codable, CaseIterable {
    case local           // Saved locally only
    case pendingUpload   // Queued for cloud upload
    case synced          // Successfully synced to cloud
}
