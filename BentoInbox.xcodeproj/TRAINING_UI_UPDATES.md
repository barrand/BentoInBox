# Training UI Updates

## Changes Made

### 1. Category Reset Functionality

Added a "Reset to P1-P4" button in the Categories view that allows you to clear all old categories and start fresh with the new P1-P4 priority system.

**How to use:**
1. Navigate to Categories view (from toolbar)
2. Click "Reset to P1-P4" button
3. Confirm the action

**What it does:**
- Deletes all existing categories
- Clears all user category assignments on messages
- Removes all training examples
- Creates fresh P1-P4 categories:
  - P1 - Needs Attention (Red)
  - P2 - Can Wait (Orange)
  - P3 - Newsletter/Automated (Green)
  - P4 - Pure Junk (Gray)

### 2. Enhanced Keyboard Shortcuts Display

The Training View now shows a prominent keyboard shortcuts help section (macOS only) that displays:

**Visual Layout:**
```
┌─────────────────────────────────────────────────────┐
│  ⌨️  Keyboard Shortcuts                             │
│                                                      │
│  [1-4]    Assign to category                        │
│  [Space]  Skip this email                           │
│                                                      │
│  [⌘Z or U]  Undo last action                        │
│  [J or ↓]   Skip to next                            │
└─────────────────────────────────────────────────────┘
```

**Features:**
- Keyboard icon for visibility
- Monospaced key labels in styled boxes
- Clear descriptions for each shortcut
- Positioned prominently above category buttons
- Only shows on macOS (iOS shows simpler tap instructions)

### 3. Improved Category Button Display

Each category button now shows:
- Larger, more prominent icon
- Category name in headline font
- Colored badge showing the number key to press (e.g., "1" in blue badge)
- "to assign" helper text

**Example button appearance:**
```
┌────────────────────────────────────┐
│  ❗️  P1 - Needs Attention          │
│      [1] to assign                 │
└────────────────────────────────────┘
```

## User Experience Improvements

### Before:
- Old category names (Important, Family/Friends, School, etc.)
- Small hint text "Press 1" below category name
- Generic text "Press number key or click to categorize"
- No comprehensive shortcuts reference

### After:
- Clean P1-P4 priority system
- Prominent keyboard shortcuts reference panel
- Color-coded number badges on each button
- Professional, polished appearance
- Easy-to-find reset option for categories

## Technical Details

### New Functions
- `SeedCategoryLoader.resetToP1P4System()`: Comprehensive reset of category system
- `shortcutRow()`: Helper view for displaying keyboard shortcuts consistently

### Updated Views
- `CategoriesView`: Added reset button with confirmation dialog
- `TrainingView`: Enhanced keyboard shortcuts display section
- Category buttons: Improved visual hierarchy and clarity

### Data Cleanup
When resetting categories:
1. Clears `userCategoryId` on all messages
2. Clears `predictedCategoryId` and `predictedConfidence` on all messages
3. Deletes all `TrainingExample` records
4. Deletes all `Category` records
5. Creates fresh P1-P4 categories

## Migration Path

For users with existing data:

1. **Navigate to Categories view**
2. **Click "Reset to P1-P4"**
3. **Confirm the reset** (warning explains data will be cleared)
4. **Start training** with the new P1-P4 system

This gives users a clean slate to work with the new priority-based categorization system.

## Visual Design

### Color Scheme
- **P1 Red**: #EF5350 (urgent, attention-grabbing)
- **P2 Orange**: #FFA726 (important but not critical)
- **P3 Green**: #66BB6A (safe, informational)
- **P4 Gray**: #9E9E9E (low priority, ignorable)

### Icons
- P1: exclamationmark.circle.fill (urgent indicator)
- P2: clock.fill (time-related but not immediate)
- P3: newspaper.fill (informational content)
- P4: trash.fill (disposable content)

### Typography
- Keyboard shortcuts: Monospaced font in styled boxes
- Number badges: Bold, white on accent color
- Descriptions: Secondary color for hierarchy

## Testing Checklist

- [ ] Reset button appears in Categories view toolbar
- [ ] Reset confirmation dialog shows appropriate warning
- [ ] After reset, only P1-P4 categories exist
- [ ] Keyboard shortcuts panel shows on macOS
- [ ] Keyboard shortcuts panel hidden on iOS
- [ ] Number badges appear on category buttons (macOS)
- [ ] All keyboard shortcuts work as expected
- [ ] Training view loads correctly with new categories
- [ ] Progress tracking works after reset
