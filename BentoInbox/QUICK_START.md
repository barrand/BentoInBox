# Quick Start: Get Google OAuth Working in 15 Minutes

This is a condensed version of the setup guide to get you up and running quickly.

## Step 1: Google Cloud Console (5 minutes)

### 1.1 Create Project & Enable API
```
1. Go to: https://console.cloud.google.com
2. Create new project: "BentoInbox"
3. Go to: APIs & Services → Library
4. Search: "Gmail API" → Enable
```

### 1.2 OAuth Consent Screen (Quick Setup)
```
1. Go to: APIs & Services → OAuth consent screen
2. Choose: External
3. Fill in:
   - App name: BentoInbox
   - User support email: [your email]
   - Developer email: [your email]
4. Click: Save and Continue
5. Scopes → Add or Remove Scopes → Select:
   ✅ https://www.googleapis.com/auth/gmail.readonly
6. Click: Update → Save and Continue
7. Test users → Add yourself → Save and Continue
```

### 1.3 Create Credentials
```
1. Go to: APIs & Services → Credentials
2. Create Credentials → OAuth client ID
3. Application type: iOS
4. Name: BentoInbox iOS
5. Bundle ID: [your bundle ID, e.g., com.yourname.BentoInbox]
6. Create
7. COPY THE CLIENT ID - you'll need this!
```

The client ID looks like: `123456789-abc123def456.apps.googleusercontent.com`

## Step 2: Xcode Setup (5 minutes)

### 2.1 Add Package Dependency
```
1. Xcode → File → Add Package Dependencies
2. Paste: https://github.com/google/GoogleSignIn-iOS
3. Dependency Rule: Up to Next Major Version (7.0.0)
4. Add Package
5. Check: GoogleSignIn ✅ GoogleSignInSwift ✅
6. Add Package
```

### 2.2 Configure URL Scheme
```
1. Select project in navigator
2. Select your app target
3. Info tab → URL Types → "+"
4. URL Schemes: [reversed client ID]
   Example: com.googleusercontent.apps.123456789-abc123def456
5. Identifier: (leave blank or same as above)
```

**How to reverse the client ID:**
- Original: `123456789-abc.apps.googleusercontent.com`
- Reversed: `com.googleusercontent.apps.123456789-abc`

### 2.3 Update GoogleConfig.swift
```swift
// Open GoogleConfig.swift
// Replace this line:
static let clientID = "YOUR_CLIENT_ID_HERE.apps.googleusercontent.com"

// With your actual client ID:
static let clientID = "123456789-abc123def456.apps.googleusercontent.com"
```

## Step 3: Build and Test (5 minutes)

### 3.1 Build
```
1. Select a simulator or device
2. Product → Build (⌘B)
3. Fix any compilation errors
```

### 3.2 Run
```
1. Product → Run (⌘R)
2. App should launch to sign-in screen
```

### 3.3 Sign In
```
1. Tap "Sign in with Google"
2. Browser/webview opens
3. Sign in with your Google account
4. Grant permission to read Gmail
5. Should redirect back to app
6. You should see your real Gmail messages! 🎉
```

## Troubleshooting (If Something Goes Wrong)

### Build Error: "No such module 'GoogleSignIn'"
**Fix:** Clean build folder (⌘⇧K) and rebuild (⌘B)

### Runtime Error: "Sign in failed"
**Fix:** Check these in order:
1. Client ID is correct in GoogleConfig.swift
2. Bundle ID matches Google Cloud Console
3. URL scheme is the reversed client ID
4. Gmail API is enabled in Google Cloud

### "Invalid client" error
**Fix:** URL scheme is wrong. Must be reversed client ID.

### "Access denied" error
**Fix:** Add yourself as a test user in OAuth consent screen (Google Cloud Console)

### App redirects but doesn't sign in
**Fix:** Check Xcode console for errors. Likely missing `.onOpenURL` handler (already added to BentoInboxApp.swift)

### No messages appear
**Fix:** 
1. Check console for API errors
2. Verify Gmail API is enabled
3. Check your Gmail account actually has messages
4. Try pull-to-refresh gesture

## Verification Checklist

- [ ] Google Cloud project created
- [ ] Gmail API enabled
- [ ] OAuth consent screen configured
- [ ] Test user added (yourself)
- [ ] OAuth client ID created
- [ ] Client ID copied
- [ ] GoogleSignIn package added
- [ ] URL scheme configured (reversed client ID)
- [ ] GoogleConfig.swift updated with client ID
- [ ] App builds without errors
- [ ] Sign-in button appears
- [ ] OAuth flow completes
- [ ] Real Gmail messages appear

## What to Do After Success

### Immediate
- Test signing out and back in
- Try assigning categories to real messages
- Test filtering by category
- Test refresh functionality

### Soon
- Read SETUP_GUIDE.md for more details
- Review MIGRATION_CHECKLIST.md for testing ideas
- Check CHANGES_SUMMARY.md to understand what changed

### Eventually
- Move app from Testing to Production in OAuth consent screen
- Implement additional features (see CHANGES_SUMMARY.md)
- Consider adding ML-based categorization

## Need More Help?

- **Detailed setup:** See `SETUP_GUIDE.md`
- **Migration details:** See `MIGRATION_CHECKLIST.md`
- **What changed:** See `CHANGES_SUMMARY.md`
- **Google Sign-In issues:** https://github.com/google/GoogleSignIn-iOS/issues
- **Gmail API issues:** https://stackoverflow.com/questions/tagged/gmail-api

## Pro Tips

### Tip 1: Keep Mocks for Development
The mock services are still available. You can switch between real and mock:

```swift
// In BentoInboxApp.swift, change:
@State private var authService: AuthService = GoogleAuthService()

// To:
@State private var authService: AuthService = MockAuthService()
```

### Tip 2: Check Console for Errors
Always keep Xcode console visible. It shows:
- OAuth flow details
- API errors
- Network issues
- Token refresh events

### Tip 3: Test with Different Accounts
Sign out, sign in with a different Google account. Make sure it works for multiple users.

### Tip 4: Test Token Refresh
After signing in, leave the app idle for an hour. Then try refreshing. The token should auto-refresh (you shouldn't notice anything).

### Tip 5: Monitor API Usage
Go to Google Cloud Console → APIs & Services → Dashboard to see your API usage. Good for debugging and monitoring.

## Success Criteria

You'll know it's working when:
✅ Sign-in button launches Google OAuth flow
✅ You can complete sign-in
✅ Real Gmail messages appear in the inbox
✅ Message details are correct (subject, from, date)
✅ You can assign categories to messages
✅ Refresh brings in new messages
✅ Sign out works and returns to sign-in screen

Good luck! 🚀
