# How to Clear Old Categories from Your Database

## The Problem
You're seeing old categories (Church, Travel, Family/Friends, School, etc.) in your training UI because they still exist in your database. The code has been updated to use P1-P4, but the database needs to be reset.

## The Solution

### Option 1: Use the Reset Button (Recommended)
1. **Launch your app**
2. **Sign in** to your Google account
3. **Click on "Categories"** in the toolbar (tag icon)
4. **Click "Reset to P1-P4"** button in the toolbar (circular arrow icon)
5. **Confirm the reset** when the dialog appears
6. **Go back to "Train Model"** and you should now see only P1-P4 categories

### Option 2: Delete the Database File (Nuclear Option)
If the reset button doesn't work, you can manually delete the database:

**For macOS:**
1. Quit the app completely
2. Open Finder
3. Press `Cmd+Shift+G` to "Go to Folder"
4. Paste this path:
   ```
   ~/Library/Containers/[YourAppBundleID]/Data/Library/Application Support/
   ```
   Replace `[YourAppBundleID]` with your actual bundle ID (e.g., `com.yourname.BentoInbox`)
5. Look for a file with `.sqlite` extension (SwiftData database)
6. Delete it
7. Restart the app - it will create a fresh database with P1-P4 categories

**For iOS Simulator:**
1. Quit the app
2. Delete the app from the simulator (long press > Remove App > Delete App)
3. Clean build folder in Xcode (`Cmd+Shift+K`)
4. Build and run again

### Option 3: Add Reset on Launch (Temporary Debug Option)
If you want to force a reset every time during development, you can temporarily modify `RootView` in ContentView.swift:

```swift
.task {
    // On launch, check sign-in status
    appState.isSignedIn = await signInVM.checkSignedIn(authService: authService)
    if appState.isSignedIn {
        // TEMPORARY: Force reset categories during development
        try? SeedCategoryLoader.resetToP1P4System(modelContext)
        
        // Seed categories if needed (this line can stay)
        try? SeedCategoryLoader.seedIfNeeded(modelContext)
    }
}
```

**Note:** Remove this temporary line after you've reset once, or it will clear your training data every launch!

## Verification

After resetting, verify the categories are correct:

1. Go to **Categories** view
2. You should see exactly 5 categories:
   - P1 - Needs Attention (Red)
   - P2 - Can Wait (Orange)
   - P3 - Newsletter/Automated (Green)
   - P4 - Pure Junk (Gray)
   - Uncategorized (System)

3. Go to **Train Model** view
4. The category definitions box should show the P1-P4 definitions
5. The category buttons should only show P1-P4 options

## Why This Happens

SwiftData (and CoreData) persist data between app launches. When you first ran the app, it created categories based on the old seed data. Even though we updated the code, the database still has those old records.

The `seedIfNeeded()` function only runs if the database is empty, so it won't overwrite existing categories. That's why you need to explicitly reset using `resetToP1P4System()`.

## After Reset

Once reset:
- All old categories are deleted
- All training examples are cleared (you start fresh)
- All message category assignments are cleared
- New P1-P4 categories are created
- You can start training with a clean slate

## Troubleshooting

**Still seeing old categories?**
- Make sure you confirmed the reset dialog
- Try restarting the app after reset
- Check the Categories view to confirm P1-P4 are there
- If still broken, use Option 2 (delete database file)

**Reset button doesn't appear?**
- Make sure you're in the Categories view, not the Inbox
- Look in the toolbar for a circular arrow icon
- On iOS, you might need to tap the "..." menu to see it

**App crashes after reset?**
- This might happen if you have the Training view open during reset
- Close all views, do the reset from Categories view
- Then open Training view fresh
