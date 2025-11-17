# Full Message Body Feature

## Overview
Added on-demand loading of full email message bodies. By default, only message metadata and snippets are loaded for speed and efficiency. Users can click a button to load the full message body when they want to read the complete email.

## Why This Approach?

### Gmail API Quota
- Free quota: 1 billion units/day
- Each `messages.get` call costs 5 quota units (same for metadata or full)
- Quota is not the main concern

### Real Benefits
1. **Speed**: Loading 100 snippets is much faster than 100 full messages
2. **Bandwidth**: Full messages can be large (especially with HTML/attachments)
3. **User Experience**: Users can quickly scan their inbox without waiting
4. **Storage**: Less data stored locally

## Implementation Details

### Services.swift Changes

#### New Structure: `GmailMessageBody`
```swift
struct GmailMessageBody {
    let plain: String?
    let html: String?
    
    var displayText: String {
        // Prefers plain text, falls back to HTML (stripped of tags)
        // Returns user-friendly content
    }
}
```

#### New Protocol Method
```swift
protocol GmailService {
    func getMessageBody(id: String) async throws -> GmailMessageBody
}
```

### GoogleGmailService.swift Changes

- Fetches full message format from Gmail API
- Parses MIME multipart structure
- Extracts plain text and HTML bodies
- Handles base64url decoding (Gmail's format)
- Recursively searches message parts for body content

### Views.swift Changes

#### MessageDetailView Updates
- Added "Load Full Message" button
- Shows loading spinner while fetching
- Displays error if fetch fails
- Shows snippet by default, full body when loaded
- Full body text is selectable for copying

## User Flow

1. User selects a message → sees snippet immediately
2. User clicks "Load Full Message" button
3. Spinner appears while fetching
4. Full message replaces snippet
5. Button disappears (no need to load again)

## Error Handling

- Network errors are caught and displayed
- Falls back to snippet if full body unavailable
- User can retry by selecting another message and coming back

## Future Enhancements

Possible improvements:
- [ ] Cache full bodies locally to avoid re-fetching
- [ ] Show HTML with basic rendering (WebView)
- [ ] Handle attachments
- [ ] Download/save attachments
- [ ] Auto-load for messages under certain size threshold
- [ ] Keyboard shortcut to load full message (e.g., Cmd+L)
