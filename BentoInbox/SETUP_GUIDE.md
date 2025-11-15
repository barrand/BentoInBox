# Google OAuth & Gmail Integration Setup Guide

This guide will walk you through setting up Google OAuth authentication and Gmail API access for BentoInbox.

## Step 1: Google Cloud Console Setup

### 1.1 Create a Project
1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Click "Select a project" → "New Project"
3. Name it "BentoInbox" (or your preferred name)
4. Click "Create"

### 1.2 Enable Gmail API
1. In your project, go to "APIs & Services" → "Library"
2. Search for "Gmail API"
3. Click on it and click "Enable"

### 1.3 Create OAuth Consent Screen
1. Go to "APIs & Services" → "OAuth consent screen"
2. Choose "External" (unless you have a Google Workspace)
3. Fill in the required fields:
   - App name: "BentoInbox"
   - User support email: your email
   - Developer contact information: your email
4. Click "Save and Continue"
5. On the "Scopes" screen, click "Add or Remove Scopes"
6. Add: `https://www.googleapis.com/auth/gmail.readonly`
7. Click "Update" then "Save and Continue"
8. On "Test users" (if in testing mode), add your Gmail address
9. Click "Save and Continue"

### 1.4 Create OAuth Client ID
1. Go to "APIs & Services" → "Credentials"
2. Click "Create Credentials" → "OAuth client ID"
3. Application type: "iOS"
4. Name: "BentoInbox iOS"
5. Bundle ID: Your app's bundle identifier (e.g., `com.yourname.BentoInbox`)
6. Click "Create"
7. **Save the Client ID** - you'll need this!

## Step 2: Xcode Project Setup

### 2.1 Add Google Sign-In SDK
1. In Xcode, go to File → Add Package Dependencies
2. Enter: `https://github.com/google/GoogleSignIn-iOS`
3. Select "Up to Next Major Version" starting from 7.0.0
4. Click "Add Package"
5. Make sure `GoogleSignIn` and `GoogleSignInSwift` are checked
6. Click "Add Package"

### 2.2 Configure URL Scheme
1. In Xcode, select your project in the navigator
2. Select your app target
3. Go to the "Info" tab
4. Expand "URL Types"
5. Click "+" to add a new URL Type
6. Set the URL Scheme to your **reversed client ID**
   - If your client ID is: `123456789-abc.apps.googleusercontent.com`
   - Your URL scheme is: `com.googleusercontent.apps.123456789-abc`
7. Leave Identifier blank or set it to the same value

### 2.3 Update GoogleConfig.swift
1. Open `GoogleConfig.swift`
2. Replace `"YOUR_CLIENT_ID_HERE.apps.googleusercontent.com"` with your actual client ID

```swift
static let clientID = "123456789-abc.apps.googleusercontent.com"
```

### 2.4 Handle OAuth Callback
Add this to your `BentoInboxApp.swift`:

```swift
import SwiftUI
import SwiftData
import GoogleSignIn

@main
struct BentoInboxApp: App {
    // ... existing code ...
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .environment(\.authService, authService)
                .environment(\.gmailService, gmailService)
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
```

### 2.5 Configure Info.plist (if needed)
If your app targets iOS 14 or earlier, you may need to add queried URL schemes to Info.plist:

```xml
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>googlegmail</string>
</array>
```

## Step 3: Testing

### 3.1 Build and Run
1. Build and run your app on a simulator or device
2. You should see the real "Sign in with Google" button
3. Click it and you'll be redirected to Google's OAuth flow
4. Sign in with your Google account
5. Grant permission to read Gmail
6. You'll be redirected back to the app

### 3.2 Verify Gmail Access
Once signed in:
- The app should fetch your actual Gmail messages
- You should see real emails in the inbox
- Categories should be assignable to real messages

## Step 4: Production Deployment

### 4.1 OAuth Consent Screen
Before releasing to the App Store:
1. Go back to "OAuth consent screen" in Google Cloud Console
2. Click "Publish App" to move from Testing to Production
3. Google may require verification if you request sensitive scopes

### 4.2 Security Best Practices
- Never commit your client ID to public repositories
- Consider using Xcode configuration files or environment variables
- Keep your OAuth credentials secure

## Troubleshooting

### "Sign in failed" error
- Check that your client ID is correct in `GoogleConfig.swift`
- Verify your bundle ID matches what's in Google Cloud Console
- Ensure Gmail API is enabled

### "Invalid client" error
- The client ID doesn't match your bundle ID
- The URL scheme is incorrect

### "Access denied" error
- You need to add yourself as a test user if the app is in testing mode
- Check that gmail.readonly scope is added to the OAuth consent screen

### Token refresh issues
- The Google Sign-In SDK handles token refresh automatically
- If you see token errors, try signing out and signing in again

## API Quotas

Gmail API has rate limits:
- 250 quota units per user per second
- 1 billion quota units per day

Each API call costs different amounts:
- `messages.list`: 5 units
- `messages.get`: 5 units

For a typical user checking 100 emails, that's ~525 units per refresh, well within limits.

## Next Steps

Once OAuth is working:
1. Test with different Gmail accounts
2. Implement error handling for network failures
3. Add offline support (your SwiftData models already handle this!)
4. Consider implementing incremental sync using `historyId`
5. Add support for other Gmail labels beyond INBOX

## Resources

- [Google Sign-In iOS Guide](https://developers.google.com/identity/sign-in/ios)
- [Gmail API Reference](https://developers.google.com/gmail/api/reference/rest)
- [OAuth 2.0 for Mobile Apps](https://developers.google.com/identity/protocols/oauth2/native-app)
