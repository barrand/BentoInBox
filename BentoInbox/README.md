# BentoInbox

A smart Gmail inbox organizer for iOS and macOS that uses categories to help you organize your emails efficiently.

## Features

✅ **Google OAuth Integration** - Secure sign-in with your Google account  
✅ **Real Gmail Access** - Fetches your actual Gmail messages (read-only)  
✅ **Smart Categories** - Organize emails with custom categories  
✅ **Offline Support** - All messages cached locally with SwiftData  
✅ **Clean Architecture** - Protocol-based design with separation of concerns  
✅ **Native SwiftUI** - Modern UI with support for iOS and macOS  
✅ **Privacy First** - Only requests read-only Gmail access  

## Screenshots

[Add screenshots here]

## Getting Started

### Prerequisites

- Xcode 15.0 or later
- iOS 17.0+ / macOS 14.0+ deployment target
- A Google account with Gmail
- Google Cloud Console account (free)

### Quick Setup (15 minutes)

Follow the **[Quick Start Guide](QUICK_START.md)** for fastest setup.

### Detailed Setup

See **[Setup Guide](SETUP_GUIDE.md)** for comprehensive instructions.

## Project Structure

```
BentoInbox/
├── BentoInboxApp.swift         # App entry point
├── ContentView.swift            # Root view controller
├── AppState.swift               # App-wide state
│
├── Services/
│   ├── Services.swift           # Service protocols + mocks
│   ├── GoogleAuthService.swift  # Real Google OAuth implementation
│   ├── GoogleGmailService.swift # Real Gmail API implementation
│   └── GoogleConfig.swift       # OAuth configuration
│
├── Models/
│   └── Models.swift             # SwiftData models
│
├── Repositories/
│   └── Repositories.swift       # Data access layer
│
├── UseCases/
│   └── UseCases.swift           # Business logic
│
├── ViewModels/
│   └── ViewModels.swift         # View models
│
├── Views/
│   ├── Views.swift              # Main views
│   └── CategoryStyle.swift      # Category styling helpers
│
└── Helpers/
    └── SeedCategoryLoader.swift # Initial category data
```

## Architecture

BentoInbox follows **Clean Architecture** principles:

### Layers

1. **Presentation Layer** (SwiftUI Views + ViewModels)
   - Views are purely declarative
   - ViewModels handle UI logic and state
   - Observable pattern for reactive updates

2. **Domain Layer** (Use Cases)
   - Business logic is isolated
   - Protocol-based for testability
   - No framework dependencies

3. **Data Layer** (Repositories + Services)
   - Repository pattern for data access
   - Service protocols for external APIs
   - SwiftData for local persistence

### Key Patterns

- **Dependency Injection** via SwiftUI Environment
- **Protocol-Oriented Design** for flexibility and testing
- **Repository Pattern** for data abstraction
- **Use Case Pattern** for business logic
- **DTO Pattern** for view-model communication

## Technologies

- **SwiftUI** - Declarative UI framework
- **SwiftData** - Local data persistence
- **Swift Concurrency** - async/await for networking
- **Google Sign-In SDK** - OAuth authentication
- **Gmail REST API** - Email access

## API Usage

### Gmail API Quotas

- **Free tier**: 1 billion units per day
- **Per user limit**: 250 units per second
- **Typical refresh**: ~510 units (100 messages)
- **Daily capacity**: ~1,960 refreshes per user

### Scopes Used

- `https://www.googleapis.com/auth/gmail.readonly` - Read-only Gmail access

## Development

### Building

```bash
# Open in Xcode
open BentoInbox.xcodeproj

# Or from command line
xcodebuild -scheme BentoInbox -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Testing

```bash
# Run tests
xcodebuild test -scheme BentoInbox -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Using Mock Services

For development without Google OAuth:

```swift
// In BentoInboxApp.swift
@State private var authService: AuthService = MockAuthService()
@State private var gmailService: GmailService = MockGmailService()
```

## Configuration

### Required Configuration

1. **Google OAuth Client ID**
   - Create in [Google Cloud Console](https://console.cloud.google.com)
   - Update `GoogleConfig.swift`

2. **Bundle Identifier**
   - Must match OAuth client configuration

3. **URL Scheme**
   - Add reversed client ID to Info.plist

### Optional Configuration

- **Category Seed Data** - Edit `SeedCategoryLoader.swift`
- **API Fetch Limits** - Adjust in `UseCases.swift`
- **UI Colors** - Modify `CategoryStyle.swift`

## Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| "Sign in failed" | Check client ID, bundle ID, and URL scheme |
| "Invalid client" | Verify URL scheme is reversed client ID |
| No messages appear | Check Gmail API is enabled in Cloud Console |
| Token errors | Sign out and sign in again |

See **[Setup Guide](SETUP_GUIDE.md)** for detailed troubleshooting.

## Roadmap

### Planned Features

- [ ] Message body viewing
- [ ] ML-based auto-categorization
- [ ] Search functionality
- [ ] Multiple account support
- [ ] Widgets
- [ ] Push notifications
- [ ] Archive/delete (write scopes)
- [ ] Compose/reply (write scopes)

### Future Ideas

- [ ] Smart filters
- [ ] Email templates
- [ ] Snooze functionality
- [ ] Important message detection
- [ ] Batch operations
- [ ] Export functionality
- [ ] Dark/light theme customization

## Contributing

Contributions are welcome! Please follow these guidelines:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

### Code Style

- Follow Swift API Design Guidelines
- Use SwiftLint for consistency
- Add comments for complex logic
- Keep functions focused and small

## Privacy

BentoInbox respects your privacy:

- **Read-only access** - Only requests gmail.readonly scope
- **Local storage** - All data stored on your device
- **No tracking** - No analytics or third-party tracking
- **No server** - No backend server collecting data
- **Open source** - Code is transparent and auditable

## Security

- OAuth 2.0 with PKCE for authentication
- Tokens stored securely by Google Sign-In SDK
- No passwords stored in app
- HTTPS for all API calls
- Regular security updates

## License

[Add your license here, e.g., MIT, Apache 2.0]

## Acknowledgments

- Google Sign-In SDK - OAuth implementation
- Gmail API - Email access
- SF Symbols - UI icons
- SwiftUI and SwiftData - Apple frameworks

## Support

- **Documentation**: See guides in repository
- **Issues**: Open an issue on GitHub
- **Questions**: [Add contact info or discussion forum]

## Links

- [Quick Start Guide](QUICK_START.md)
- [Setup Guide](SETUP_GUIDE.md)
- [Migration Checklist](MIGRATION_CHECKLIST.md)
- [Changes Summary](CHANGES_SUMMARY.md)
- [Google Sign-In iOS](https://github.com/google/GoogleSignIn-iOS)
- [Gmail API Reference](https://developers.google.com/gmail/api)

---

**Made with ❤️ using Swift and SwiftUI**
