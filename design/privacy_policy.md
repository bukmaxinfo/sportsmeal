# SportsMeal Privacy Policy

*Last updated: April 6, 2026*

## Overview

SportsMeal ("the App") is a nutrition tracking app that uses AI to analyze meal photos. Your privacy is important to us. This policy explains what data the App collects, how it is used, and your rights.

## Data Collection and Storage

### Data Stored on Your Device
Most personal data is stored locally on your device using Apple's SwiftData framework:
- User profile (name, age, height, weight, sex, activity level, dietary preferences)
- Meal history (food items, calories, macros, timestamps)
- Meal photos (stored locally using iOS external storage)
- Exercise entries
- Pantry items
- Meal templates
- App preferences

We do not operate our own backend servers for this app.

### Account and Private iCloud Sync
SportsMeal uses Sign in with Apple for authentication. To help preserve account state and support private sync behavior, the app may store limited account data in your private iCloud / CloudKit storage, such as:
- your Apple user identifier
- display name
- email address if Apple provides it during sign in
- account record timestamps such as creation or last-seen time

This CloudKit usage is best-effort and tied to your own Apple account. We do not sell this data or use it for advertising.

### API Key Storage
Your Anthropic API key is stored securely in the iOS Keychain, Apple's encrypted credential storage system. The key is never stored in plaintext, never logged, and never transmitted to any party other than Anthropic's API. If you choose to use the optional Gemini chat feature, your Gemini API key is also stored in the iOS Keychain.

## Third-Party Services

### Anthropic API (Claude)
When you use AI-powered features (meal photo analysis, menu scanning, fridge scanning, recipe generation, meal recommendations), your data is sent to Anthropic's API:
- **Meal photos**: Sent as base64-encoded JPEG images (compressed and downscaled to max 1024px)
- **Text prompts**: Include contextual information like cuisine type, portion size, dietary preferences, and remaining calorie budget
- **No personal identifiers** are included in API requests (no name, no account ID, no device ID)

Anthropic's data handling is governed by their own privacy policy at https://www.anthropic.com/privacy. The App uses your own API key — you have a direct relationship with Anthropic.

### OpenFoodFacts API
When you scan a barcode, the barcode number is sent to OpenFoodFacts (https://world.openfoodfacts.org), a free, open-source food products database. Only the barcode number is sent — no personal data.

### Apple HealthKit
If you grant permission, the App reads and writes the following HealthKit data:
- **Reads**: Body weight, step count, active energy burned
- **Writes**: Dietary energy consumed (meal calories), workout sessions

HealthKit data is handled according to Apple's HealthKit guidelines and is never sent to external services. HealthKit access is optional and the App functions fully without it.

## Data Not Collected
The App does **not** collect or use:
- Location data
- Contact information
- Browsing history
- Advertising identifiers
- Analytics or crash reporting data
- Push notification tokens (notifications are local only)

## Camera and Photo Library
The App requests access to your photo library to select meal and menu photos for AI analysis. Photos are processed locally (downscaled and compressed) before being sent to the Anthropic API. The App does not access photos beyond those you explicitly select.

## Children's Privacy
The App is not directed at children under 13. We do not knowingly collect personal information from children.

## Data Deletion
All your data is stored locally on your device. To delete all App data:
1. Delete the App from your device
2. Your API key will be removed from the Keychain
3. All meal history, profile data, and photos will be permanently deleted

You can also remove individual meals, exercises, pantry items, and templates within the App.

## Changes to This Policy
We may update this Privacy Policy from time to time. The "Last updated" date at the top will reflect any changes.

## Contact
For privacy questions or concerns, please open an issue at the project's repository or contact the developer directly.
