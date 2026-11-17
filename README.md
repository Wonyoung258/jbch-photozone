# JBCH Photozone

An iPad photo booth app. Guests tap **Take Photo**, the app takes 4 photos on a 6-second countdown, and puts them in a vertical **1 × 4 photo strip**. Guests then pick a frame and can:

- **Print** two copies of the strip side by side on 4×6 photo paper (AirPrint, e.g. Epson PictureMate PM-400)
- **Save** the strip to the iPad's photo library
- **Scan a QR code** to download the strip to their own phone (uploaded to Firebase Storage)

Built with SwiftUI. It runs on iPad (the main target) and iPhone, iOS/iPadOS 17 or later.

> Based on [UNIV-4cut](https://github.com/9oormthon-univ/UNIV-4cut) by the goorm UNIV team.

---

## Contents

1. [What you need](#1-what-you-need)
2. [Install Xcode](#2-install-xcode)
3. [Sign in to Xcode with your own Apple ID](#3-sign-in-to-xcode-with-your-own-apple-id)
4. [Download the project](#4-download-the-project)
5. [Open the project and let the packages load](#5-open-the-project-and-let-the-packages-load)
6. [Set up signing (your team + your bundle ID)](#6-set-up-signing-your-team--your-bundle-id)
7. [Create your own Firebase project](#7-create-your-own-firebase-project)
8. [Add `GoogleService-Info.plist` to the project](#8-add-googleservice-infoplist-to-the-project)
9. [Turn on Firebase Storage (for QR codes)](#9-turn-on-firebase-storage-for-qr-codes)
10. [Run the app on your iPad](#10-run-the-app-on-your-ipad)
11. [Set up the printer](#11-set-up-the-printer)
12. [Customizing frames and the home screen](#12-customizing-frames-and-the-home-screen)
13. [Troubleshooting](#13-troubleshooting)
14. [Project structure](#14-project-structure)

---

## 1. What you need

| Item | Notes |
|---|---|
| A Mac | Any Mac that can run a current version of Xcode. |
| Xcode 15 or later | Free from the Mac App Store. The project targets iOS 17. |
| An Apple ID | A free one works. A paid Apple Developer account ($99/year) only matters for long-term use; see [step 3](#3-sign-in-to-xcode-with-your-own-apple-id). |
| An iPad on iPadOS 17+ | Plus a USB-C (or Lightning) cable to connect it to the Mac. |
| A Google account | For Firebase (QR code downloads). |
| *(Optional)* An AirPrint photo printer | E.g. Epson PictureMate PM-400, with 4×6 photo paper. |

> The iOS Simulator has **no camera**, so the photo booth can't take pictures there; the countdown will just keep repeating. Use a real iPad to test the full flow.

---

## 2. Install Xcode

1. Open the **App Store** on your Mac, search for **Xcode**, and click **Get / Install**. It's a large download (10+ GB), so give it time.
2. Open Xcode once after it installs. If it asks to install **additional components** or **platform support for iOS**, click **Install** and wait for it to finish.
3. Check your version: menu bar **Xcode → About Xcode**. It must be **15.0 or later**.

---

## 3. Sign in to Xcode with your own Apple ID

Xcode needs **your** Apple ID to sign the app so it can be installed on your iPad. Don't use someone else's account or team.

1. In Xcode, open **Xcode → Settings…** (or press `⌘,`).
2. Go to the **Accounts** tab.
3. If someone else's Apple ID is listed there (for example, on a shared Mac), select it and click **–** to remove it.
4. Click **+** at the bottom left → choose **Apple ID** → **Continue** → sign in with your Apple ID (and two-factor code).
5. Select your account in the list. On the right, under **Team**, you should see something like **"Your Name (Personal Team)"**. That's the team you'll use in [step 6](#6-set-up-signing-your-team--your-bundle-id).

**Free vs. paid Apple account:**

| | Free Apple ID (Personal Team) | Paid Apple Developer Program |
|---|---|---|
| Install on your own iPad | ✅ | ✅ |
| How long the app keeps working | **7 days**, then it won't open until you run it from Xcode again | 1 year |
| Good for | Trying it out, a one-off event | An iPad that stays set up as a booth |

If you use a free account for an event, **re-run the app from Xcode within a few days before the event** so it doesn't expire mid-event.

---

## 4. Download the project

Open the **Terminal** app and run:

```bash
cd ~/Desktop
git clone https://github.com/Wonyoung258/jbch-photozone.git
cd jbch-photozone
```

> If macOS asks to install the **command line developer tools** when you run `git`, click **Install**, wait, and run the command again.

You can also click **Code → Download ZIP** on the GitHub page and unzip it, but `git clone` makes it easier to get updates later (`git pull`).

---

## 5. Open the project and let the packages load

1. In Finder, open the `jbch-photozone` folder and double-click **`UNIV-4cut.xcodeproj`**. The project still uses its original internal name, UNIV-4cut. That's expected.
2. Xcode automatically downloads the **Firebase** package (Swift Package Manager). Watch the progress bar at the top of the window. It can take a few minutes the first time.
3. When it finishes, the left sidebar shows **Package Dependencies → Firebase** and others.

If the packages don't load, use **File → Packages → Reset Package Caches**, then **File → Packages → Resolve Package Versions**.

> You'll see **`GoogleService-Info.plist` in red** in the sidebar. That's normal: the file is private and not in the repo. You'll create your own in [step 7](#7-create-your-own-firebase-project) and [step 8](#8-add-googleservice-infoplist-to-the-project).

---

## 6. Set up signing (your team + your bundle ID)

The project is set up with the previous developer's team and bundle ID. You need to switch both to your own, or Xcode won't be able to sign the app.

1. In the left sidebar, click the blue **UNIV-4cut** project icon at the very top.
2. In the middle panel, under **TARGETS**, select **UNIV-4cut**, not the item under *PROJECT*.
3. Open the **Signing & Capabilities** tab.
4. Make sure **Automatically manage signing** is checked.
5. **Team:** choose your team from step 3, e.g. *"Your Name (Personal Team)"*.
6. **Bundle Identifier:** change it to something unique to you, in reverse-domain style, for example:

   ```
   com.yourname.jbchphotozone
   ```

   Only letters, numbers, `.` and `-`. It must be unique across all of Apple, so `com.wykim.univ4cut` (already in use) won't work for you.
7. Wait a moment. The red errors under *Signing* should go away and show a **Provisioning Profile** and **Signing Certificate**. If an error remains, see [Troubleshooting](#13-troubleshooting).

**Write down your bundle ID.** Firebase needs the **exact same** value in the next step.

> These settings are saved in `UNIV-4cut.xcodeproj/project.pbxproj`. If you contribute back to this repo, avoid committing your personal team/bundle ID changes unless they're meant to be shared.

---

## 7. Create your own Firebase project

The app uses Firebase Storage to host each photo strip so guests can download it via QR code. Every person setting this up needs **their own** Firebase project and config file; the config file is private and is ignored by git.

1. Go to the [Firebase console](https://console.firebase.google.com/) and sign in with your Google account.
2. Click **Create a project** (or **Add project**).
   - Name it, e.g. `jbch-photozone`.
   - Google Analytics is optional. You can turn it off; the app doesn't use it.
   - Click **Create project**, wait, then **Continue**.
3. On the project overview page, click the **iOS+** icon (**Add app → iOS**).
4. **Register app:**
   - **Apple bundle ID:** enter the bundle ID from [step 6](#6-set-up-signing-your-team--your-bundle-id) **exactly** (it's case-sensitive). If it doesn't match, the app can't talk to Firebase.
   - App nickname: optional, e.g. `JBCH Photozone iPad`.
   - App Store ID: leave empty.
   - Click **Register app**.
5. **Download config file:** click **Download GoogleService-Info.plist**. Keep it; you'll use it in the next step.
6. The remaining steps in the Firebase wizard (*Add Firebase SDK*, *Add initialization code*) are **already done in this project**. Just click **Next** through them and then **Continue to console**.

---

## 8. Add `GoogleService-Info.plist` to the project

The Xcode project already contains a reference to this file at one exact location, so **copy the file there in Finder**. Don't drag it into Xcode, or you'll end up with a duplicate.

1. Rename the downloaded file if needed so it's exactly **`GoogleService-Info.plist`**. Browsers sometimes save it as `GoogleService-Info (1).plist`.
2. In Finder, move it into the **inner** `UNIV-4cut` folder, next to `Info.plist`:

   ```
   jbch-photozone/
   ├── UNIV-4cut.xcodeproj
   └── UNIV-4cut/
       ├── GoogleService-Info.plist   ← put it here
       ├── Info.plist
       ├── UNIV_4cutApp.swift
       └── ...
   ```

   Or from Terminal (adjust the source path if your download went elsewhere):

   ```bash
   cp ~/Downloads/GoogleService-Info.plist ~/Desktop/jbch-photozone/UNIV-4cut/
   ```

3. Back in Xcode, `GoogleService-Info.plist` in the sidebar should no longer be red. Click it and check that **`BUNDLE_ID`** matches your bundle ID from step 6.
4. Confirm git is ignoring it (it should never be committed):

   ```bash
   git status   # GoogleService-Info.plist should NOT be listed
   ```

> **Did you change your bundle ID later?** Then add a new iOS app in Firebase with the new bundle ID and download a fresh `GoogleService-Info.plist`. The old one won't match.

---

## 9. Turn on Firebase Storage (for QR codes)

The **QR Code** button uploads the strip to Firebase Storage and turns its download link into a QR code. Without this step, everything else (taking photos, saving, printing) still works, but the QR screen will stay on "Generating QR code…".

### 9a. Upgrade to the Blaze plan

Firebase requires the pay-as-you-go **Blaze** plan to create a Storage bucket (since October 2024). Blaze still includes a free monthly allowance, and a photo booth's usage is usually well within it, but a billing account is required.

1. In the Firebase console, click **Upgrade** (bottom of the left sidebar, next to *Spark*), choose **Blaze**, and link or create a Google Cloud billing account.
2. Recommended: set a **budget alert** (e.g. $5) when prompted, so you're emailed if costs ever appear.

### 9b. Create the Storage bucket

1. In the left sidebar, go to **Build → Storage** (or **Databases & Storage → Storage**, depending on the console version), then **Get started**.
2. Choose a **location** close to where the booth will be used. This can't be changed later.
3. Choose **Start in production mode** and click **Create**.

### 9c. Set the security rules

The app uploads without users signing in, so the rules must allow uploads into the `images/` folder. Open the **Rules** tab, replace everything with the following, and click **Publish**:

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Photo strips uploaded by the booth (random file names).
    match /images/{fileName} {
      allow read;
      allow create: if request.resource.size < 10 * 1024 * 1024; // max 10 MB
    }
    // Everything else is locked.
    match /{allPaths=**} {
      allow read, write: if false;
    }
  }
}
```

### 9d. (Recommended) Auto-delete old photos

The QR screen tells guests their photo expires, but nothing deletes the uploads unless you set a lifecycle rule:

1. Open the [Google Cloud Console → Cloud Storage → Buckets](https://console.cloud.google.com/storage/browser), making sure your Firebase project is selected at the top.
2. Click your bucket (named like `your-project-id.firebasestorage.app`) → **Lifecycle** tab → **Add a rule**.
3. Action: **Delete object**. Condition: **Age** = `1` day. Click **Create**.

> Cloud Storage lifecycle rules work in whole days, so 1 day is the shortest option. The app's QR screen currently says photos expire in **3 hours**. Update that text in `QRCodeSheetView.swift` if you want it to match.

---

## 10. Run the app on your iPad

### First-time iPad setup

1. Connect the iPad to the Mac with a cable and unlock it. If the iPad asks **"Trust This Computer?"**, tap **Trust** and enter the passcode.
2. **Turn on Developer Mode** (required on iPadOS 16+):
   - In Xcode, pick the iPad in the device menu at the top of the window. This makes the setting appear.
   - On the iPad: **Settings → Privacy & Security → Developer Mode** → turn **on** → **Restart** → after restart, tap **Turn On** and enter the passcode.

### Build and run

1. In Xcode's toolbar, click the device menu (next to the **UNIV-4cut** scheme) and select **your iPad**.
2. Press **▶ Run** (`⌘R`). The first build takes a few minutes because Firebase compiles.
3. **Free Apple ID only:** the first launch shows *"Untrusted Developer"*. On the iPad, go to **Settings → General → VPN & Device Management** → tap your Apple ID under *Developer App* → **Trust**. Then open the app again.
4. When the app starts, allow **Camera** access when asked (and **Photos** access the first time someone taps *Save*).

You can unplug the iPad afterwards. The app stays installed, but with a free Apple ID it stops opening after 7 days (see [step 3](#3-sign-in-to-xcode-with-your-own-apple-id)).

> **Tip for events:** use **Settings → Accessibility → Guided Access** on the iPad to lock it to this app, so guests can't leave the booth.

---

## 11. Set up the printer

Printing uses **AirPrint over Wi-Fi**. The iPad and printer must be on the **same Wi-Fi network**. iPads can't print over a USB cable.

1. Connect the printer to your Wi-Fi using its own menu (for the PM-400: **Setup → Wireless LAN**), and load **4×6 photo paper**.
2. Check the iPad can see it: open any photo in the **Photos** app → Share → **Print**. If the printer appears and prints, the app will work too.
3. In the app, after taking photos, tap **Print**:
   - **First time:** choose the printer from the list. The app remembers it.
   - **After that:** prints go straight to that printer with one tap.
   - **To switch printers:** **long-press** the Print button → **Change Printer…**.
4. Each print is a 4×6 sheet with **two identical strips side by side**. Cut it down the middle to get two 2×6 strips.

Guest/hotel Wi-Fi often blocks devices from seeing each other. If the printer doesn't show up, use a home network or a small travel router you control.

---

## 12. Customizing frames and the home screen

### Home screen image

The home screen shows the text **"JBCH PHOTOZONE"**. To show an image instead, add it to `UNIV-4cut/Resources/Assets.xcassets` with the name **`home_hero`** (drag the image into the asset catalog in Xcode and rename it). No code change is needed.

### Frame artwork

Frames are listed in `PhotoFrame.all` in `UNIV-4cut/Code/Utilities/Result/ImageProcessor.swift`. They're currently plain colors. To add a designed frame:

1. Create a **1200 × 3600 px PNG** with **transparent windows** where the photos go:

   | Photo | x | y | width × height |
   |---|---|---|---|
   | 1 | 80 | 80 | 1040 × 780 |
   | 2 | 80 | 900 | 1040 × 780 |
   | 3 | 80 | 1720 | 1040 × 780 |
   | 4 | 80 | 2540 | 1040 × 780 |

   The bottom area (y = 3320 to 3600) is free for logos and decoration.
2. Add the PNG to `Assets.xcassets`, e.g. named `strip_blossom`.
3. Add one line to `PhotoFrame.all`:

   ```swift
   PhotoFrame(id: "blossom", backgroundColor: .white, overlayImageName: "strip_blossom"),
   ```

It automatically appears as a choice on the result screen and is used for saving, QR, and printing.

### Other settings

| What | Where |
|---|---|
| Countdown length (default 6 s) | `CameraViewModel.countdownSeconds` in `CameraViewModel.swift` |
| App name on the home screen | Target → **General → Display Name** in Xcode |
| Print job name | `StripPrinter.send` in `ResultViewModel.swift` |

---

## 13. Troubleshooting

| Problem | Fix |
|---|---|
| **"Signing for "UNIV-4cut" requires a development team"** | Step 6: pick your team under *Signing & Capabilities*. If your team isn't listed, redo step 3. |
| **"Failed to register bundle identifier"** / "not available" | The bundle ID is taken. Pick a more unique one (step 6), then make a matching Firebase app + new `GoogleService-Info.plist` (steps 7–8). |
| **Build error: "Build input file cannot be found: …GoogleService-Info.plist"** | The file is missing or in the wrong folder. See step 8; it must be at `UNIV-4cut/GoogleService-Info.plist`. |
| **App crashes on launch** mentioning `FirebaseApp.configure` / config file | Same as above: the plist is missing, renamed, or not in the app target. |
| **"No such module 'Firebase'"** | **File → Packages → Reset Package Caches**, then **Product → Clean Build Folder** (`⇧⌘K`) and build again. |
| **"Multiple commands produce …GoogleService-Info.plist"** | The file was added twice. In Xcode, delete the extra reference (**Remove Reference**), keeping only one at `UNIV-4cut/GoogleService-Info.plist`. |
| **iPad doesn't appear in Xcode** | Unlock the iPad, tap **Trust**, try another cable/port. Check **Window → Devices and Simulators**. |
| **"Developer Mode disabled"** | Step 10: turn on Developer Mode on the iPad and restart it. |
| **"Untrusted Developer"** on the iPad | Settings → General → VPN & Device Management → Trust your Apple ID. |
| **App stopped opening after a week** | Free Apple ID profiles last 7 days. Connect the iPad and press ▶ Run again. |
| **Countdown repeats forever, no photos** | Camera unavailable (Simulator) or camera permission denied. Use a real iPad and allow camera in Settings → JBCH Photozone. |
| **QR screen stuck on "Generating QR code…"** | Storage isn't set up or the rules block uploads (step 9), or the iPad has no internet. Check the Xcode console for "Failed to upload image". |
| **"Printer Not Found"** | Printer off/asleep or on another network. Check step 11, or long-press **Print → Change Printer…**. |
| **White borders on prints** | Make sure 4×6 *photo* paper is loaded and selected on the printer. Borderless output depends on the printer's AirPrint support. |

---

## 14. Project structure

```
UNIV-4cut/
├── UNIV_4cutApp.swift          App entry point, configures Firebase
├── ContentView.swift           Picks the iPad or iPhone home layout
├── GoogleService-Info.plist    Your Firebase config (not in git; you add it)
├── Code/
│   ├── Features/
│   │   ├── Home/               Home screen ("JBCH PHOTOZONE" / home_hero image)
│   │   ├── Onboarding/         Instructions before shooting, camera permission
│   │   ├── TakePhoto/          Camera preview, 6-second countdown, captures 4 photos
│   │   └── Result/             Strip preview, frame picker, Home / QR / Save / Print
│   └── Utilities/Result/
│       └── ImageProcessor.swift  Strip layout, frames (PhotoFrame), strip + print-sheet rendering
└── Resources/
    ├── Assets.xcassets         Images, app icon
    ├── Colors.xcassets         Brand colors
    └── Fonts/                  Pretendard font
```

**Dependencies:** [Firebase iOS SDK](https://github.com/firebase/firebase-ios-sdk) 10.x via Swift Package Manager. Only **Firebase Storage** is used at runtime; you don't need to enable Firestore, Realtime Database, or Analytics.
