# Training UI - Visual Layout

## New Training View Layout (macOS)

```
┌──────────────────────────────────────────────────────────────────┐
│  Train Model                                              ✕       │
├──────────────────────────────────────────────────────────────────┤
│                                                                   │
│  Training Progress                              23 / 100          │
│  ████████████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ 23%            │
│  77 more for a good baseline model                               │
│                                                                   │
├──────────────────────────────────────────────────────────────────┤
│                                                                   │
│  From                                                            │
│  newsletter@example.com                                          │
│                                                                   │
│  ─────────────────────────────────────────────────              │
│                                                                   │
│  Subject                                                         │
│  Weekly Newsletter - What's New This Week                        │
│                                                                   │
│  ─────────────────────────────────────────────────              │
│                                                                   │
│  Preview                                                         │
│  Here's what happened this week in tech: Apple announces        │
│  new products, major security updates, and more...               │
│                                                                   │
│                                                                   │
├──────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  📋  Category Definitions                                  │ │
│  │                                                            │ │
│  │  [1] P1 - Needs Attention                                 │ │
│  │      Urgent, requires immediate response                  │ │
│  │                                                            │ │
│  │  [2] P2 - Can Wait                                        │ │
│  │      Important but not urgent                             │ │
│  │                                                            │ │
│  │  [3] P3 - Newsletter/Automated                            │ │
│  │      Informational, no response needed                    │ │
│  │                                                            │ │
│  │  [4] P4 - Pure Junk                                       │ │
│  │      Spam, unwanted, can ignore                           │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  ⌨️  Keyboard Shortcuts                                    │ │
│  │                                                            │ │
│  │  [1-4]     Assign to category                             │ │
│  │  [Space]   Skip this email                                │ │
│  │                                                            │ │
│  │  [⌘Z or U] Undo last action                               │ │
│  │  [J or ↓]  Skip to next                                   │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                   │
│  ┌─────────────────────────────────┐ ┌──────────────────────┐  │
│  │  ❗️  P1 - Needs Attention       │ │  ⏰  P2 - Can Wait   │  │
│  │      [1] to assign               │ │      [2] to assign   │  │
│  └─────────────────────────────────┘ └──────────────────────┘  │
│                                                                   │
│  ┌─────────────────────────────────┐ ┌──────────────────────┐  │
│  │  📰  P3 - Newsletter/Automated  │ │  🗑️  P4 - Pure Junk  │  │
│  │      [3] to assign               │ │      [4] to assign   │  │
│  └─────────────────────────────────┘ └──────────────────────┘  │
│                                                                   │
│                    [Skip ➡️]  [Undo ↩️]                          │
│                                                                   │
└──────────────────────────────────────────────────────────────────┘
```

## Key Features in New Layout

### 1. Category Definitions Box (NEW!)
- Green clipboard icon for visibility
- Clear number badges [1], [2], [3], [4] color-coded
- Category names in bold
- Brief, actionable descriptions
- Positioned above keyboard shortcuts

### 2. Keyboard Shortcuts Box (Existing, Improved)
- Blue keyboard icon
- Monospaced key labels in styled boxes
- Clear action descriptions
- Easy to scan layout

### 3. Color-Coded Number Badges
Each category definition uses a color-coded badge:
- **[1]** - Red background (P1 - urgent)
- **[2]** - Orange background (P2 - important)
- **[3]** - Green background (P3 - informational)
- **[4]** - Gray background (P4 - junk)

### 4. Category Button Display
Each button shows:
- Large icon with semantic meaning
- Category name
- Number badge in accent color
- "to assign" helper text

## Mobile Layout (iOS/iPadOS)

```
┌─────────────────────────────────┐
│  < Back    Train Model          │
├─────────────────────────────────┤
│  Progress: 23 / 100             │
│  ████████░░░░░░░░░░░ 23%        │
│  77 more to go                  │
├─────────────────────────────────┤
│                                 │
│  From:                          │
│  newsletter@example.com         │
│                                 │
│  Subject:                       │
│  Weekly Newsletter              │
│                                 │
│  Preview:                       │
│  Here's what happened...        │
│                                 │
├─────────────────────────────────┤
│  Tap a category to assign       │
│                                 │
│  ┌────────────────────────────┐│
│  │ ❗️ P1 - Needs Attention   ││
│  │ Urgent, immediate response ││
│  └────────────────────────────┘│
│                                 │
│  ┌────────────────────────────┐│
│  │ ⏰ P2 - Can Wait           ││
│  │ Important but not urgent   ││
│  └────────────────────────────┘│
│                                 │
│  ┌────────────────────────────┐│
│  │ 📰 P3 - Newsletter/Auto    ││
│  │ Informational only         ││
│  └────────────────────────────┘│
│                                 │
│  ┌────────────────────────────┐│
│  │ 🗑️  P4 - Pure Junk         ││
│  │ Spam, can ignore           ││
│  └────────────────────────────┘│
│                                 │
│      [Skip]      [Undo]         │
└─────────────────────────────────┘
```

## Design Rationale

### Why Category Definitions at Top?
1. **First-time users** need to understand what P1-P4 mean
2. **Reference while training** - no need to remember definitions
3. **Consistency** - ensures everyone categorizes the same way
4. **Reduces mistakes** - clear guidance prevents mis-categorization

### Color Coding System
- **Red (P1)**: Universal signal for urgent/important
- **Orange (P2)**: Warning color, needs attention but not critical
- **Green (P3)**: Safe, informational, no action needed
- **Gray (P4)**: Neutral, ignorable, low value

### Information Hierarchy
1. Progress (top) - motivational, shows advancement
2. Email content (middle) - what you're categorizing
3. Definitions & shortcuts (above buttons) - reference material
4. Category buttons (bottom) - action items
5. Helper buttons (very bottom) - secondary actions

## Accessibility Considerations

- **High contrast** color badges for visibility
- **Clear typography** with appropriate sizing
- **Semantic icons** that convey meaning
- **Text descriptions** supplement color coding
- **Keyboard shortcuts** for power users
- **Touch targets** appropriately sized for mobile

## Implementation Notes

The layout uses:
- `GroupBox` for definition and shortcut sections
- `LazyVGrid` for responsive category button layout
- Color-coded badges using `.background()` modifiers
- SF Symbols for all icons
- Platform-specific layouts with `#if os(macOS)`
