//
//  SeedCategoryLoader.swift
//  BentoInbox
//
//  Created by Bryce Barrand on 11/11/25.
//

import Foundation
import SwiftData

enum SeedCategoryLoader {
    static func seedIfNeeded(_ context: ModelContext) throws {
        let fetch = FetchDescriptor<Category>()
        let existing = try context.fetch(fetch)
        if !existing.isEmpty { return }

        // Priority-based categorization system (P1-P4)
        let defaults: [(String, String?, Bool)] = [
            ("P1 - Needs Attention", "#EF5350", true),      // Red - urgent, needs response soon
            ("P2 - Can Wait", "#FFA726", true),             // Orange - important but not urgent
            ("P3 - Newsletter/Automated", "#66BB6A", true), // Green - informational, low priority
            ("P4 - Pure Junk", "#9E9E9E", true)             // Gray - ignore/archive
        ]

        for (name, colorHex, suggested) in defaults {
            let c = Category(name: name, isSuggested: suggested, isUserDefined: false, colorHex: colorHex, isSystem: false)
            context.insert(c)
        }

        // System Uncategorized (non-deletable)
        let uncategorized = Category(name: "Uncategorized", isSuggested: false, isUserDefined: false, colorHex: nil, isSystem: true)
        context.insert(uncategorized)

        try context.save()
    }
    
    /// Force reset all categories to the new P1-P4 system (use with caution - clears existing)
    static func resetToP1P4System(_ context: ModelContext) throws {
        // First, clear all user category assignments from messages
        let messageFetch = FetchDescriptor<Message>()
        let messages = try context.fetch(messageFetch)
        for message in messages {
            message.userCategoryId = nil
            message.predictedCategoryId = nil
            message.predictedConfidence = nil
        }
        
        // Delete all training examples
        let trainingFetch = FetchDescriptor<TrainingExample>()
        let trainingExamples = try context.fetch(trainingFetch)
        for example in trainingExamples {
            context.delete(example)
        }
        
        // Delete all existing categories
        let categoryFetch = FetchDescriptor<Category>()
        let existing = try context.fetch(categoryFetch)
        for category in existing {
            context.delete(category)
        }
        try context.save()
        
        // Now seed the new P1-P4 categories
        let defaults: [(String, String?, Bool)] = [
            ("P1 - Needs Attention", "#EF5350", true),
            ("P2 - Can Wait", "#FFA726", true),
            ("P3 - Newsletter/Automated", "#66BB6A", true),
            ("P4 - Pure Junk", "#9E9E9E", true)
        ]

        for (name, colorHex, suggested) in defaults {
            let c = Category(name: name, isSuggested: suggested, isUserDefined: false, colorHex: colorHex, isSystem: false)
            context.insert(c)
        }

        let uncategorized = Category(name: "Uncategorized", isSuggested: false, isUserDefined: false, colorHex: nil, isSystem: true)
        context.insert(uncategorized)

        try context.save()
    }
}

