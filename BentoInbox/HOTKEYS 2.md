# Keyboard Shortcuts for BentoInbox

## Training View Hotkeys

When categorizing emails in the Training View, you can use these keyboard shortcuts for faster workflow:

### Category Assignment

| Key | Action | Category |
|-----|--------|----------|
| **1** | Assign to P1 | Needs Attention (Red) 🔴 |
| **2** | Assign to P2 | Can Wait (Orange) 🟠 |
| **3** | Assign to P3 | Newsletters/Automated (Green) 🟢 |
| **4** | Assign to P4 | Junk (Gray) ⚫ |

### Navigation

| Key | Action |
|-----|--------|
| **Space** | Skip current email ⭐ Primary |
| **S** | Skip current email (alternative) |

## Visual Hints in UI

The Training View shows subtle reminders:
- **Top right**: "Hotkeys: 1-4 to categorize • Space to skip"
- **Category buttons**: Small numbered badges (1, 2, 3, 4)
- **Skip button**: Space bar symbol (⎵)

## How It Works

When you're in the Training View:
1. Review the email content
2. Press **1**, **2**, **3**, or **4** to instantly categorize
3. The email is saved and the next one loads automatically
4. Press **Space** to skip an email without categorizing

## Tips for Fast Training

1. **Keep your hand on the number keys** - Most emails will fall into one of the four priorities
2. **Use Space to skip quickly** - When you're unsure, skip and come back later
3. **Build muscle memory** - After a few emails, you'll categorize without thinking
4. **Watch your progress bar** - The goal is 100 categorized emails for ML training

## Platform Support

These hotkeys work on:
- ✅ **macOS** - Full keyboard support
- ✅ **iPadOS** (with external keyboard)
- ⚠️ **iOS** - Limited (no physical keyboard on most devices)

## Implementation Details

The hotkeys use SwiftUI's `.onKeyPress()` modifier introduced in iOS 17+ and macOS 14+.

### Key Features:
- **Instant feedback** - Key presses are captured immediately
- **Context-aware** - Only works when viewing an uncategorized email
- **Non-blocking** - Won't interfere with other text input
- **Accessibility-friendly** - Works alongside VoiceOver and other assistive technologies

## Training Workflow Example

```
Email 1: Newsletter from Substack
→ Press "3" (P3: Newsletters) ✓

Email 2: Boss needs response ASAP  
→ Press "1" (P1: Needs Attention) ✓

Email 3: Promotional spam
→ Press "4" (P4: Junk) ✓

Email 4: Not sure yet...
→ Press "Space" (Skip) ⏭

Email 5: Meeting reminder
→ Press "2" (P2: Can Wait) ✓
```

With hotkeys, you can categorize **100+ emails in under 10 minutes**! 🚀

---

**Pro Tip:** The faster you categorize, the sooner you can train your ML model and get automated predictions! 🧠
