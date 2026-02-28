//
//  Item.swift
//  SpendSnap
//
//  Created by Fong Cheng Loong on 28/2/26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
