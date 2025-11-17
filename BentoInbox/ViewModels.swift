//
//  ViewModels.swift
//  BentoInbox
//
//  Created by Bryce Barrand on 11/11/25.
//

import Foundation
import SwiftData
import Combine

@MainActor
final class SignInViewModel: ObservableObject {
    @Published var isSigningIn = false
    @Published var errorMessage: String?

    func checkSignedIn(authService: AuthService) async -> Bool {
        await authService.isSignedIn()
    }

    func signIn(authService: AuthService, appState: AppState) async {
        isSigningIn = true
        defer { isSigningIn = false }
        do {
            try await authService.signIn()
            appState.isSignedIn = true
        } catch {
            errorMessage = "Failed to sign in: \(error.localizedDescription)"
        }
    }

    func signOut(authService: AuthService, appState: AppState) async {
        do {
            try await authService.signOut()
            appState.isSignedIn = false
        } catch {
            errorMessage = "Failed to sign out: \(error.localizedDescription)"
        }
    }
}

@MainActor
final class InboxViewModel: ObservableObject {
    @Published var messages: [MessageDTO] = []
    @Published var categories: [CategoryDTO] = []
    @Published var filter: InboxFilter = .all
    @Published var isRefreshing = false
    @Published var errorMessage: String?

    private let messageRepo: MessageRepository = SwiftDataMessageRepository()
    private let categoryRepo: CategoryRepository = SwiftDataCategoryRepository()

    enum InboxFilter {
        case all
        case uncategorized
        case category(UUID)
    }

    func refresh(context: ModelContext, gmail: GmailService) async {
        isRefreshing = true
        defer { isRefreshing = false }
        do {
            let useCase = FetchRecentInboxUseCase(gmail: gmail, messages: messageRepo)
            try await useCase.execute(maxResults: 100, context: context)
            try load(context: context)
        } catch {
            errorMessage = "Failed to refresh: \(error.localizedDescription)"
        }
    }

    func load(context: ModelContext) throws {
        categories = try categoryRepo.allCategories(in: context)
        switch filter {
        case .all:
            messages = try messageRepo.fetchInbox(limit: 200, in: context)
        case .uncategorized:
            messages = try messageRepo.fetchUncategorized(limit: 200, in: context)
        case .category(let id):
            messages = try messageRepo.fetchByCategory(id, limit: 200, in: context)
        }
    }

    func assign(messageId: String, to categoryId: UUID?, context: ModelContext) throws {
        let useCase = AssignCategoryUseCase(messages: messageRepo, training: SwiftDataTrainingRepository())
        try useCase.execute(messageId: messageId, categoryId: categoryId, context: context)
        
        // Re-fetch just this one message to get updated data and update the array
        if let index = messages.firstIndex(where: { $0.id == messageId }),
           let updated = try? messageRepo.fetchMessage(id: messageId, context: context) {
            let updatedDTO = MessageDTO(
                id: updated.id,
                date: updated.date,
                from: updated.from,
                subject: updated.subject,
                snippet: updated.snippet,
                isRead: updated.isRead,
                userCategoryId: updated.userCategoryId,
                predictedCategoryId: updated.predictedCategoryId,
                predictedConfidence: updated.predictedConfidence
            )
            // Create a new array to ensure SwiftUI detects the change
            var updatedMessages = messages
            updatedMessages[index] = updatedDTO
            messages = updatedMessages
        }
    }
}

@MainActor
final class MessageDetailViewModel: ObservableObject {
    @Published var message: MessageDTO?
}

@MainActor
final class CategoriesViewModel: ObservableObject {
    @Published var categories: [CategoryDTO] = []
    @Published var errorMessage: String?

    private let categoryRepo: CategoryRepository = SwiftDataCategoryRepository()

    func load(context: ModelContext) throws {
        categories = try categoryRepo.allCategories(in: context)
    }
}
