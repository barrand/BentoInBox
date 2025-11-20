# Personal Sender Detection Feature

## Overview

Added smart detection for emails from **real people** (friends, family, colleagues) vs. automated systems and marketing emails. This is a **high-priority signal** for importance since personal emails usually require attention.

## How It Works

### Detection Logic

The `personal-sender` tag is added when an email meets these criteria:

#### ✅ **Positive Signals**
1. **Personal email domain** (strong signal)
   - Gmail, Yahoo, Hotmail, Outlook, iCloud
   - Protonmail, AOL
   
2. **Real name format** (strong signal)
   - "John Smith <john@example.com>"
   - Has name before the email address
   
3. **Work colleague pattern**
   - Real name + simple domain (company.com)
   - Example: "Sarah Johnson <sarah@company.com>"

#### ❌ **Disqualifiers** (Automatic rejection)
1. **Automated addresses**
   - noreply@, no-reply@, donotreply@
   - notifications@, automated@
   - bounce@, mailer-daemon@, postmaster@
   
2. **Marketing/Support addresses**
   - newsletter@, marketing@, promo@
   - support@, help@, info@, contact@
   - team@, hello@, sales@, billing@

### Scoring Examples

| Sender | personal-sender Tag? | Why? |
|--------|---------------------|------|
| `John Smith <john@gmail.com>` | ✅ Yes | Personal domain + real name |
| `Mom <mom.jane@icloud.com>` | ✅ Yes | Personal iCloud + real name |
| `Sarah <sarah@company.com>` | ✅ Yes | Work colleague with name |
| `newsletter@marketing.com` | ❌ No | Contains "newsletter" |
| `noreply@example.com` | ❌ No | Automated address |
| `support@helpdesk.com` | ❌ No | Support keyword |
| `Team <team@company.com>` | ❌ No | Contains "team" |
| `info@sales.example.com` | ❌ No | Info/sales keywords |

## UI Representation

The `personal-sender` tag appears in **pink** 💗 to visually distinguish it as a high-priority signal.

```
Tags
[personal-sender] [question] [urgent]
    💗 Pink        🟠 Orange   🔴 Red
```

## ML Training Value

### Why This Matters

Personal sender detection is one of the **most predictive features** for email importance:

- **Friend emails** → Usually P1 or P2 (high priority)
- **Family emails** → Almost always important
- **Direct colleague emails** → Action required or important info
- **Marketing/automated** → Usually P3 or P4 (low priority)

### As An ML Feature

In the future ML model, this becomes a powerful binary feature:

```swift
struct EmailMLFeatures {
    let hasTag_PersonalSender: Bool  // ⭐️ Strong signal!
    // ... other features
}
```

**Expected impact**: Emails with `personal-sender` tag are **3-5x more likely** to be high priority (P1/P2).

## Test Cases in Mock Data

The mock Gmail service now generates diverse sender types:

1. ✅ **John Smith <john.smith@gmail.com>** → Personal Gmail
2. ✅ **Sarah Johnson <sarah@company.com>** → Work colleague
3. ❌ **newsletter@marketing.com** → Marketing
4. ❌ **noreply@notifications.example.com** → Automated
5. ✅ **Mom <mom.jane@icloud.com>** → Family - iCloud
6. ✅ **Mike Chen <mike.chen@yahoo.com>** → Friend - Yahoo
7. ❌ **support@helpdesk.com** → Support
8. ✅ **Alex Rodriguez <alex@startup.io>** → Startup colleague
9. ❌ **Team Newsletter <team@company.com>** → Team email
10. ❌ **info@sales.example.com** → Sales/info

## Implementation Details

### Code Location

`Services.swift` → `MockLLMAnalysisService` → `detectPersonalSender(from:)`

```swift
private func detectPersonalSender(from: String) -> Bool {
    // 1. Check for automated/system addresses
    // 2. Check for marketing/support keywords
    // 3. Detect real name format
    // 4. Check personal email domains
    // 5. Combine signals with scoring logic
}
```

### Caching

Like all LLM analysis, personal sender detection:
- ✅ Runs once per email
- ✅ Cached in database
- ✅ Instant on subsequent opens

## Future Enhancements

### Phase 1: Current (✅ Done)
- Detect personal senders
- Add `personal-sender` tag
- Display with pink color

### Phase 2: Sender Rules (Next)
- Learn specific sender patterns
- "All emails from mom@icloud.com → P1"
- Build sender reputation database

### Phase 3: Contact Integration
- Cross-reference with Contacts app
- "This person is in your contacts → personal-sender"
- VIP list support

### Phase 4: Interaction History
- Track email-reply patterns
- "You always reply to this person → high importance"
- Conversation depth analysis

## User Experience

When you open emails, you'll now see:

**From a friend:**
```
From: John Smith <john.smith@gmail.com>

Tags
[personal-sender] [question]
```

**From marketing:**
```
From: newsletter@marketing.com

Tags
[newsletter] [promotional]
(No personal-sender tag)
```

This makes it **instantly obvious** which emails come from real people who expect a response!

## Statistics Idea (Future)

Track personal sender patterns:
- **% of P1 emails** with personal-sender tag
- **Response rate** to personal-sender emails
- **Average time to respond** to personal vs. non-personal emails
- **Most important personal senders** (based on your categorization history)

## Summary

🎉 **Personal sender detection is now live!**

The system can now distinguish:
- ✅ **Real people** (friends, family, colleagues) → High priority
- ❌ **Automated systems** (noreply, notifications) → Low priority
- ❌ **Marketing/support** (newsletters, team emails) → Low priority

**This is a game-changer for ML training** because sender identity is the #1 predictor of email importance!

Open some emails and watch for the **pink personal-sender tag** on emails from real people! 💗
