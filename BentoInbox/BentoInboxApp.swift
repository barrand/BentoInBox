//
//  BentoInboxApp.swift
//  BentoInbox
//
//  Created by Bryce Barrand on 11/11/25.
//

import SwiftUI
import SwiftData
import GoogleSignIn

@main
struct BentoInboxApp: App {

    // Register our SwiftData models
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Message.self,
            Category.self,
            TrainingExample.self,
            SyncState.self,
            EmailTag.self,
            EmailAnalysis.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    // App-wide services
    @State private var appState = AppState()
    @State private var authService: AuthService = GoogleAuthService()
    @State private var gmailService: GmailService = {
        let auth = GoogleAuthService()
        return GoogleGmailService(authService: auth)
    }()
    @State private var contactsService: ContactsService = SystemContactsService()
    @State private var ollamaModelManager = OllamaModelManager()
    @State private var llmAnalysisService: LLMAnalysisService = {
        let contacts = SystemContactsService()
        
        // Check which LLM service to use based on UserDefaults
        let useOllama = UserDefaults.standard.bool(forKey: "useOllama")
        let selectedModel = UserDefaults.standard.string(forKey: "ollamaModel") ?? "llama3.1:8b"
        
        if useOllama {
            let ollama = OllamaLLMAnalysisService(contactsService: contacts, model: selectedModel)
            if ollama.isAvailable() {
                print("✅ Using Ollama (\(selectedModel)) for LLM analysis")
                return ollama
            } else {
                print("⚠️ Ollama not running, falling back to Mock")
            }
        }
        
        print("ℹ️ Using Mock LLM service")
        return MockLLMAnalysisService(contactsService: contacts)
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .environment(\.authService, authService)
                .environment(\.gmailService, gmailService)
                .onOpenURL { url in
                    // Handle Google OAuth callback
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
        .modelContainer(sharedModelContainer)
    }
}

