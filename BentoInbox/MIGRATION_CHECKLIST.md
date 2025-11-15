# Migration Checklist: Mock to Real Google OAuth

This checklist will help you complete the transition from mock services to real Google OAuth and Gmail integration.

## ✅ Completed Changes

The following files have already been created/updated:

- ✅ **GoogleAuthService.swift** - Real Google Sign-In implementation
- ✅ **GoogleGmailService.swift** - Real Gmail API implementation  
- ✅ **GoogleConfig.swift** - Centralized configuration
- ✅ **BentoInboxApp.swift** - Updated to use real services and handle OAuth callbacks
- ✅ **Views.swift** - Updated sign-in button text
- ✅ **SETUP_GUIDE.md** - Complete setup instructions

## 🔧 Required Actions

### 1. Add Google Sign-In SDK Package
- [ ] In Xcode: File → Add Package Dependencies
- [ ] URL: `https://github.com/google/GoogleSignIn-iOS`
- [ ] Version: 7.0.0 or newer
- [ ] Add both `GoogleSignIn` and `GoogleSignInSwift`

### 2. Set Up Google Cloud Project
- [ ] Create project at [Google Cloud Console](https://console.cloud.google.com)
- [ ] Enable Gmail API
- [ ] Configure OAuth consent screen
- [ ] Add gmail.readonly scope
- [ ] Create iOS OAuth client ID
- [ ] Copy your Client ID

### 3. Configure Xcode Project
- [ ] Add URL Scheme to Info.plist (reversed client ID)
- [ ] Update `GoogleConfig.swift` with your actual client ID
- [ ] Verify bundle ID matches Google Cloud Console

### 4. Test OAuth Flow
- [ ] Build and run the app
- [ ] Click "Sign in with Google"
- [ ] Complete OAuth flow in browser/webview
- [ ] Verify you're redirected back to the app
- [ ] Confirm real Gmail messages appear

## 🧹 Optional Cleanup

Once everything is working with real services, you can optionally remove the mock implementations:

### Files that can be kept for testing:
- **MockAuthService** and **MockGmailService** in Services.swift
  - Keep these for unit tests and previews
  - They're still used in `#Preview` blocks

### Alternative: Feature flag approach
Instead of deleting mocks, you could add a feature flag:

```swift
// In BentoInboxApp.swift
#if DEBUG
let useMockServices = CommandLine.arguments.contains("--use-mocks")
#else
let useMockServices = false
#endif

@State private var authService: AuthService = {
    #if DEBUG
    if useMockServices {
        return MockAuthService()
    }
    #endif
    return GoogleAuthService()
}()
```

This allows you to:
- Keep mocks for UI testing
- Test without real Google credentials
- Switch easily during development

## 🔒 Security Checklist

- [ ] Never commit real client IDs to public repositories
- [ ] Consider using `.xcconfig` files for sensitive data
- [ ] Add GoogleConfig.swift to .gitignore if it contains secrets
- [ ] Use environment variables for CI/CD
- [ ] Review OAuth consent screen settings before publishing

## 📱 Testing Checklist

### Basic Flow
- [ ] Sign in with Google account
- [ ] Verify Gmail messages load
- [ ] Check that message metadata is correct (from, subject, date)
- [ ] Test message categorization
- [ ] Test filter by category
- [ ] Test refresh functionality
- [ ] Sign out and verify state clears

### Edge Cases
- [ ] Test with empty inbox
- [ ] Test with very large inbox (1000+ messages)
- [ ] Test with poor network connection
- [ ] Test offline behavior
- [ ] Test token expiration (wait 1 hour, then interact)
- [ ] Test with multiple accounts (sign out, sign in with different account)

### Error Handling
- [ ] Deny permissions during OAuth - should show error
- [ ] Revoke app access in Google account - should require re-auth
- [ ] Test with invalid client ID - should show clear error
- [ ] Test API rate limiting (unlikely but possible)

## 🚀 Production Readiness

Before releasing to App Store:

- [ ] Publish OAuth consent screen (move from Testing to Production)
- [ ] Test with non-developer Google accounts
- [ ] Implement proper error messages for users
- [ ] Add loading states for network operations
- [ ] Consider implementing retry logic for failed requests
- [ ] Add analytics/logging for OAuth failures
- [ ] Document support process for auth issues
- [ ] Test on multiple iOS versions
- [ ] Test on different device sizes

## 📊 Performance Optimization

Consider these improvements after basic functionality works:

- [ ] Implement incremental sync using Gmail's `historyId`
- [ ] Cache message metadata in SwiftData (already done!)
- [ ] Implement pagination for large inboxes
- [ ] Add background refresh capability
- [ ] Optimize API calls (batch requests where possible)
- [ ] Add pull-to-refresh UI feedback

## 🐛 Common Issues & Solutions

### Issue: "Sign in failed"
**Solution:** Check that:
- Client ID is correct in GoogleConfig.swift
- Bundle ID matches Google Cloud Console
- URL scheme is properly configured

### Issue: "Invalid client"
**Solution:** 
- Verify reversed client ID format
- Check Info.plist URL types

### Issue: No messages appear after sign in
**Solution:**
- Check network connectivity
- Verify Gmail API is enabled in Google Cloud
- Check Xcode console for API errors
- Confirm account has Gmail messages

### Issue: Token expired errors
**Solution:**
- GoogleAuthService automatically refreshes tokens
- If persistent, sign out and sign in again
- Check token refresh logic in GoogleAuthService.swift

## 📝 Next Steps

After successful migration:

1. **Enhance the UI**
   - Add message bodies (requires different API call)
   - Implement search functionality
   - Add compose/reply features (requires write scopes)

2. **Improve Classification**
   - Implement ML-based category prediction
   - Use CreateML to train on user's categorizations
   - Add auto-categorization based on training data

3. **Add More Features**
   - Support for other Gmail labels
   - Archive/delete functionality (needs write scopes)
   - Push notifications for new messages
   - Widget support

4. **Multi-platform**
   - Add macOS support (update GoogleAuthService for AppKit)
   - Consider iPadOS-specific UI enhancements
   - Add Catalyst support

## 🆘 Need Help?

- Google Sign-In SDK: https://github.com/google/GoogleSignIn-iOS
- Gmail API Docs: https://developers.google.com/gmail/api
- OAuth 2.0 Guide: https://developers.google.com/identity/protocols/oauth2

Good luck with your integration! 🎉
