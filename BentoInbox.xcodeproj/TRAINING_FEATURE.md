# Training Feature Documentation

## Overview
A comprehensive training UI for manually categorizing emails to build a machine learning dataset. This feature implements the P1-P4 priority categorization system and provides an efficient interface for labeling emails.

## Priority Categories (P1-P4)

### P1 - Needs Attention (Red #EF5350)
- **Purpose**: Emails requiring immediate read and response
- **Icon**: exclamationmark.circle.fill
- **Examples**: Urgent work emails, time-sensitive requests, important family matters

### P2 - Can Wait (Orange #FFA726)
- **Purpose**: Important emails that need response eventually, but not urgent
- **Icon**: clock.fill
- **Examples**: Standard work correspondence, follow-ups, non-urgent questions

### P3 - Newsletter/Automated (Green #66BB6A)
- **Purpose**: Informational content good to read eventually, usually no response needed
- **Icon**: newspaper.fill
- **Examples**: Newsletters, automated reports, promotional emails from trusted sources

### P4 - Pure Junk (Gray #9E9E9E)
- **Purpose**: Emails to ignore or archive immediately
- **Icon**: trash.fill
- **Examples**: Spam, unwanted promotions, irrelevant automated emails

## Training UI Features

### Progress Tracking
- **Visual progress bar**: Shows training progress toward the 100-email goal
- **Counter display**: "X / 100" clearly shows how many emails have been categorized
- **Motivational messaging**: Displays remaining count with encouraging text
- **Goal completion alert**: Celebrates when reaching the target goal

### Smart Sampling
- Prioritizes uncategorized messages
- Fetches up to 500 emails for training
- Sorted by date (most recent first) for relevance

### Keyboard Shortcuts (macOS)

| Key | Action |
|-----|--------|
| 1-4 | Assign to category P1-P4 |
| Space | Skip current email |
| Cmd+Z or U | Undo last categorization |
| J or ↓ | Skip to next email |

### UI Components

#### Progress Header
- Shows current progress (X/Y format)
- Linear progress bar visualization
- Contextual message about training status

#### Message Display
- **From**: Sender information
- **Subject**: Email subject line
- **Preview**: Email snippet/preview text
- All text is selectable for easy copying

#### Category Buttons
- Large, clickable buttons for each category
- Color-coded icons matching category theme
- Keyboard shortcut hints displayed on buttons
- Responsive grid layout

#### Action Buttons
- **Skip**: Move to next email without categorizing
- **Undo**: Revert last categorization and go back

## Technical Implementation

### Data Models
- **TrainingExample**: Tracks each user categorization
  - Links message ID to category ID
  - Records timestamp and source ("user")
  - Used to build training dataset for CoreML

### ViewModels
- **TrainingViewModel**: Manages training state
  - Loads uncategorized messages
  - Tracks progress and history
  - Handles categorization and undo operations

### Repository Methods
- `fetchForTraining()`: Smart sampling of uncategorized emails
- `countUncategorized()`: Track remaining work
- `recordExample()`: Save training data

## Usage Flow

1. **Launch Training Mode**: Click "Train Model" in toolbar
2. **Review Email**: Read sender, subject, and preview
3. **Categorize**: Press number key (1-4) or click category button
4. **Automatic Progression**: Automatically moves to next email
5. **Undo if Needed**: Press Cmd+Z or U to go back
6. **Skip Uncertain Emails**: Press Space to skip emails you're unsure about
7. **Reach Goal**: Get notified at 100 emails, continue if desired

## Training Best Practices

### Getting to 100 Emails Quickly
1. Start with obvious cases (P3 newsletters, P4 junk) - these are fastest
2. Use keyboard shortcuts to build muscle memory
3. Don't overthink - trust your instincts
4. Skip uncertain emails rather than guessing

### Improving Model Quality
- Be consistent with your categorization criteria
- Consider the action required, not just the sender
- P1 should be truly urgent (interrupt-worthy)
- When uncertain between P1 and P2, choose P2

### Active Learning (Post-Launch)
- After initial training, the model will predict categories
- Review and correct predictions to improve accuracy
- Focus corrections on important misclassifications

## Integration with Hybrid Approach

The training feature is designed to work with the hybrid AI approach:

1. **Cold Start (0-100 emails)**: Manual training + LLM for safety
2. **Improving Model (100-500 emails)**: CoreML primary, LLM for uncertain cases
3. **Mature Model (500+ emails)**: CoreML primary, LLM for summaries

## Future Enhancements

Potential improvements for consideration:
- Batch labeling (e.g., "mark all from this sender as P3")
- Auto-categorization based on simple rules to speed up labeling
- Training statistics (accuracy over time, category distribution)
- Export training data for analysis
- Custom training goals (adjust from 100 to other targets)
- Confidence indicators for user categorizations
- Training history view with ability to review/modify past labels
