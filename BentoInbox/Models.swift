//
//  Models.swift
//  BentoInbox
//
//  Created by Bryce Barrand on 11/11/25.
//

import Foundation
import SwiftData

@Model
final class Message {
    @Attribute(.unique) var id: String
    var threadId: String
    var date: Date
    var from: String
    var to: String?
    var subject: String?
    var snippet: String?
    var gmailLabelsRaw: String // JSON-encoded [String]
    var isRead: Bool
    var userCategoryId: UUID?
    var predictedCategoryId: UUID?
    var predictedConfidence: Double?
    var embedding: Data?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: String,
        threadId: String,
        date: Date,
        from: String,
        to: String? = nil,
        subject: String? = nil,
        snippet: String? = nil,
        gmailLabelsRaw: String = "[]",
        isRead: Bool = true,
        userCategoryId: UUID? = nil,
        predictedCategoryId: UUID? = nil,
        predictedConfidence: Double? = nil,
        embedding: Data? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.threadId = threadId
        self.date = date
        self.from = from
        self.to = to
        self.subject = subject
        self.snippet = snippet
        self.gmailLabelsRaw = gmailLabelsRaw
        self.isRead = isRead
        self.userCategoryId = userCategoryId
        self.predictedCategoryId = predictedCategoryId
        self.predictedConfidence = predictedConfidence
        self.embedding = embedding
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

@Model
final class Category {
    @Attribute(.unique) var id: UUID
    var name: String
    var isSuggested: Bool
    var isUserDefined: Bool
    var colorHex: String?
    var isSystem: Bool
    var isArchived: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        isSuggested: Bool,
        isUserDefined: Bool,
        colorHex: String? = nil,
        isSystem: Bool = false,
        isArchived: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.isSuggested = isSuggested
        self.isUserDefined = isUserDefined
        self.colorHex = colorHex
        self.isSystem = isSystem
        self.isArchived = isArchived
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

@Model
final class TrainingExample {
    @Attribute(.unique) var id: UUID
    var messageId: String
    var categoryId: UUID
    var createdAt: Date
    var source: String

    init(id: UUID = UUID(), messageId: String, categoryId: UUID, createdAt: Date = Date(), source: String = "user") {
        self.id = id
        self.messageId = messageId
        self.categoryId = categoryId
        self.createdAt = createdAt
        self.source = source
    }
}

@Model
final class SyncState {
    @Attribute(.unique) var id: String
    var lastFetchedDate: Date?

    init(id: String = "global", lastFetchedDate: Date? = nil) {
        self.id = id
        self.lastFetchedDate = lastFetchedDate
    }
}

