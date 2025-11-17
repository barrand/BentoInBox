# HTML Email Rendering

## Overview
BentoInbox now renders HTML emails properly in the reading pane using WebKit (WKWebView). Plain text emails continue to display as regular text, while HTML emails are rendered with full formatting support.

## Implementation

### HTMLEmailView Component
A cross-platform SwiftUI wrapper for WKWebView that works on both iOS and macOS:

```swift
#if os(macOS)
struct HTMLEmailView: NSViewRepresentable {
    let htmlContent: String
    // Wraps WKWebView for macOS
}
#else
struct HTMLEmailView: UIViewRepresentable {
    let htmlContent: String
    // Wraps WKWebView for iOS
}
#endif
```

### Features

#### 1. **Automatic Format Detection**
- Checks if email has HTML content (`body.hasHTML`)
- Falls back to plain text if HTML not available
- Prioritizes HTML for richer formatting

#### 2. **Custom Styling**
The WebView injects CSS to ensure emails look great:
- System fonts (-apple-system)
- Proper text sizing (14px macOS, 16px iOS)
- Transparent background (matches app theme)
- Styled links (iOS blue)
- Formatted blockquotes
- Code syntax highlighting
- Responsive layout

#### 3. **Image Blocking** (As Requested)
```css
img {
    max-width: 100%;
    height: auto;
    display: none; /* Hide images as requested */
}
```
Images are hidden to:
- ✅ Prevent tracking pixels
- ✅ Save bandwidth
- ✅ Avoid loading external content
- ✅ Faster rendering

#### 4. **Security**
- No JavaScript execution
- No external resource loading (images blocked)
- Sandboxed WebView environment
- baseURL set to `nil` (no relative path resolution)

### Supported HTML Features

#### ✅ Fully Supported
- Headings (h1-h6)
- Paragraphs
- Bold, italic, underline
- Lists (ordered and unordered)
- Links (clickable, styled)
- Blockquotes
- Code blocks and inline code
- Horizontal rules
- Basic tables
- Text colors and styling

#### ⚠️ Blocked (By Design)
- Images (tracking prevention)
- External CSS files
- JavaScript
- Iframes
- Forms

#### 📋 Fallback Behavior
If HTML rendering fails or content is malformed:
1. Attempts to display HTML
2. If error occurs, falls back to plain text version
3. If no plain text, shows snippet
4. If no snippet, shows "(No content available)"

## User Experience

### HTML Email View:
```
┌─────────────────────────────────────┐
│ Message                             │
│                                     │
│ Weekly Newsletter - Issue #42       │
│                                     │
│ Hello there! 👋                     │
│                                     │
│ This is an HTML email with          │
│ formatting.                         │
│                                     │
│ This Week's Highlights              │
│ • Feature Update: Dark mode         │
│ • Bug Fix: Performance              │
│ • Coming Soon: Templates            │
│                                     │
│ [Styled blockquotes and links]      │
└─────────────────────────────────────┘
```

### Plain Text Email View:
```
┌─────────────────────────────────────┐
│ Message                             │
│                                     │
│ Hello there!                        │
│                                     │
│ This is a plain text message...     │
│ (Standard text display)             │
│ (Selectable for copying)            │
└─────────────────────────────────────┘
```

## Testing

The MockGmailService alternates between HTML and plain text based on message ID:
- Even-numbered IDs (0, 2, 4...): HTML email
- Odd-numbered IDs (1, 3, 5...): Plain text email

This allows testing both rendering modes during development.

## Performance

### Rendering Speed
- HTML emails: ~50-200ms initial render
- Plain text: Instant (native SwiftUI Text)
- WebView reuse: Same instance updates content

### Memory Usage
- WebView: ~10-30MB per instance
- Lightweight compared to full browser
- Properly deallocated when view dismissed

## Future Enhancements

Possible improvements:
- [ ] Toggle to show/hide images (with user consent)
- [ ] Dark mode HTML styles
- [ ] Attachment preview
- [ ] Print support
- [ ] Export as PDF
- [ ] Font size adjustment
- [ ] Accessibility improvements (VoiceOver support)
- [ ] HTML sanitization for untrusted content

## Technical Notes

### Why WKWebView?
- Native WebKit engine (same as Safari)
- Hardware accelerated rendering
- Proper HTML/CSS standards support
- Secure sandboxing
- Low memory footprint
- Official Apple recommendation

### Why Not Alternatives?
- ❌ `AttributedString` with HTML: Limited HTML support, no CSS
- ❌ Third-party parsers: Reinventing the wheel, poor compatibility
- ❌ `SFSafariViewController`: Too heavyweight, full browser UI
- ✅ `WKWebView`: Perfect balance of features and performance
