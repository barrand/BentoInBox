//
//  EmailAnalysisExporter.swift
//  BentoInbox
//
//  Created by Bryce Barrand on 11/20/25.
//

import Foundation
import SwiftData

/// Utility for exporting email analysis data to CSV for model comparison and accuracy evaluation
struct EmailAnalysisExporter {
    
    /// Export email analysis data to CSV format
    /// - Parameters:
    ///   - context: SwiftData model context
    ///   - limit: Maximum number of emails to export (default: 20)
    ///   - includeSnippet: Whether to include email snippet in export (default: false)
    /// - Returns: CSV string ready to save to file
    static func exportToCSV(context: ModelContext, limit: Int = 20, includeSnippet: Bool = false) throws -> String {
        // Fetch messages
        let descriptor = FetchDescriptor<Message>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        var messages = try context.fetch(descriptor)
        messages = Array(messages.prefix(limit))
        
        // Build CSV header
        var csvLines: [String] = []
        if includeSnippet {
            csvLines.append("Message ID,Sender,Subject,Snippet,AI Tags,Intent,Urgency,Sender Category,Requires Response,Is Actionable,Has Deadline,Mentions Money,Summary")
        } else {
            csvLines.append("Message ID,Sender,Subject,AI Tags,Intent,Urgency,Sender Category,Requires Response,Is Actionable,Has Deadline,Mentions Money,Summary")
        }
        
        // Fetch tags and analysis for each message
        for message in messages {
            // Get tags
            let tagsPredicate = #Predicate<EmailTag> { tag in
                tag.messageId == message.id
            }
            let tagsDescriptor = FetchDescriptor<EmailTag>(predicate: tagsPredicate)
            let tags = try context.fetch(tagsDescriptor)
            let tagNames = tags.map { $0.tag }.joined(separator: "; ")
            
            // Get analysis
            let analysisPredicate = #Predicate<EmailAnalysis> { analysis in
                analysis.messageId == message.id
            }
            let analysisDescriptor = FetchDescriptor<EmailAnalysis>(predicate: analysisPredicate)
            let analyses = try context.fetch(analysisDescriptor)
            let analysis = analyses.first
            
            // Build CSV row
            let sender = escapeCSV(message.from)
            let subject = escapeCSV(message.subject ?? "")
            let snippet = includeSnippet ? escapeCSV(message.snippet ?? "") : ""
            let aiTags = escapeCSV(tagNames.isEmpty ? "none" : tagNames)
            let intent = escapeCSV(analysis?.intent ?? "")
            let urgency = escapeCSV(analysis?.urgency ?? "")
            let senderCategory = escapeCSV(analysis?.senderCategory ?? "")
            let requiresResponse = analysis?.requiresResponse ?? false ? "Yes" : "No"
            let isActionable = analysis?.isActionable ?? false ? "Yes" : "No"
            let hasDeadline = analysis?.hasDeadline ?? false ? "Yes" : "No"
            let mentionsMoney = analysis?.mentionsMoney ?? false ? "Yes" : "No"
            let summary = escapeCSV(analysis?.summary ?? "")
            
            if includeSnippet {
                csvLines.append("\(message.id),\(sender),\(subject),\(snippet),\(aiTags),\(intent),\(urgency),\(senderCategory),\(requiresResponse),\(isActionable),\(hasDeadline),\(mentionsMoney),\(summary)")
            } else {
                csvLines.append("\(message.id),\(sender),\(subject),\(aiTags),\(intent),\(urgency),\(senderCategory),\(requiresResponse),\(isActionable),\(hasDeadline),\(mentionsMoney),\(summary)")
            }
        }
        
        return csvLines.joined(separator: "\n")
    }
    
    /// Export detailed comparison data for multiple model runs
    /// Use this when you want to compare different models' outputs
    static func exportComparisonCSV(context: ModelContext, limit: Int = 20) throws -> String {
        // Fetch messages
        let descriptor = FetchDescriptor<Message>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        var messages = try context.fetch(descriptor)
        messages = Array(messages.prefix(limit))
        
        // Build CSV with columns for manual annotation
        var csvLines: [String] = []
        csvLines.append("Message ID,Sender,Subject,AI Tags,Expected Tags (Manual),False Positives,False Negatives,Notes")
        
        for message in messages {
            // Get tags
            let tagsPredicate = #Predicate<EmailTag> { tag in
                tag.messageId == message.id
            }
            let tagsDescriptor = FetchDescriptor<EmailTag>(predicate: tagsPredicate)
            let tags = try context.fetch(tagsDescriptor)
            let tagNames = tags.map { $0.tag }.joined(separator: "; ")
            
            let sender = escapeCSV(message.from)
            let subject = escapeCSV(message.subject ?? "")
            let aiTags = escapeCSV(tagNames.isEmpty ? "none" : tagNames)
            
            // Empty columns for manual annotation
            csvLines.append("\(message.id),\(sender),\(subject),\(aiTags),,,,")
        }
        
        return csvLines.joined(separator: "\n")
    }
    
    /// Save CSV string to file
    static func saveToFile(csv: String, filename: String = "email_analysis_export.csv") -> URL? {
        let fileManager = FileManager.default
        
        #if os(macOS)
        // Use Desktop on macOS
        guard let desktopURL = fileManager.urls(for: .desktopDirectory, in: .userDomainMask).first else {
            print("❌ Could not get desktop directory")
            return nil
        }
        #else
        // Use Documents on iOS
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("❌ Could not get documents directory")
            return nil
        }
        let desktopURL = documentsURL
        #endif
        
        let fileURL = desktopURL.appendingPathComponent(filename)
        
        do {
            try csv.write(to: fileURL, atomically: true, encoding: .utf8)
            print("✅ CSV exported to: \(fileURL.path)")
            return fileURL
        } catch {
            print("❌ Failed to save CSV: \(error)")
            return nil
        }
    }
    
    // MARK: - Private Helpers
    
    /// Escape special characters for CSV format
    private static func escapeCSV(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // If contains comma, quote, or newline, wrap in quotes and escape quotes
        if trimmed.contains(",") || trimmed.contains("\"") || trimmed.contains("\n") {
            let escaped = trimmed.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        
        return trimmed
    }
}

// MARK: - View for CSV Export

#if os(macOS)
import SwiftUI

struct EmailAnalysisExportView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var exportStatus: String = ""
    @State private var isExporting = false
    @State private var exportedFileURL: URL?
    @State private var numberOfEmails = 20
    @State private var includeSnippet = false
    @State private var exportType: ExportType = .comparison
    
    enum ExportType: String, CaseIterable {
        case comparison = "Comparison (for manual annotation)"
        case detailed = "Detailed (all fields)"
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Export Email Analysis")
                .font(.title2.weight(.semibold))
            
            Form {
                Section {
                    Picker("Export Type", selection: $exportType) {
                        ForEach(ExportType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    
                    Stepper("Number of emails: \(numberOfEmails)", value: $numberOfEmails, in: 1...100)
                    
                    if exportType == .detailed {
                        Toggle("Include snippet", isOn: $includeSnippet)
                    }
                }
                
                Section {
                    if !exportStatus.isEmpty {
                        Text(exportStatus)
                            .foregroundStyle(exportStatus.contains("❌") ? .red : .green)
                    }
                    
                    if let url = exportedFileURL {
                        Button("Reveal in Finder") {
                            NSWorkspace.shared.activateFileViewerSelecting([url])
                        }
                    }
                }
            }
            .formStyle(.grouped)
            
            HStack(spacing: 12) {
                Button("Export CSV") {
                    exportCSV()
                }
                .buttonStyle(.borderedProminent)
                .disabled(isExporting)
                
                if isExporting {
                    ProgressView()
                        .controlSize(.small)
                }
            }
        }
        .padding()
        .frame(minWidth: 400, minHeight: 300)
    }
    
    private func exportCSV() {
        isExporting = true
        exportStatus = "Exporting..."
        exportedFileURL = nil
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let csv: String
                let filename: String
                
                switch exportType {
                case .comparison:
                    csv = try EmailAnalysisExporter.exportComparisonCSV(
                        context: modelContext,
                        limit: numberOfEmails
                    )
                    filename = "email_analysis_comparison_\(Date().formatted(.iso8601)).csv"
                    
                case .detailed:
                    csv = try EmailAnalysisExporter.exportToCSV(
                        context: modelContext,
                        limit: numberOfEmails,
                        includeSnippet: includeSnippet
                    )
                    filename = "email_analysis_detailed_\(Date().formatted(.iso8601)).csv"
                }
                
                if let url = EmailAnalysisExporter.saveToFile(csv: csv, filename: filename) {
                    DispatchQueue.main.async {
                        exportStatus = "✅ Exported \(numberOfEmails) emails successfully!"
                        exportedFileURL = url
                        isExporting = false
                    }
                } else {
                    DispatchQueue.main.async {
                        exportStatus = "❌ Failed to save file"
                        isExporting = false
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    exportStatus = "❌ Export failed: \(error.localizedDescription)"
                    isExporting = false
                }
            }
        }
    }
}

#Preview {
    EmailAnalysisExportView()
        .modelContainer(for: [Message.self, EmailTag.self, EmailAnalysis.self])
}
#endif
