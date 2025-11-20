//
//  Repositories.swift
//  BentoInbox
//
//  Created by Bryce Barrand on 11/11/25.
//

import Foundation
import SwiftData

// DTOs and Upserts

struct MessageUpsert {
    let id: String
    let threadId: String
    let date: Date
    let from: String
    let to: String?
    let subject: String?
    let snippet: String?
    let labelIds: [String]
    let isRead: Bool
}

struct MessageDTO: Identifiable {
    let id: String
    let date: Date
    let from: String
    let subject: String?
    let snippet: String?
    let isRead: Bool
    let userCategoryId: UUID?
    let predictedCategoryId: UUID?
    let predictedConfidence: Double?
}

struct CategoryDTO: Identifiable, Hashable {
    let id: UUID
    let name: String
    let isSuggested: Bool
    let isUserDefined: Bool
    let isSystem: Bool
    let colorHex: String?
}

struct TrainingExampleDTO: Identifiable {
    let id: UUID
    let messageId: String
    let categoryId: UUID
    let createdAt: Date
    let source: String
}

struct EmailTagDTO: Identifiable {
    let id: UUID
    let messageId: String
    let tag: String
    let source: String
    let confidence: Double
    let createdAt: Date
}

struct EmailAnalysisDTO: Identifiable {
    let id: UUID
    let messageId: String
    let summary: String
    let intent: String
    let urgency: String
    let requiresResponse: Bool
    let isActionable: Bool
    let senderCategory: String
    let hasDeadline: Bool
    let mentionsMoney: Bool
    let mentionsYouDirectly: Bool
    let createdAt: Date
}

// Repositories

protocol MessageRepository {
    func upsert(messages: [MessageUpsert], in context: ModelContext) throws
    func fetchInbox(limit: Int, in context: ModelContext) throws -> [MessageDTO]
    func fetchUncategorized(limit: Int, in context: ModelContext) throws -> [MessageDTO]
    func fetchByCategory(_ categoryId: UUID, limit: Int, in context: ModelContext) throws -> [MessageDTO]
    func fetchMessage(id: String, context: ModelContext) throws -> Message
    func updateUserCategory(messageId: String, categoryId: UUID?, in context: ModelContext) throws
    func existingIds(in context: ModelContext) throws -> Set<String>
    func fetchForTraining(limit: Int, in context: ModelContext) throws -> [MessageDTO]
    func countUncategorized(in context: ModelContext) throws -> Int
}

protocol CategoryRepository {
    func allCategories(in context: ModelContext) throws -> [CategoryDTO]
    func systemUncategorizedId(in context: ModelContext) throws -> UUID
}

protocol TrainingRepository {
    func recordExample(messageId: String, categoryId: UUID, source: String, in context: ModelContext) throws
    func examples(in context: ModelContext) throws -> [TrainingExampleDTO]
}

protocol EmailTagRepository {
    func saveTags(_ tags: [String], for messageId: String, source: String, in context: ModelContext) throws
    func fetchTags(for messageId: String, in context: ModelContext) throws -> [EmailTagDTO]
}

protocol EmailAnalysisRepository {
    func saveAnalysis(_ analysis: LLMEmailAnalysis, for messageId: String, in context: ModelContext) throws
    func fetchAnalysis(for messageId: String, in context: ModelContext) throws -> EmailAnalysisDTO?
}

final class SwiftDataMessageRepository: MessageRepository {
    func upsert(messages: [MessageUpsert], in context: ModelContext) throws {
        for m in messages {
            if let existing = try fetchModel(by: m.id, in: context) {
                existing.threadId = m.threadId
                existing.date = m.date
                existing.from = m.from
                existing.to = m.to
                existing.subject = m.subject
                existing.snippet = m.snippet
                existing.gmailLabelsRaw = try jsonEncode(m.labelIds)
                existing.isRead = m.isRead
                existing.updatedAt = Date()
            } else {
                let model = Message(
                    id: m.id,
                    threadId: m.threadId,
                    date: m.date,
                    from: m.from,
                    to: m.to,
                    subject: m.subject,
                    snippet: m.snippet,
                    gmailLabelsRaw: try jsonEncode(m.labelIds),
                    isRead: m.isRead
                )
                context.insert(model)
            }
        }
        try context.save()
    }

    func fetchInbox(limit: Int, in context: ModelContext) throws -> [MessageDTO] {
        var descriptor = FetchDescriptor<Message>(predicate: #Predicate { $0.id != "" }, sortBy: [SortDescriptor(\.date, order: .reverse)])
        descriptor.fetchLimit = limit
        let models = try context.fetch(descriptor)
        return models.map { $0.toDTO() }
    }

    func fetchUncategorized(limit: Int, in context: ModelContext) throws -> [MessageDTO] {
        var descriptor = FetchDescriptor<Message>(predicate: #Predicate { $0.userCategoryId == nil }, sortBy: [SortDescriptor(\.date, order: .reverse)])
        descriptor.fetchLimit = limit
        let models = try context.fetch(descriptor)
        return models.map { $0.toDTO() }
    }

    func fetchByCategory(_ categoryId: UUID, limit: Int, in context: ModelContext) throws -> [MessageDTO] {
        var descriptor = FetchDescriptor<Message>(predicate: #Predicate { $0.userCategoryId == categoryId }, sortBy: [SortDescriptor(\.date, order: .reverse)])
        descriptor.fetchLimit = limit
        let models = try context.fetch(descriptor)
        return models.map { $0.toDTO() }
    }

    func updateUserCategory(messageId: String, categoryId: UUID?, in context: ModelContext) throws {
        guard let model = try fetchModel(by: messageId, in: context) else { return }
        model.userCategoryId = categoryId
        model.updatedAt = Date()
        try context.save()
    }

    func existingIds(in context: ModelContext) throws -> Set<String> {
        // SwiftData's FetchDescriptor does not support propertiesToFetch; fetch models and map ids.
        let descriptor = FetchDescriptor<Message>()
        let models = try context.fetch(descriptor)
        return Set(models.map { $0.id })
    }
    
    func fetchForTraining(limit: Int, in context: ModelContext) throws -> [MessageDTO] {
        // Smart sampling: Mix of uncategorized messages with diverse characteristics
        // Prioritize uncategorized, but include some variety
        var descriptor = FetchDescriptor<Message>(
            predicate: #Predicate { $0.userCategoryId == nil },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        let models = try context.fetch(descriptor)
        return models.map { $0.toDTO() }
    }
    
    func countUncategorized(in context: ModelContext) throws -> Int {
        let descriptor = FetchDescriptor<Message>(predicate: #Predicate { $0.userCategoryId == nil })
        return try context.fetchCount(descriptor)
    }
    
    func fetchMessage(id: String, context: ModelContext) throws -> Message {
        guard let message = try fetchModel(by: id, in: context) else {
            throw NSError(domain: "MessageRepository", code: 404, userInfo: [NSLocalizedDescriptionKey: "Message not found"])
        }
        return message
    }

    private func fetchModel(by id: String, in context: ModelContext) throws -> Message? {
        let descriptor = FetchDescriptor<Message>(predicate: #Predicate { $0.id == id })
        return try context.fetch(descriptor).first
    }

    private func jsonEncode(_ labels: [String]) throws -> String {
        let data = try JSONEncoder().encode(labels)
        return String(data: data, encoding: .utf8) ?? "[]"
    }
}

final class SwiftDataCategoryRepository: CategoryRepository {
    func allCategories(in context: ModelContext) throws -> [CategoryDTO] {
        let models = try context.fetch(FetchDescriptor<Category>(sortBy: [SortDescriptor(\.name)]))
        return models.map { CategoryDTO(id: $0.id, name: $0.name, isSuggested: $0.isSuggested, isUserDefined: $0.isUserDefined, isSystem: $0.isSystem, colorHex: $0.colorHex) }
    }

    func systemUncategorizedId(in context: ModelContext) throws -> UUID {
        let models = try context.fetch(FetchDescriptor<Category>(predicate: #Predicate { $0.isSystem && $0.name == "Uncategorized" }))
        if let id = models.first?.id { return id }
        // Ensure exists
        let unc = Category(name: "Uncategorized", isSuggested: false, isUserDefined: false, isSystem: true)
        context.insert(unc)
        try context.save()
        return unc.id
    }
}

final class SwiftDataTrainingRepository: TrainingRepository {
    func recordExample(messageId: String, categoryId: UUID, source: String, in context: ModelContext) throws {
        let ex = TrainingExample(messageId: messageId, categoryId: categoryId, source: source)
        context.insert(ex)
        try context.save()
    }

    func examples(in context: ModelContext) throws -> [TrainingExampleDTO] {
        let models = try context.fetch(FetchDescriptor<TrainingExample>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)]))
        return models.map { TrainingExampleDTO(id: $0.id, messageId: $0.messageId, categoryId: $0.categoryId, createdAt: $0.createdAt, source: $0.source) }
    }
}

final class SwiftDataEmailTagRepository: EmailTagRepository {
    func saveTags(_ tags: [String], for messageId: String, source: String, in context: ModelContext) throws {
        // Delete existing LLM tags for this message to avoid duplicates
        let descriptor = FetchDescriptor<EmailTag>(predicate: #Predicate { $0.messageId == messageId && $0.source == "llm" })
        let existing = try context.fetch(descriptor)
        for tag in existing {
            context.delete(tag)
        }
        
        // Insert new tags
        for tagName in tags {
            let tag = EmailTag(messageId: messageId, tag: tagName, source: source)
            context.insert(tag)
        }
        try context.save()
    }
    
    func fetchTags(for messageId: String, in context: ModelContext) throws -> [EmailTagDTO] {
        let descriptor = FetchDescriptor<EmailTag>(
            predicate: #Predicate { $0.messageId == messageId },
            sortBy: [SortDescriptor(\.tag)]
        )
        let models = try context.fetch(descriptor)
        return models.map { EmailTagDTO(id: $0.id, messageId: $0.messageId, tag: $0.tag, source: $0.source, confidence: $0.confidence, createdAt: $0.createdAt) }
    }
}

final class SwiftDataEmailAnalysisRepository: EmailAnalysisRepository {
    func saveAnalysis(_ analysis: LLMEmailAnalysis, for messageId: String, in context: ModelContext) throws {
        // Delete existing analysis for this message
        let descriptor = FetchDescriptor<EmailAnalysis>(predicate: #Predicate { $0.messageId == messageId })
        let existing = try context.fetch(descriptor)
        for old in existing {
            context.delete(old)
        }
        
        // Insert new analysis
        let model = EmailAnalysis(
            messageId: messageId,
            summary: analysis.summary,
            intent: analysis.intent,
            urgency: analysis.urgency,
            requiresResponse: analysis.requiresResponse,
            isActionable: analysis.isActionable,
            senderCategory: analysis.senderCategory,
            hasDeadline: analysis.hasDeadline,
            mentionsMoney: analysis.mentionsMoney,
            mentionsYouDirectly: analysis.mentionsYouDirectly
        )
        context.insert(model)
        try context.save()
    }
    
    func fetchAnalysis(for messageId: String, in context: ModelContext) throws -> EmailAnalysisDTO? {
        let descriptor = FetchDescriptor<EmailAnalysis>(predicate: #Predicate { $0.messageId == messageId })
        guard let model = try context.fetch(descriptor).first else { return nil }
        return EmailAnalysisDTO(
            id: model.id,
            messageId: model.messageId,
            summary: model.summary,
            intent: model.intent,
            urgency: model.urgency,
            requiresResponse: model.requiresResponse,
            isActionable: model.isActionable,
            senderCategory: model.senderCategory,
            hasDeadline: model.hasDeadline,
            mentionsMoney: model.mentionsMoney,
            mentionsYouDirectly: model.mentionsYouDirectly,
            createdAt: model.createdAt
        )
    }
}

// MARK: - Mapping

private extension Message {
    func toDTO() -> MessageDTO {
        MessageDTO(
            id: id,
            date: date,
            from: from,
            subject: subject,
            snippet: snippet,
            isRead: isRead,
            userCategoryId: userCategoryId,
            predictedCategoryId: predictedCategoryId,
            predictedConfidence: predictedConfidence
        )
    }
}
