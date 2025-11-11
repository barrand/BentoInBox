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

        let defaults: [(String, Bool)] = [
            ("Important", true),
            ("Family/Friends", true),
            ("School", true),
            ("Church", true),
            ("Work", true),
            ("Promotions", true),
            ("Newsletters", true),
            ("Receipts", true),
            ("Travel", true)
        ]

        for (name, suggested) in defaults {
            let c = Category(name: name, isSuggested: suggested, isUserDefined: false, isSystem: false)
            context.insert(c)
        }

        // System Uncategorized (non-deletable)
        let uncategorized = Category(name: "Uncategorized", isSuggested: false, isUserDefined: false, colorHex: nil, isSystem: true)
        context.insert(uncategorized)

        try context.save()
    }
}

