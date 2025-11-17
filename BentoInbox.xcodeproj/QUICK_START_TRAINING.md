# Quick Start Guide: Resetting Categories & Training

## Step 1: Reset to P1-P4 System

If you have old categories, you'll need to reset them first:

1. **Open Categories View**
   - Click the "Categories" button in the toolbar (tag icon)

2. **Click "Reset to P1-P4"**
   - Look for the reset button in the toolbar (circular arrow icon)

3. **Confirm Reset**
   - A dialog will warn you that this clears all existing data
   - Click "Reset" to proceed

✅ **Result**: You now have fresh P1-P4 categories!

## Step 2: Start Training

1. **Open Training View**
   - Click "Train Model" in the toolbar (brain icon 🧠)

2. **Review the Email**
   - Read the sender, subject, and preview

3. **Categorize Using Keyboard**
   - Press **1** for P1 - Needs Attention (urgent)
   - Press **2** for P2 - Can Wait (important)
   - Press **3** for P3 - Newsletter/Automated (informational)
   - Press **4** for P4 - Pure Junk (ignore)

4. **Other Shortcuts**
   - **Space**: Skip this email
   - **⌘Z** or **U**: Undo last action
   - **J** or **↓**: Skip to next

5. **Track Progress**
   - Watch the progress bar at the top
   - Goal: Categorize 100 emails for a good baseline model

## Understanding the Categories

### P1 - Needs Attention (🔴 Red)
**When to use**: Email requires action soon
- Email from your boss about a deadline
- Important message from family
- School notice requiring response
- Time-sensitive work requests

### P2 - Can Wait (🟠 Orange)
**When to use**: Important but not urgent
- Regular work correspondence
- Follow-up emails you should respond to eventually
- Important but not time-critical information
- Questions that can wait a few days

### P3 - Newsletter/Automated (🟢 Green)
**When to use**: Good to read eventually, usually no response needed
- Email newsletters you subscribe to
- Automated reports and digests
- Marketing emails from companies you like
- Social media notifications

### P4 - Pure Junk (⚫ Gray)
**When to use**: Never need to read this
- Spam and phishing attempts
- Unwanted promotional emails
- Irrelevant automated messages
- Emails you wish you could unsubscribe from

## Tips for Fast Training

### Speed Tips
1. **Use number keys only** - much faster than clicking
2. **Don't overthink** - trust your gut reaction
3. **Skip if uncertain** - better than guessing wrong
4. **Do obvious ones first** - newsletters and junk are easiest to spot

### Quality Tips
1. **Be consistent** - use the same criteria each time
2. **When in doubt, go lower priority** - better to under-prioritize than over
3. **Consider the action** - what would you do with this email?
4. **Think long-term** - would you want future emails like this flagged?

## Training Session Example

Here's a typical 10-minute session:

```
Email 1: "Weekly Newsletter from Medium"
→ Press 3 (Newsletter)

Email 2: "Meeting tomorrow at 9am - confirm?"
→ Press 1 (Needs Attention)

Email 3: "Holiday sale - 50% off everything!"
→ Press 4 (Junk) or 3 (Newsletter) if you like the store

Email 4: "Can we schedule a call this week?"
→ Press 2 (Can Wait)

Email 5: "Your package has shipped"
→ Press 3 (Newsletter)

... and so on until you hit 100!
```

## After Training

Once you've categorized 100 emails:

1. **The app will celebrate** 🎉
2. **You can continue training** (more = better accuracy)
3. **Or start using the model** for predictions

The hybrid approach means:
- CoreML model categorizes most emails quickly
- LLM validates uncertain predictions
- You can still manually correct mistakes

## Troubleshooting

**Q: I don't see P1-P4 categories**
→ Go to Categories view and click "Reset to P1-P4"

**Q: Keyboard shortcuts aren't working**
→ Make sure the training view has focus (click on it)

**Q: I made a mistake**
→ Press ⌘Z or U to undo

**Q: Should I skip uncertain emails?**
→ Yes! Skipping is better than guessing wrong. You can categorize them later.

**Q: How many emails should I really train on?**
→ Minimum 100 for basic model, 200-500 for good accuracy

**Q: Can I change a category after training?**
→ Yes! Just categorize it again from the inbox view

## Visual Reference

### Training View Layout
```
┌────────────────────────────────────────────┐
│  Progress: 23/100                          │
│  [████████░░░░░░░░░░] 23%                  │
│  77 more for a good baseline               │
├────────────────────────────────────────────┤
│                                            │
│  From: newsletter@example.com              │
│  Subject: Weekly Updates                   │
│  Preview: Here's what happened...          │
│                                            │
├────────────────────────────────────────────┤
│  ⌨️  Keyboard Shortcuts                    │
│  [1-4] Assign   [Space] Skip              │
│  [⌘Z]  Undo     [J/↓]   Next              │
├────────────────────────────────────────────┤
│  [❗️ P1 - Needs Attention]    [1]         │
│  [⏰ P2 - Can Wait]            [2]         │
│  [📰 P3 - Newsletter/Auto]     [3]         │
│  [🗑️  P4 - Pure Junk]          [4]         │
└────────────────────────────────────────────┘
```

Happy training! 🚀
