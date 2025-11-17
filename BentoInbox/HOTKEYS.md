# Keyboard Shortcuts for BentoInbox

## Reading Pane Hotkeys

When viewing emails in the detail pane, you can use these keyboard shortcuts to quickly categorize messages:

### Category Assignment

| Key | Action | Category |
|-----|--------|----------|
| **1** | Assign to P1 | Needs Attention (Red) 🔴 |
| **2** | Assign to P2 | Can Wait (Orange) 🟠 |
| **3** | Assign to P3 | Newsletters/Automated (Green) 🟢 |
| **4** | Assign to P4 | Junk (Gray) ⚫ |

## Visual Hints in UI

The Message Detail View shows subtle reminders:
- **Top of form**: "Hotkeys: 1-4 to categorize"
- **Category picker**: Small numbered badges (1, 2, 3, 4) next to each P-category

## How It Works

When you're viewing an email in the detail pane:
1. Read the email content
2. Press **1**, **2**, **3**, or **4** to instantly categorize
3. The category is assigned and saved automatically
4. A training example is recorded for future ML model training
5. Select another email from the list to continue

## Training While You Work

**You don't need a separate training screen!** Every time you categorize an email, you're training the model:

1. **View email** in the inbox
2. **Categorize with hotkey** (1-4)
3. **Training example saved** automatically
4. **Move to next email**
5. Repeat until you reach 100+ categorized emails

## Tips for Fast Categorization

1. **Keep your hand on the number keys** - Makes categorization instant
2. **Use arrow keys or click** - Navigate between emails quickly
3. **Build muscle memory** - After a few emails, it becomes automatic
4. **Filter by "Uncategorized"** - Focus on emails that need categorization
5. **Watch your progress** - Check how many training examples you've created

## Platform Support

These hotkeys work on:
- ✅ **macOS** - Full keyboard support
- ✅ **iPadOS** (with external keyboard)
- ⚠️ **iOS** - Limited (no physical keyboard on most devices)

## Implementation Details

The hotkeys use SwiftUI's `.onKeyPress()` modifier introduced in iOS 17+ and macOS 14+.

### Key Features:
- **Instant feedback** - Key presses are captured immediately
- **Context-aware** - Only works when viewing an email
- **Non-blocking** - Won't interfere with other text input
- **Automatic training** - Every categorization creates a training example
- **Accessibility-friendly** - Works alongside VoiceOver

## Workflow Example

```
Select email from list: Newsletter from Substack
→ Press "3" (P3: Newsletters) ✓
→ Training example saved automatically

Select email from list: Boss needs response ASAP  
→ Press "1" (P1: Needs Attention) ✓
→ Training example saved automatically

Select email from list: Promotional spam
→ Press "4" (P4: Junk) ✓
→ Training example saved automatically

Select email from list: Meeting reminder
→ Press "2" (P2: Can Wait) ✓
→ Training example saved automatically
```

With hotkeys, you can categorize **100+ emails in under 10 minutes** while naturally working through your inbox! 🚀

## Checking Your Progress

To see how many emails you've categorized (training examples):

1. Check your SwiftData database
2. Or add a simple counter in the UI (future enhancement)
3. Goal: 100+ categorized emails for basic ML model

## Future Enhancements

Potential additions:
- [ ] **Training progress indicator** in toolbar
- [ ] **Cmd+Z** - Undo last categorization
- [ ] **Arrow keys** - Navigate between emails without clicking
- [ ] **Cmd+Delete** - Archive/delete emails
- [ ] **Custom keybindings** - User-configurable shortcuts

---

**Pro Tip:** The faster you categorize, the sooner you can train your ML model and get automated predictions! 🧠
