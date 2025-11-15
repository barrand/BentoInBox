# Info.plist Configuration Guide

This guide shows what needs to be added to your Info.plist for Google OAuth to work.

## Required Configuration

### URL Types (OAuth Callback)

You need to add a URL type for the OAuth callback. This should be your **reversed client ID**.

**Example:**
- Client ID: `123456789-abc.apps.googleusercontent.com`
- URL Scheme: `com.googleusercontent.apps.123456789-abc`

### Adding in Xcode (Recommended)

1. Select your project in the Project Navigator
2. Select your app target
3. Go to the "Info" tab
4. Find "URL Types" section
5. Click "+" to add a new URL type
6. Fill in:
   - **URL Schemes**: `com.googleusercontent.apps.YOUR-CLIENT-ID`
   - **Identifier**: (leave blank or same as URL scheme)
   - **Role**: Editor

### Adding Manually (Info.plist)

If you prefer to edit Info.plist directly, add:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.googleusercontent.apps.YOUR-CLIENT-ID</string>
        </array>
    </dict>
</array>
```

Replace `YOUR-CLIENT-ID` with your actual client ID (without the `.apps.googleusercontent.com` part).

## Optional Configuration

### Queried URL Schemes (iOS 14 and earlier)

If your app needs to support iOS 14 or earlier, you may need to add:

```xml
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>googlegmail</string>
</array>
```

This is typically not needed for iOS 15+ with the Google Sign-In SDK.

## Verification

### Check URL Scheme is Correct

The URL scheme must be the **exact reverse** of your client ID:

**Correct Examples:**
- Client ID: `123-abc.apps.googleusercontent.com`
- URL Scheme: `com.googleusercontent.apps.123-abc` ✅

- Client ID: `456789-xyz.apps.googleusercontent.com`
- URL Scheme: `com.googleusercontent.apps.456789-xyz` ✅

**Incorrect Examples:**
- URL Scheme: `com.googleusercontent.apps.123456789` ❌ (missing suffix)
- URL Scheme: `com.yourcompany.bentoinbox` ❌ (custom scheme won't work)
- URL Scheme: `123-abc.apps.googleusercontent.com` ❌ (not reversed)

## Testing Your Configuration

After adding the URL scheme:

1. Build and run your app
2. Tap "Sign in with Google"
3. Complete the OAuth flow
4. The app should open automatically after authentication

If the app doesn't open:
- Check URL scheme is exactly the reversed client ID
- Verify no typos in client ID
- Clean build folder (⌘⇧K) and rebuild

## Complete Example

Here's a complete Info.plist with all relevant keys:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Your existing keys -->
    <key>CFBundleName</key>
    <string>$(PRODUCT_NAME)</string>
    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    
    <!-- Add this for Google OAuth -->
    <key>CFBundleURLTypes</key>
    <array>
        <dict>
            <key>CFBundleTypeRole</key>
            <string>Editor</string>
            <key>CFBundleURLSchemes</key>
            <array>
                <!-- Replace with your reversed client ID -->
                <string>com.googleusercontent.apps.123456789-abc</string>
            </array>
        </dict>
    </array>
    
    <!-- Optional: Only needed for iOS 14 or earlier -->
    <key>LSApplicationQueriesSchemes</key>
    <array>
        <string>googlegmail</string>
    </array>
    
    <!-- Your other existing keys -->
</dict>
</plist>
```

## Multiple URL Schemes

If your app already has URL schemes (e.g., for deep linking), you can have multiple:

```xml
<key>CFBundleURLTypes</key>
<array>
    <!-- Existing URL scheme -->
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>bentoinbox</string>
        </array>
    </dict>
    <!-- Google OAuth URL scheme -->
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.googleusercontent.apps.123456789-abc</string>
        </array>
    </dict>
</array>
```

## Troubleshooting

### Issue: Can't find URL Types in Xcode
**Solution:** Make sure you're in the "Info" tab of your app target, not the project settings.

### Issue: URL Types section is missing
**Solution:** Scroll down in the Info tab. It's usually near the bottom.

### Issue: OAuth callback doesn't work after adding URL scheme
**Solution:** 
- Clean build folder (⌘⇧K)
- Delete app from simulator/device
- Rebuild and install fresh copy

### Issue: Not sure what my client ID is
**Solution:** 
- Go to [Google Cloud Console](https://console.cloud.google.com)
- APIs & Services → Credentials
- Find your iOS OAuth client
- Copy the client ID

## Related Files

- **GoogleConfig.swift** - Where you configure the client ID
- **BentoInboxApp.swift** - Handles `.onOpenURL` callback
- **GoogleAuthService.swift** - Implements OAuth flow

## Next Steps

After configuring Info.plist:
1. ✅ Update GoogleConfig.swift with your client ID
2. ✅ Build and test the OAuth flow
3. ✅ Verify you can sign in and see Gmail messages
