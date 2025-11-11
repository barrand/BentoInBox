//
//  UseCases.swift
//  BentoInbox
//
//  Created by Bryce Barrand on 11/11/25.
//

import Foundation
import SwiftData

struct FetchRecentInboxUseCase {
    let gmail: GmailService
    let messages: MessageRepository

    func execute(maxResults: Int = 100, context: ModelContext) async throws {
        var fetchedIds: [String] = []
        var pageToken: String? = nil

        repeat {
            let page = try await gmail.listMessageIds(labelIds: ["INBOX"], maxResults: min(50, maxResults - fetchedIds.count), pageToken: pageToken)
            fetchedIds.append(contentsOf: page.ids)
            pageToken = page.nextPageToken
        } while fetchedIds.count < maxResults && pageToken != nil

        let existing = try messages.existingIds(in: context)
        var upserts: [MessageUpsert] = []

        for id in fetchedIds {
            if existing.contains(id) { continue }
            let meta = try await gmail.getMessageMetadata(id: id)
            let date = meta.date ?? Date()
            upserts.append(MessageUpsert(
                id: meta.id,
                threadId: meta.threadId,
                date: date,
                from: meta.from ?? "",
                to: meta.to,
                subject: meta.subject,
                snippet: meta.snippet,
                labelIds: meta.labelIds,
                isRead: meta.isRead
            ))
        }

        try messages.upsert(messages: upserts, in: context)

        // Update sync state
        let newestDate = upserts.map { $0.date }.max()
        if let newestDate {
            let state = try fetchOrCreateSyncState(context: context)
            state.lastFetchedDate = max(state.lastFetchedDate ?? .distantPast, newestDate)
            try context.save()
        }
    }

    private func fetchOrCreateSyncState(context: ModelContext) throws -> SyncState {
        if let existing = try context.fetch(FetchDescriptor<SyncState>()).first {
            return existing
        }
        let s = SyncState()
        context.insert(s)
        return s
    }
}

struct AssignCategoryUseCase {
    let messages: MessageRepository
    let training: TrainingRepository

    func execute(messageId: String, categoryId: UUID?, context: ModelContext) throws {
        try messages.updateUserCategory(messageId: messageId, categoryId: categoryId, in: context)
        if let categoryId {
            try training.recordExample(messageId: messageId, categoryId: categoryId, source: "user", in: context)
        }
    }
}

