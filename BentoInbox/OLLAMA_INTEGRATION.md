# Ollama Integration Guide

## Overview

Your app now supports **Ollama** for LLM-powered email analysis! You can choose from any model you've installed and switch between them easily.

---

## 🏷️ **Predefined Tag System**

BentoInbox uses a **fixed set of 12 tags** that the AI chooses from. The AI cannot create new tags - this keeps your inbox organized and consistent!

### **Available Tags:**

| Tag | Color | When to Use |
|-----|-------|-------------|
| `personal-sender` | 💗 Pink | Real person in your contacts or clearly personal |
| `urgent` | 🔴 Red | Time-sensitive, needs immediate attention |
| `question` | 🟠 Orange | Someone asking you something |
| `action-required` | 🟠 Orange | You need to do something |
| `meeting` | 🔵 Blue | Meeting invites, calendar events |
| `travel` | 🟣 Purple | Travel, flights, hotels, reservations |
| `financial` | 🟢 Green | Money, invoices, payments |
| `work-project` | 🟣 Indigo | Work-related projects |
| `newsletter` | ⚫ Gray | Newsletters, bulk emails |
| `receipt` | 🔵 Teal | Purchase confirmations, order receipts |
| `social` | 🔵 Cyan | Social media notifications |
| `general` | ⚪ Secondary | Everything else |

**Note:** Each email gets **1-3 tags** maximum. The AI picks the most relevant ones.

---

## 🚀 **Quick Start**

### 1. **Check Ollama is Running**

```bash
# Start Ollama server (if not already running)
ollama serve
```

Leave this running in the background.

### 2. **List Your Installed Models**

```bash
# See what models you have
ollama list
```

Example output:
```
NAME                    SIZE     MODIFIED
llama3.1:8b            4.7 GB   2 hours ago
qwen2.5:7b             4.4 GB   1 day ago
mistral:7b             4.1 GB   3 days ago
```

### 3. **Enable Ollama in BentoInbox**

1. Open BentoInbox
2. Click **Categories** button (tag icon)
3. Toggle **"Use Ollama for Analysis"** ✅ ON
4. Select your model from dropdown
5. **Restart the app** for changes to take effect

### 4. **Test It**

1. Go back to inbox
2. Open an email
3. Wait ~2-5 seconds
4. See improved tags and summary! 🎉

---

## 📊 **Model Selector UI**

When you open **Categories** view, you'll see:

```
┌─────────────────────────────────────┐
│ LLM SETTINGS                        │
├─────────────────────────────────────┤
│ ✅ Use Ollama for Analysis      🟢 │
│                                     │
│ Model:                              │
│ ┌─────────────────────────────┐    │
│ │ llama3.1:8b          4.7 GB │ ▼  │
│ ├─────────────────────────────┤    │
│ │ qwen2.5:7b           4.4 GB │    │
│ │ mistral:7b           4.1 GB │    │
│ └─────────────────────────────┘    │
│                                     │
│ 3 models installed                  │
│                                     │
│ Restart app after changing models   │
└─────────────────────────────────────┘
```

**Status Indicators:**
- 🟢 Green dot = Ollama is running
- 🔴 Red dot = Ollama not running (but enabled)
- No dot = Ollama disabled

---

## 🎯 **Choosing the Right Model**

### **Recommended Models for Email Analysis**

| Model | Size | Speed | Quality | Best For |
|-------|------|-------|---------|----------|
| **llama3.1:8b** ⭐️ | 4.7GB | 2-3s | Excellent | **Best all-around** |
| **qwen2.5:7b** | 4.4GB | 2s | Excellent | Structured output |
| **mistral:7b** | 4.1GB | 2s | Very Good | Fast & accurate |
| **llama3.2:3b** | 2GB | 1s | Good | Budget/speed |
| **llama3.1:70b** | 40GB | 10s | Best | Max quality (needs 64GB RAM) |

### **Quick Comparison**

**For Most Users:**
```bash
ollama pull llama3.1:8b
```
- Best balance of speed and quality
- Works great for email tagging
- Needs 8GB RAM minimum

**For Speed:**
```bash
ollama pull llama3.2:3b
```
- Fastest analysis (~1 second)
- Good enough for simple tagging
- Needs 4GB RAM minimum

**For Maximum Quality:**
```bash
ollama pull llama3.1:70b
```
- Best possible results
- State-of-the-art understanding
- Needs 64GB RAM (M3 Max or better)

---

## 🔧 **How to Install New Models**

### **Install a Model**

```bash
# Install llama3.1 (8B parameters)
ollama pull llama3.1:8b

# Install qwen (excellent for structured output)
ollama pull qwen2.5:7b

# Install mistral (fast and accurate)
ollama pull mistral:7b

# Install tiny model (for testing/speed)
ollama pull llama3.2:3b
```

### **Check Installation**

```bash
ollama list
```

### **Remove a Model** (if you need space)

```bash
ollama rm mistral:7b
```

---

## ⚙️ **How It Works**

### **1. Detection on Startup**

When you start BentoInbox:
```swift
// Check if user enabled Ollama
let useOllama = UserDefaults.standard.bool(forKey: "useOllama")
let selectedModel = UserDefaults.standard.string(forKey: "ollamaModel")

if useOllama && ollamaIsRunning {
    // Use Ollama with selected model
    llmService = OllamaLLMAnalysisService(model: selectedModel)
} else {
    // Fall back to Mock service
    llmService = MockLLMAnalysisService()
}
```

### **2. Email Analysis**

When you open an email:
```
1. Extract email content (subject, body, sender)
2. Check if sender is in Contacts
3. Build prompt with instructions + allowed tag list
4. Send to Ollama API (http://localhost:11434)
5. Parse JSON response
6. ✅ Validate tags against allowed list (filter out any invalid tags)
7. Cache results in database
8. Display tags and summary
```

### **3. Tag Validation**

The app **strictly enforces** the predefined tag list:
- ✅ AI is told to only use specific tags
- ✅ If AI makes up a new tag, it's automatically filtered out
- ✅ If all tags are invalid, defaults to `"general"`
- ⚠️ Invalid tags are logged (visible in Console.app)

Example log:
```
⚠️ LLM used invalid tags (ignored): deadline, invoices, todo
```

This ensures your tags stay **consistent and predictable** across all emails!

### **4. Caching**

- Each email is analyzed **once**
- Results stored in `EmailTag` and `EmailAnalysis` tables
- Subsequent opens are **instant** (no re-analysis)
- Clear cache to re-analyze with different model

---

## 🎨 **Quality Comparison**

### **Example Email:**

```
From: Sarah Johnson <sarah@company.com>
Subject: Q4 Budget Review - Need your input by Friday
Body: Hey, can you take a look at the attached Q4 
projections and let me know your thoughts? We need 
to finalize this by end of week for the board meeting.
```

### **Mock Service Results:**

```
Tags: ["question", "general"]
Summary: "Email about: Q4 Budget Review - Need your input by Friday"
Intent: "question"
Urgency: "normal"
Requires Response: true
```

### **Ollama (llama3.1:8b) Results:**

```
Tags: ["personal-sender", "financial", "question"]
Summary: "Colleague requesting feedback on Q4 financial 
         projections for Friday board meeting"
Intent: "action-required"
Urgency: "soon"
Requires Response: true
Is Actionable: true
Has Deadline: true
Mentions Money: true
```

**Much better! 🎯**

**Note:** Tags are now limited to 1-3 per email, chosen from the predefined set of 12 tags. This keeps your inbox organized and prevents tag explosion!

---

## 🐛 **Troubleshooting**

### **"Ollama not running"**

**Problem:** Toggle is ON but shows red dot

**Solution:**
```bash
# Start Ollama server
ollama serve

# In BentoInbox, click "Check Ollama Status"
```

### **"No models available"**

**Problem:** Dropdown is empty

**Solution:**
```bash
# Install a model
ollama pull llama3.1:8b

# Restart BentoInbox
```

### **"Failed to parse LLM response"**

**Problem:** Analysis fails with JSON parsing error

**Solution:**
- Some models don't follow JSON format well
- Try a different model (qwen2.5 is excellent for structured output)
- Or clear tags and retry

### **"Analysis takes too long"**

**Problem:** 10+ seconds per email

**Solution:**
- You might be using a large model (70b)
- Switch to smaller model (8b or 3b)
- Check RAM usage (might be swapping)

### **"Too many different tags / tag explosion"**

**Problem:** AI keeps creating new tags

**Solution:**
✅ **This is now fixed!** The app enforces a predefined set of 12 tags:
- `personal-sender`, `urgent`, `question`, `action-required`
- `meeting`, `travel`, `financial`, `work-project`
- `newsletter`, `receipt`, `social`, `general`

If the AI tries to use other tags, they're automatically filtered out. You'll see a warning in Console.app:
```
⚠️ LLM used invalid tags (ignored): deadline, invoice, todo
```

To clear old invalid tags from your database, you can delete and re-analyze emails.

### **"Model not found"**

**Problem:** Selected model doesn't exist

**Solution:**
```bash
# Install the model
ollama pull llama3.1:8b

# Restart BentoInbox
```

---

## 📈 **Performance Tips**

### **1. Choose the Right Model Size**

| Your Mac | Recommended Model |
|----------|-------------------|
| 8GB RAM | llama3.2:3b |
| 16GB RAM | llama3.1:8b ⭐️ |
| 32GB RAM | mistral:7b or qwen2.5:7b |
| 64GB+ RAM | llama3.1:70b |

### **2. Let Ollama Warm Up**

First request is slower (~5s), subsequent requests faster (~2s).

### **3. Batch Analysis**

Don't analyze all emails at once - only when you open them.

### **4. Cache Aggressively**

Already implemented! Each email analyzed once.

---

## 🔄 **Switching Models**

### **Steps:**

1. **Go to Categories view**
2. **Select new model** from dropdown
3. **Restart BentoInbox** (required for changes to take effect)
4. **(Optional) Clear tags** to re-analyze existing emails

### **When to Switch:**

**Switch to larger model:**
- Want better accuracy
- Edge cases not handled well
- Summaries not coherent

**Switch to smaller model:**
- Analysis too slow
- Running out of RAM
- Don't need perfect accuracy

---

## 🎛️ **Advanced: Custom Prompts & Tags**

### **Customizing the Tag List**

Want different tags? You can modify the predefined list in `Services.swift`:

```swift
// In OllamaLLMAnalysisService class
static let allowedTags = [
    "personal-sender",
    "urgent",
    "question",
    // ... add your custom tags here!
    "legal",           // Add this for legal emails
    "engineering",     // Add this for technical emails
    "customer-support" // Add this for support tickets
]
```

**After modifying tags:**
1. Update the tag colors in `Views.swift` → `tagColor(for:)` function
2. Clear existing email analysis (so they get re-tagged)
3. Restart the app

### **Customizing the Prompt**

You can modify the prompt in `Services.swift` → `OllamaLLMAnalysisService` → `analyzeEmail()`:

```swift
let prompt = """
Analyze this email and extract structured information...

YOUR CUSTOM INSTRUCTIONS HERE

Return JSON with these EXACT fields:
{ ... }
"""
```

**Ideas for customization:**
- Add domain-specific tags (e.g., "legal", "hr", "engineering")
- Change summary style (e.g., "action-oriented", "technical")
- Add custom fields (e.g., "sentiment", "priority_score")
- Adjust tag count (currently 1-3, could increase to 5)

---

## 💡 **Tips for Best Results**

### **1. Use Contacts**

Ollama checks if sender is in your Contacts for better `personal-sender` detection.

### **2. Clear Tags When Switching Models**

Different models = different results. Clear cache to re-analyze.

### **3. Give Feedback**

If tags are wrong, re-categorize the email. Future ML model will learn from this!

### **4. Experiment with Models**

Try different models to see which works best for your email style.

### **5. Monitor Performance**

Check Console.app for Ollama logs:
```
✅ Using Ollama (llama3.1:8b) for LLM analysis
```

---

## 📊 **Model Recommendations by Use Case**

### **Personal Email** (friends, family)
- **qwen2.5:7b** - Excellent at understanding casual language
- Fast, accurate, good with personal tone

### **Work Email** (colleagues, clients)
- **llama3.1:8b** ⭐️ - Best all-around
- Handles formal language, meeting requests, deadlines

### **Mixed Email** (everything)
- **llama3.1:8b** ⭐️ - Most versatile
- Good balance of speed and quality

### **Budget/Testing**
- **llama3.2:3b** - Fast and cheap
- Good enough for basic tagging

### **Maximum Quality** (money no object)
- **llama3.1:70b** - Best possible
- Requires 64GB+ RAM, Mac Studio or better

---

## 🔮 **Future Enhancements**

### **Coming Soon:**

- **Live model switching** (no restart required)
- **Model comparison** (A/B test different models)
- **Custom prompts UI** (edit prompts in app)
- **Performance metrics** (see analysis time, token usage)
- **Model recommendations** (based on your email patterns)

---

## 📝 **Summary**

### **What You Can Do:**

✅ **Choose any Ollama model** you've installed
✅ **Switch models** anytime via dropdown
✅ **See model sizes** to make informed choices
✅ **Status indicator** shows if Ollama is running
✅ **Automatic fallback** to Mock if Ollama unavailable

### **How to Use:**

1. Install Ollama models: `ollama pull llama3.1:8b`
2. Start Ollama: `ollama serve`
3. Enable in app: Categories → Toggle ON
4. Select model: Choose from dropdown
5. Restart app
6. Open emails and see better results! 🎉

### **Best Practice:**

**Start with `llama3.1:8b`** - it's the best balance of speed and quality for email analysis. You can always try others later!

```bash
ollama pull llama3.1:8b
ollama serve
# Then enable in app
```

**Happy tagging! 🏷️✨**
