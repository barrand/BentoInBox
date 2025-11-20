# LLM Email Analysis & Tags Feature

## Overview

We've added **LLM-powered email analysis** that automatically extracts tags and generates summaries when you open an email in the reading pane. This is the first step toward building a smart ML training system.

## What's New

### 1. **New Data Models** (`Models.swift`)

#### `EmailTag`
Stores semantic tags extracted from emails:
- `messageId`: Which email this tag belongs to
- `tag`: The tag name (e.g., "meeting", "urgent", "financial")
- `source`: Where the tag came from ("llm", "user", or "rule")
- `confidence`: How confident the system is in this tag
- `createdAt`: When the tag was created

#### `EmailAnalysis`
Stores rich LLM analysis of emails:
- `messageId`: Which email was analyzed
- `summary`: One-sentence summary of the email
- `intent`: What kind of email it is ("question", "action-required", "informational", "promotional", "transactional")
- `urgency`: How urgent it is ("immediate", "soon", "normal", "low")
- `requiresResponse`: Boolean - does sender expect a reply?
- `isActionable`: Boolean - is there something you need to do?
- `senderCategory`: Type of sender ("colleague", "client", "service", "marketing", "personal")
- `hasDeadline`: Boolean - mentions a deadline?
- `mentionsMoney`: Boolean - mentions payments/costs?
- `mentionsYouDirectly`: Boolean - addresses you by name?
- `createdAt`: When the analysis was performed

### 2. **LLM Analysis Service** (`Services.swift`)

#### `LLMAnalysisService` Protocol
```swift
protocol LLMAnalysisService {
    func isAvailable() -> Bool
    func analyzeEmail(subject: String?, body: String, from: String) async throws -> LLMEmailAnalysis
}
```

#### `MockLLMAnalysisService`
Currently using a **smart mock** that:
- Analyzes email content to extract relevant tags
- Detects patterns like "meeting", "travel", "financial", "urgent"
- Classifies intent based on keywords
- Determines urgency and actionability
- Provides realistic simulated analysis in ~1.5 seconds

**Future**: Replace with Apple's Foundation Models for real on-device LLM analysis.

### 3. **New Repositories** (`Repositories.swift`)

#### `EmailTagRepository`
- `saveTags()`: Save tags for a message (replaces existing LLM tags)
- `fetchTags()`: Get all tags for a message

#### `EmailAnalysisRepository`
- `saveAnalysis()`: Save analysis for a message (replaces existing)
- `fetchAnalysis()`: Get analysis for a message

### 4. **Enhanced Reading Pane UI** (`Views.swift`)

When you open an email, you now see:

#### **AI Analysis Section**
- **"Analyzing..." indicator** while LLM processes the email
- **Tags section** with color-coded tag chips:
  - 🔴 Red: "urgent"
  - 🟠 Orange: "question", "action-required"
  - 🔵 Blue: "meeting", "calendar"
  - 🟣 Purple: "travel"
  - 🟢 Green: "financial", "invoice"
  - 🟣 Indigo: "work-project"
  - ⚫️ Gray: "newsletter"
  - 🔘 Secondary: Other tags
- **Summary section** with one-sentence summary
- **Quick insights** badges:
  - "Response needed" (orange)
  - "Action required" (blue)
  - "Has deadline" (red)

#### **Smart Caching**
- Analysis is cached in the database
- Only analyzes each email **once**
- Instant display on subsequent opens

### 5. **Flow Layout**
Added a custom `FlowLayout` that wraps tags naturally across multiple lines.

## How It Works

### When You Open an Email:

1. **Load email body** from Gmail API
2. **Check cache** - Does this email already have analysis?
   - ✅ **Yes**: Display cached tags and summary instantly
   - ❌ **No**: Run LLM analysis
3. **Run LLM analysis** (if needed):
   - Extract semantic tags from subject + body
   - Generate summary
   - Classify intent, urgency, sender type
   - Detect actionability, deadlines, money mentions
4. **Save to database** for future use
5. **Display in UI** with color-coded tags and insights

### What Tags Look Like

Example email: *"Hi Bryce, can you review the Q4 budget by Friday? The invoice is attached."*

**Tags extracted:**
- `question` (asks you something)
- `action-required` (needs you to do something)
- `work-project` (work-related)
- `financial` (mentions budget/invoice)
- `deadline` (mentions Friday)

**Analysis:**
- **Summary**: "Email about: Review Q4 budget by Friday with invoice attached"
- **Intent**: "action-required"
- **Urgency**: "soon"
- **Requires Response**: true
- **Is Actionable**: true
- **Has Deadline**: true
- **Mentions Money**: true
- **Mentions You Directly**: true

## Why This Matters for ML Training

These tags and analysis fields will become **powerful features** for your ML model:

### Current Flow (Manual Training)
1. You categorize email as P1/P2/P3/P4
2. System records `TrainingExample`

### Enhanced Flow (With LLM Tags) ✨
1. Email arrives → **LLM extracts tags**
2. You categorize email as P1/P2/P3/P4
3. System records `TrainingExample` + **associates tags**
4. ML model learns: *"Emails with tags ['urgent', 'question', 'action-required'] are usually P1"*

### Future ML Features Will Use:
- **Tags** as binary features (hasTag_Urgent, hasTag_Financial, etc.)
- **Intent** as categorical feature
- **Urgency** as ordinal feature
- **Boolean flags** (requiresResponse, isActionable, hasDeadline)
- **Sender category** for sender-based learning

This gives the ML model **rich semantic understanding** instead of just raw text.

## Tag Categories We Extract

### 👤 **Personal Sender** ⭐️ **HIGH PRIORITY**
- `personal-sender` - Email from a real person (friend, family, colleague)
  - ✅ Detects personal email domains (Gmail, Yahoo, iCloud, Hotmail, etc.)
  - ✅ Identifies real name format: "John Doe <john@example.com>"
  - ✅ Excludes automated addresses (noreply, no-reply, notifications)
  - ✅ Excludes marketing/support (newsletter, support, info, team)
  - **This is a strong signal for importance!** Real people > automated systems

### 📅 **Meeting & Calendar**
- `meeting`
- `calendar`
- `invitation`

### ✈️ **Travel**
- `travel`
- `flight`
- `hotel`
- `booking-confirmation`

### 💰 **Financial**
- `financial`
- `invoice`
- `payment`
- `receipt`

### 💼 **Work & Projects**
- `work-project`
- `project`
- `task`

### 📰 **Content Types**
- `newsletter`
- `general`
- `informational`

### 🚨 **Priority & Action**
- `urgent`
- `action-required`
- `question`
- `deadline`

## Next Steps

### Phase 1: ✅ **LLM Tag Extraction** (DONE!)
- Added tag extraction service
- Display tags in reading pane
- Cache analysis in database

### Phase 2: **Sender Rules** (Next)
- Learn patterns from specific senders
- "Always put sender@example.com in P4"
- Confidence scores based on consistency

### Phase 3: **Rich ML Features**
- Use tags as training features
- Train CoreML model with 100+ examples
- Combine sender patterns + tags + content

### Phase 4: **Hybrid Prediction**
- Sender rules (instant, high confidence)
- ML model (fast, good for patterns)
- LLM analysis (slower, handles edge cases)

## How to Test

1. **Run the app**
2. **Open an email** in the reading pane
3. **Wait ~1.5 seconds** for analysis
4. **See tags and summary** appear below the message content
5. **Open the same email again** - notice instant display (cached!)

## Future: Real LLM Integration

Currently using `MockLLMAnalysisService` with smart pattern detection.

**Next**: Replace with Apple's **Foundation Models** framework:

```swift
import FoundationModels

final class AppleLLMAnalysisService: LLMAnalysisService {
    private let model = SystemLanguageModel.default
    
    func isAvailable() -> Bool {
        switch model.availability {
        case .available:
            return true
        default:
            return false
        }
    }
    
    func analyzeEmail(...) async throws -> LLMEmailAnalysis {
        let session = LanguageModelSession(instructions: """
            You are an email analyzer. Extract semantic tags and provide structured analysis.
            """)
        
        let prompt = "Analyze this email: ..."
        
        let response = try await session.respond(
            to: prompt,
            generating: LLMEmailAnalysis.self
        )
        
        return response.content
    }
}
```

This will use **on-device Apple Intelligence** for true semantic understanding!

## Tag Statistics (Future Feature Idea)

Could add a view showing:
- Most common tags across all emails
- Tag distribution by category (P1 emails = "urgent", P4 emails = "newsletter")
- Tag clouds
- Tag-based search/filtering

## Summary

🎉 **You now have LLM-powered email analysis!**

Every email you open gets:
- ✅ Semantic tags extracted
- ✅ One-sentence summary
- ✅ Intent classification
- ✅ Urgency assessment
- ✅ Actionability detection
- ✅ Rich metadata for future ML training

**Open an email and watch the magic happen!** ✨
