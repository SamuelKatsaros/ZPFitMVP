# Firebase Setup Guide for ZP Fit

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Click "Add Project"
3. Enter project name: `zpfit` (or your preference)
4. Enable Google Analytics (optional)
5. Create project

## Step 2: Add iOS App to Firebase

1. In Firebase Console, click the iOS icon to add an iOS app
2. Enter iOS bundle ID: Check your Xcode project's bundle identifier
   - Open `ZPFit.xcodeproj` in Xcode
   - Select ZPFit target → General tab
   - Copy the Bundle Identifier (e.g., `com.yourname.zpfit`)
3. Enter App nickname: "ZP Fit iOS"
4. Download `GoogleService-Info.plist`

## Step 3: Add GoogleService-Info.plist to Xcode

1. Locate the downloaded `GoogleService-Info.plist` file
2. Drag it into your Xcode project navigator
3. **Important**: Check "Copy items if needed"
4. **Important**: Make sure "ZPFit" target is selected
5. The file should appear in the project root alongside `ZPFitApp.swift`

## Step 4: Add Firebase SDK via Swift Package Manager

1. Open your Xcode project
2. Go to File → Add Package Dependencies...
3. Enter package URL: `https://github.com/firebase/firebase-ios-sdk`
4. Click "Add Package"
5. Select the following products to add:
   - ✅ FirebaseAuth
   - ✅ FirebaseFirestore
   - ✅ FirebaseCore
6. Click "Add Package"

## Step 5: Configure Firebase Services

### Enable Authentication

1. In Firebase Console, go to Authentication
2. Click "Get Started"
3. Click "Sign-in method" tab
4. Enable "Email/Password"
5. Click "Save"

### Create Firestore Database

1. In Firebase Console, go to Firestore Database
2. Click "Create database"
3. Select "Start in test mode" (for development)
4. Choose Firestore location (e.g., `us-central`)
5. Click "Enable"

### Set up Security Rules (Important!)

In Firestore Rules tab, replace with:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only read/write their own user document
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      // Users can read/write their own progress
      match /progress/{document=**} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
    
    // Everyone can read programs, exercises, and trainers
    match /programs/{document=**} {
      allow read: if request.auth != null;
      allow write: if false; // Only admins can write (set up admin SDK separately)
    }
    
    match /exercises/{document=**} {
      allow read: if request.auth != null;
      allow write: if false;
    }
    
    match /trainers/{document=**} {
      allow read: if request.auth != null;
      allow write: if false;
    }
  }
}
```

### Enable Offline Persistence

Offline persistence is already enabled in the code (`FirestoreService.swift`). This allows the app to work without internet connection.

## Step 6: Add Sample Data to Firestore

### Add a Test Program

1. Go to Firestore Database in Firebase Console
2. Click "Start collection"
3. Collection ID: `programs`
4. Document ID: `jacklete`
5. Add fields:
   ```
   title: "Jacklete" (string)
   subtitle: "Build muscle, strength, and explosive power" (string)
   difficulty: "Advanced" (string)
   durationWeeks: 9 (number)
   coverImage: "https://lirp.cdn-website.com/cee6e347/dms3rep/multi/opt/new-zach-img-02-640w.jpg" (string)
   trainerId: "zach" (string)
   ```

### Add Program Days (Subcollection)

1. Click on the `jacklete` document
2. Click "Start collection"
3. Collection ID: `days`
4. Document ID: `day1`
5. Add fields:
   ```
   dayNumber: 1 (number)
   title: "Day 1 - Upper Body" (string)
   description: "Chest and triceps focus" (string)
   durationMinutes: 45 (number)
   type: "Strength" (string)
   exerciseIds: ["push-ups", "bench-press"] (array)
   ```

### Add Exercises

1. Go back to root collections
2. Create collection: `exercises`
3. Document ID: `push-ups`
4. Add fields:
   ```
   name: "Push Ups" (string)
   instructions: "Standard push up form" (string)
   muscleGroup: "Chest" (string)
   reps: 20 (number)
   videoURL: "https://customer-xyz.cloudflarestream.com/abc123/manifest/video.m3u8" (string)
   thumbnailURL: "https://customer-xyz.cloudflarestream.com/abc123/thumbnails/thumbnail.jpg" (string)
   ```

## Step 7: Build and Run

1. Clean build folder: Product → Clean Build Folder (Cmd+Shift+K)
2. Build the project: Product → Build (Cmd+B)
3. Fix any compilation errors if they appear
4. Run on simulator or device: Product → Run (Cmd+R)

## Troubleshooting

### "Module 'FirebaseCore' not found"
- Ensure Firebase packages were added correctly
- Try File → Packages → Reset Package Caches
- Clean and rebuild

### "GoogleService-Info.plist not found"
- Verify the file is in Xcode project navigator
- Check that it's added to the ZPFit target (select file → File Inspector → Target Membership)

### Authentication errors
- Verify Email/Password is enabled in Firebase Console
- Check that GoogleService-Info.plist matches your Firebase project

### Data not appearing
- Check Firestore security rules allow reading
- Verify you're logged in (create test account)
- Check network connection
- Look for errors in Xcode console

## Cloudflare Stream Setup (Optional)

If you want to use Cloudflare Stream for videos:

1. Sign up at [Cloudflare Stream](https://www.cloudflare.com/products/cloudflare-stream/)
2. Upload workout videos
3. Get the Stream URL (format: `https://customer-xyz.cloudflarestream.com/{videoId}/manifest/video.m3u8`)
4. Add these URLs to your Firestore exercise documents in the `videoURL` field

## Next Steps

Once Firebase is set up:

1. Launch the app
2. Sign up with a test email/password
3. Navigate to Programs tab
4. Programs will load from Firestore (or show hardcoded fallback)
5. Select a program
6. The selection saves to Firestore under `users/{uid}/currentProgramId`
7. Complete workouts to track progress in `users/{uid}/progress/`

## Support

For Firebase documentation:
- [Firebase Auth iOS](https://firebase.google.com/docs/auth/ios/start)
- [Firestore iOS](https://firebase.google.com/docs/firestore/quickstart)
- [Firebase iOS Setup](https://firebase.google.com/docs/ios/setup)
