//
//  Item.swift
//  bamboohr-ios
//
//  Created by Encore Shao on 2025/3/15.
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
