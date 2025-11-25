# Improving AI Tag Accuracy: Comprehensive Guide

**Date**: November 20, 2025

## Overview

This guide provides strategies to improve the accuracy of AI-generated email tags beyond simply changing the model. These techniques can significantly boost precision and recall.

---

## 🎯 1. Few-Shot Learning (Most Effective!)

**What it is**: Provide the LLM with 3-5 example emails and their correct tags in the prompt.

**Why it works**: LLMs learn patterns much better from examples than from descriptions alone.

### Implementation Strategy:

```swift
// Add to OllamaLLMAnalysisService
private func buildPromptWithExamples(from: String, subject: String?, body: String) -> String {
    let examples = """
    Here are some example emails with correct tags:
    
    Example 1:
    From: Krishna Vasamshetti <recruiter@mitchell-martin.com>
    Subject: Senior Python Developer - Jersey City
    Body: "This is Krishna, Sr. Technical Recruiter... We are seeking a Senior Python Developer..."
    Correct Tags: ["recruiting", "cold-outreach"]
    
    Example 2:
    From: Jane Smith <jane.smith@company.com>
    Subject: Meeting tomorrow at 2pm?
    Body: "Can we meet tomorrow to discuss the project?"
    Correct Tags: ["meeting", "question", "personal-sender"]
    
    Example 3:
    From: noreply@github.com
    Subject: [Security] Dependabot alert
    Body: "A security vulnerability was found in your repository..."
    Correct Tags: ["work-project", "urgent"]
    
    Example 4:
    From: Acme Newsletter <newsletter@acme.com>
    Subject: Weekly Digest - Issue #47
    Body: "Here's what's new this week... Click here to unsubscribe"
    Correct Tags: ["newsletter"]
    
    Example 5:
    From: crypto_invest@sketchy-domain.com
    Subject: URGENT: Make $10,000 NOW!!!
    Body: "Invest in crypto today and become a millionaire..."
    Correct Tags: ["spam-likely", "cold-outreach"]
    
    Now analyze this email:
    """
    
    return examples + "\n\nFrom: \(from)\nSubject: \(subject ?? "No subject")\nBody: \(body)"
}
```

**Expected improvement**: +20-30% accuracy

---

## 🧪 2. Chain-of-Thought Reasoning

**What it is**: Ask the LLM to explain its reasoning before providing tags.

**Why it works**: Forces the model to think through the decision process, reducing impulsive/wrong answers.

### Implementation:

```swift
let prompt = """
Analyze this email step by step:

1. First, identify the sender type (personal, automated, marketing, etc.)
2. Then, identify the main topic/purpose
3. Finally, select the most appropriate tags

Email:
From: \(from)
Subject: \(subject ?? "No subject")
Body: \(truncatedBody)

Your analysis:
{
  "reasoning": "Step 1: The sender is... Step 2: The email is about... Step 3: Therefore tags should be...",
  "tags": ["tag1", "tag2"],
  "intent": "...",
  ...
}
"""
```

**Expected improvement**: +10-15% accuracy

---

## 📊 3. Confidence Scoring & Thresholds

**What it is**: Ask the LLM to rate its confidence for each tag, then filter low-confidence tags.

**Why it works**: LLMs can recognize when they're uncertain, and these uncertain tags are often wrong.

### Implementation:

```swift
struct TagWithConfidence: Codable {
    let tag: String
    let confidence: Double  // 0.0 to 1.0
    let reasoning: String
}

struct LLMEmailAnalysisWithConfidence: Codable {
    let summary: String
    let tags: [TagWithConfidence]
    let intent: String
    // ... other fields
}

// In analyzeEmail, filter by confidence:
let validTags = analysis.tags
    .filter { $0.confidence >= 0.7 }  // Only keep high-confidence tags
    .map { $0.tag }
```

**Expected improvement**: +15-20% accuracy (by reducing false positives)

---

## 🔄 4. Multi-Pass Analysis

**What it is**: Run analysis twice with different prompts and combine results.

**Why it works**: Different prompting strategies catch different patterns; consensus improves accuracy.

### Implementation:

```swift
func analyzeEmail(subject: String?, body: String, from: String) async throws -> LLMEmailAnalysis {
    // Pass 1: Content-focused
    let contentPrompt = buildContentFocusedPrompt(from: from, subject: subject, body: body)
    let contentAnalysis = try await sendOllamaRequest(contentPrompt)
    
    // Pass 2: Sender-focused
    let senderPrompt = buildSenderFocusedPrompt(from: from, subject: subject, body: body)
    let senderAnalysis = try await sendOllamaRequest(senderPrompt)
    
    // Merge results (tags that appear in both or have high confidence in either)
    return mergeAnalyses(contentAnalysis, senderAnalysis)
}
```

**Expected improvement**: +10-15% accuracy
**Trade-off**: 2x slower

---

## 🎓 5. Dynamic Few-Shot from User Corrections

**What it is**: Store user corrections and use the most similar examples in the prompt.

**Why it works**: Examples are personalized to YOUR email patterns and preferences.

### Implementation:

```swift
@Model
final class TagCorrection {
    var messageId: String
    var from: String
    var subject: String?
    var bodySnippet: String
    var aiTags: [String]
    var correctedTags: [String]
    var createdAt: Date
}

// When user manually edits tags:
func recordCorrection(messageId: String, aiTags: [String], correctedTags: [String]) {
    let correction = TagCorrection(
        messageId: messageId,
        from: message.from,
        subject: message.subject,
        bodySnippet: String(message.snippet?.prefix(200) ?? ""),
        aiTags: aiTags,
        correctedTags: correctedTags,
        createdAt: Date()
    )
    modelContext.insert(correction)
}

// In prompt building:
func fetchRelevantExamples(for email: String, limit: Int = 3) -> [TagCorrection] {
    // Fetch corrections similar to current email
    // Could use: same sender domain, similar subject keywords, etc.
}
```

**Expected improvement**: +25-40% accuracy (after collecting ~50 corrections)

---

## 🧬 6. Structured Output with Validation

**What it is**: Use JSON Schema to force the LLM to return valid, structured output.

**Why it works**: Reduces parsing errors and ensures consistent format.

### Implementation:

```swift
// With Ollama API, use strict JSON schema:
let schema = """
{
  "type": "object",
  "properties": {
    "tags": {
      "type": "array",
      "items": {
        "type": "string",
        "enum": ["personal-sender", "urgent", "question", "action-required", 
                 "meeting", "travel", "financial", "work-project", "newsletter",
                 "receipt", "social", "recruiting", "cold-outreach", "spam-likely", "general"]
      },
      "minItems": 1,
      "maxItems": 3
    },
    "intent": {
      "type": "string",
      "enum": ["question", "action-required", "informational", "promotional", "transactional"]
    }
  },
  "required": ["tags", "intent", "urgency", "summary"]
}
"""
```

**Expected improvement**: +5-10% accuracy (mainly by preventing invalid tags)

---

## 🎯 7. Tag Hierarchy & Mutual Exclusion Rules

**What it is**: Define rules for which tags can coexist and which are mutually exclusive.

**Why it works**: Prevents nonsensical tag combinations.

### Implementation:

```swift
struct TagRules {
    // Tags that can't appear together
    static let mutuallyExclusive: [[String]] = [
        ["personal-sender", "newsletter"],  // Newsletters aren't from personal senders
        ["spam-likely", "work-project"],    // Spam isn't work
        ["spam-likely", "personal-sender"]  // Spam isn't personal
    ]
    
    // If tag A is present, tag B is likely wrong
    static let incompatiblePairs: [(String, String)] = [
        ("newsletter", "personal-sender"),
        ("recruiting", "personal-sender"),
        ("cold-outreach", "personal-sender")
    ]
    
    static func validate(_ tags: [String]) -> [String] {
        var validatedTags = tags
        
        // Remove conflicting tags
        for exclusiveSet in mutuallyExclusive {
            let matches = validatedTags.filter { exclusiveSet.contains($0) }
            if matches.count > 1 {
                // Keep only the first one (or the most specific)
                validatedTags.removeAll { matches.dropFirst().contains($0) }
            }
        }
        
        return validatedTags
    }
}

// Apply after LLM returns tags:
analysis.tags = TagRules.validate(analysis.tags)
```

**Expected improvement**: +5-10% accuracy

---

## 📈 8. Temperature & Parameter Tuning

**What it is**: Adjust LLM generation parameters for more consistent output.

**Why it works**: Lower temperature = more deterministic, higher accuracy for classification tasks.

### Recommended Settings:

```swift
let options = OllamaOptions(
    temperature: 0.1,           // Very low for classification (was 0.3)
    num_predict: 512,
    top_p: 0.9,                // Nucleus sampling
    top_k: 40,                 // Top-k sampling
    repeat_penalty: 1.1        // Prevent repetition
)
```

**Expected improvement**: +5-10% accuracy

---

## 🔍 9. Pre-Processing & Context Enhancement

**What it is**: Add more structured context to help the LLM make better decisions.

**Why it works**: More information = better decisions.

### Implementation:

```swift
func analyzeEmail(subject: String?, body: String, from: String) async throws -> LLMEmailAnalysis {
    let emailAddress = extractEmailAddress(from: from)
    let domain = emailAddress.split(separator: "@").last?.lowercased() ?? ""
    
    // Check if sender is in contacts
    let inContacts = await contactsService.isInContacts(email: emailAddress)
    
    // Extract domain metadata
    let isKnownService = knownServiceDomains.contains(domain)
    let isPersonalDomain = personalEmailDomains.contains(domain)
    
    // Count emails from this sender
    let previousEmailCount = try? await countPreviousEmails(from: emailAddress)
    
    // Build enhanced context
    let context = """
    Additional context:
    - Sender email: \(emailAddress)
    - Domain: \(domain)
    - In contacts: \(inContacts ? "Yes" : "No")
    - Known service domain: \(isKnownService ? "Yes" : "No")
    - Personal email domain: \(isPersonalDomain ? "Yes" : "No")
    - Previous emails from sender: \(previousEmailCount ?? 0)
    """
    
    let prompt = buildPrompt(from: from, subject: subject, body: body, context: context)
    // ...
}
```

**Expected improvement**: +10-15% accuracy

---

## 🧠 10. Model-Specific Optimizations

**What it is**: Different models respond better to different prompting styles.

### For Llama 3.1 (Current Model):

- ✅ Use structured output format (JSON)
- ✅ Keep prompts concise but detailed
- ✅ Use examples (few-shot)
- ✅ Use system prompts for role-setting

### If Testing Other Models:

| Model | Best For | Prompt Style | Temperature |
|-------|----------|--------------|-------------|
| **Llama 3.1:8b** | General purpose | Structured, examples | 0.1-0.3 |
| **Mistral:7b** | Fast, efficient | Concise, direct | 0.2-0.4 |
| **Phi-3:mini** | Lightweight, fast | Simple, clear | 0.1-0.2 |
| **Gemma 2:9b** | Reasoning | Detailed, step-by-step | 0.2-0.5 |
| **Qwen 2.5:7b** | Multilingual | Context-rich | 0.1-0.3 |

---

## 🎨 11. Tag Specificity Optimization

**What it is**: Redefine tags to be more specific and less ambiguous.

**Current issues**:
- "general" is too broad → Split into more specific categories
- "cold-outreach" vs "recruiting" can overlap → Define clearer boundaries

### Suggested Tag Refinements:

```swift
static let allowedTags = [
    // People
    "personal-sender",        // Friends, family, known contacts
    "colleague",              // Work colleagues (domain match)
    "client",                 // External business contacts
    
    // Content Type
    "meeting",                // Calendar invites, meeting requests
    "question",               // Asking for information/action
    "announcement",           // FYI, informational
    "work-project",           // Project-related communication
    
    // Business/Marketing
    "recruiting",             // Job offers only
    "cold-sales",             // Sales outreach
    "partnership-request",    // Business partnerships
    "newsletter",             // Subscribed newsletters
    "marketing-promo",        // Promotional emails
    
    // Transactional
    "receipt",                // Purchase confirmations
    "financial",              // Invoices, payments
    "travel",                 // Travel confirmations
    "service-notification",   // Automated system alerts
    
    // Priority
    "urgent",                 // Time-sensitive
    "action-required",        // Needs response/action
    
    // Quality
    "spam-likely",            // Suspected spam
    
    // Fallback
    "uncategorized"           // Truly unclear
]
```

---

## 📊 12. Evaluation & Metrics

To measure improvement, calculate:

### Precision
```
Precision = True Positives / (True Positives + False Positives)
```

### Recall
```
Recall = True Positives / (True Positives + False Negatives)
```

### F1 Score (Overall Accuracy)
```
F1 = 2 × (Precision × Recall) / (Precision + Recall)
```

### Per-Tag Metrics

Track accuracy for each tag separately to identify problem tags.

---

## 🚀 Implementation Priority

Based on ROI (accuracy improvement vs. implementation effort):

1. **🔥 High Priority** (Do these first):
   - Few-shot learning with examples (Strategy #1)
   - Lower temperature to 0.1 (Strategy #8)
   - Tag validation rules (Strategy #7)
   - Confidence thresholds (Strategy #3)

2. **⚡ Medium Priority**:
   - Chain-of-thought reasoning (Strategy #2)
   - Enhanced context (Strategy #9)
   - Tag hierarchy refinement (Strategy #11)

3. **💡 Long-term**:
   - Dynamic few-shot from corrections (Strategy #5)
   - Multi-pass analysis (Strategy #4)
   - Per-tag evaluation metrics (Strategy #12)

---

## 📝 Testing Workflow with CSV Export

1. **Export baseline**: Run current model, export 20 emails to CSV
2. **Manual annotation**: Fill in "Expected Tags" column
3. **Calculate metrics**: Count false positives/negatives
4. **Apply improvement**: Implement one strategy from above
5. **Re-test**: Export again, compare metrics
6. **Iterate**: Repeat until accuracy is acceptable

---

## 🎯 Expected Results

| Strategy Combination | Expected Accuracy | Implementation Time |
|---------------------|-------------------|---------------------|
| Baseline (current) | ~60-70% | - |
| + Few-shot examples | ~75-85% | 2 hours |
| + Lower temperature | ~80-88% | 5 minutes |
| + Tag validation | ~83-90% | 1 hour |
| + Chain-of-thought | ~85-92% | 2 hours |
| + All strategies | ~90-95% | 1-2 days |

**Note**: 100% accuracy is unrealistic even for humans. 90-95% is excellent for automated tagging.

---

## 💡 Quick Wins (Can Implement Now)

### 1. Lower Temperature
```swift
options: OllamaOptions(temperature: 0.1, num_predict: 512)
```

### 2. Add 5 Example Emails to Prompt
See Strategy #1 above for code.

### 3. Add Tag Validation
See Strategy #7 above for code.

**These 3 changes alone should boost accuracy from ~65% to ~80%.**

---

## Next Steps

1. Use the new CSV export tool to establish baseline accuracy
2. Implement the "Quick Wins" above
3. Re-export and measure improvement
4. Iterate with additional strategies as needed

Good luck! 🚀
