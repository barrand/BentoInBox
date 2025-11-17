# Training View UI - Hotkey Hints

## Visual Layout

```
┌─────────────────────────────────────────────────────────────┐
│ Training Progress                              42 / 100     │
│ ████████████████░░░░░░░░░░░░░░░░░░░░░░░                    │
│ 58 more to reach your goal                                  │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│ Email 23 of 58      Hotkeys: 1-4 to categorize • Space to skip│
│ ─────────────────────────────────────────────────────────── │
│ Date:                                                        │
│ November 17, 2025                                           │
│ 2:30 PM                                                     │
│ ─────────────────────────────────────────────────────────── │
│ From:                                                        │
│ newsletter@substack.com                                     │
│ ─────────────────────────────────────────────────────────── │
│ Subject:                                                     │
│ Your weekly tech roundup                                    │
│ ─────────────────────────────────────────────────────────── │
│ Content:                                                     │
│ Here are this week's top stories in technology...           │
│                                                             │
│ (scrollable content)                                        │
│                                                             │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│ [🔴 P1: Needs Attention ①] [🟠 P2: Can Wait ②]              │
│ [🟢 P3: Newsletters ③] [⚫ P4: Junk ④]      [Skip ⎵]       │
└─────────────────────────────────────────────────────────────┘
```

## UI Elements Explained

### 1. Top Right Hint (Very Small)
```
Hotkeys: 1-4 to categorize • Space to skip
```
- Font: `.caption2` (very small)
- Color: `.tertiary` (subtle gray)
- Position: Top right of email content area

### 2. Category Button Badges
```
[🔴 P1: Needs Attention ①]
                        ^^
                Small numbered badge
```
- Font: 9pt, medium weight
- Style: Small pill-shaped badge
- Color: Secondary text on primary background
- Subtle but visible

### 3. Skip Button
```
[Skip ⎵]
      ^^
Space bar symbol
```
- Shows the space bar symbol (⎵)
- Font: `.caption2` for the symbol
- Matches the visual style of category badges

## Design Philosophy

**Subtle but Discoverable:**
- Hints are small enough not to clutter the UI
- Visible enough for new users to discover
- Styled to look like keyboard keys
- Consistent visual language throughout

**Progressive Disclosure:**
- Top hint introduces the concept
- Category badges reinforce individual keys
- Skip button shows alternative interaction
- User learns by seeing, then by doing

## Color & Typography

### Hotkey Hints
- Font size: 9-11pt
- Weight: Medium
- Color: Secondary (gray)
- Background: Primary with 10% opacity
- Border radius: 3px

### Skip Button
- Style: Plain button (no heavy styling)
- Background: Secondary with 10% opacity
- Hover: Slight highlight
- Active: Darker background

### Top Reminder
- Font: System caption2
- Color: Tertiary (very light gray)
- No background
- Right-aligned

## Accessibility

All hotkey hints are:
- **Screen reader friendly** - Don't interfere with VoiceOver
- **High contrast** - Meet WCAG AA standards
- **Non-intrusive** - Don't block content
- **Keyboard-first** - Support keyboard navigation

## Future Enhancements

Possible additions:
- [ ] Tooltip on hover explaining hotkeys
- [ ] Settings to hide/show hints
- [ ] Animated hint on first visit
- [ ] Keyboard shortcut help panel (⌘?)
- [ ] Custom keybinding configuration
