# SportsMeal - Project Tracker
Last updated: 2026-04-06
Architecture: Cloud AI API (Claude Vision) for meal photo analysis

## App Vision
A comprehensive health & nutrition iOS app. Photograph meals for AI-powered calorie estimation, track exercise, get personalized recommendations, manage your pantry, and generate recipes — all tailored to your body metrics and dietary goals.

## Current Status: v0.2 complete — all 3 phases implemented

---

## v0.2 Roadmap

### Phase 1: Quick Wins (improve core accuracy)

**M6 — Portion Control & Meal Notes** [S]
- [x] Add portion picker (0.5x / 1x / 1.5x / 2x) to CameraView before analysis
- [x] Add notes text field ("this is a shared plate", "extra sauce on the side")
- [x] Pass portion + notes into Claude prompt as context
- [x] Apply portion multiplier to calorie result
- [x] Store notes in existing Meal.notes field

**M7 — Multi-Cuisine Support** [S]
- [x] Add optional cuisine picker to CameraView (Chinese/Japanese/Indian/Mexican/Western/Other)
- [x] Enhance Claude prompt: "Consider cuisine type, typical serving sizes, cooking methods (oil-heavy stir fry vs steamed)"
- [x] Add cuisineType field to Meal model
- [x] Stacks with portion control for much better accuracy

**M8 — Smart Exercise Coaching** [S]
- [x] When calorie surplus detected, show banner: "You're X kcal over — here's how to burn it"
- [x] Invert existing MET math to calculate duration per exercise type
- [x] Show on HomeView as a contextual card (only when relevant)
- [x] No new API calls — pure math on existing data

### Phase 2: Infrastructure & Health Integration

**M9 — Extract Shared AI Client** [S]
- [x] Refactor CalorieEstimationService → shared ClaudeAPIClient actor (auth, request building, response parsing, image encoding)
- [x] Build thin services on top: MealAnalysisService, FridgeInventoryService, RecipeService, RecommendationService
- [x] All future AI features use this shared client
- [x] Add request caching for expensive operations

**M10 — Dietary Preferences** [S]
- [x] Create DietaryPreference model (dietType: keto/whole30/paleo/vegan/none, restrictions: [String])
- [x] Add to UserProfile as a relationship
- [x] Add preference selection in Profile settings
- [x] Feed preferences into all recommendation prompts

**M11 — Apple HealthKit Integration** [M]
- [x] Add HealthKit entitlement and permission descriptions
- [x] Create HealthKitService for read/write
- [x] Import: weight history, step count, active calories
- [x] Export: meal calories, exercise sessions
- [x] Sync weight changes into UserProfile automatically
- [x] Handle permission denial gracefully

### Phase 3: Big Features

**M12 — Pantry & Recipe Generation** [M — build together]
- [x] Create PantryItem model (name, category, quantity, expirationDate, isAvailable)
- [x] Build pantry management view (manual add/edit/remove items)
- [x] Fridge photo scan → AI identifies ingredients → user reviews & confirms before saving
- [x] Build recipe generation: "I have [pantry items], [X kcal budget], [dietary prefs] → suggest 3 recipes"
- [x] Recipe display with ingredients, instructions, estimated calories
- [x] Flag expiring items, suggest recipes that use them first

**M13 — Meal Recommendations** [M]
- [x] Proactive meal suggestions on HomeView based on remaining calorie budget
- [x] Factor in dietary preferences (keto/whole30/etc)
- [x] Factor in recent meals (avoid repetition)
- [x] Cache recommendations (don't re-fetch on every HomeView load)
- [x] Optional: "What should I eat?" quick action button

**M14 — Menu Scanner (reframed from restaurant feature)** [S]
- [x] Reuse existing photo analysis — point camera at a restaurant menu instead of a plate
- [x] AI estimates calories for each visible dish
- [x] Recommend dishes that fit remaining calorie budget
- [x] "You have 600 kcal left — these 3 dishes fit" overlay on menu scan results
- [x] No restaurant database or location services needed — just the menu photo

### Deferred / Backlog (v0.2)
- [ ] Receipt scanning for pantry (low ROI — manual entry is faster and more reliable)
- [ ] Restaurant database integration (dish-level nutrition data doesn't exist for indie apps)
- [ ] Barcode scanner for packaged foods
- [ ] Nutrition breakdown beyond calories (protein, carbs, fat)
- [ ] Meal templates / favorites for quick logging
- [ ] Watch app companion
- [ ] Widget for daily calorie summary
- [ ] Social sharing of progress
- [ ] Localization (English + Chinese)
- [ ] App icon and launch screen design

---

## v0.3 Roadmap — "Launch Ready"

### Current Milestone: Sprint 1 — Nutrition Depth & Polish
Progress: [15/16 tasks complete]

### P0 — Must Have (highest user impact)

**M15 — Macro Nutrition Breakdown** [M] ✅
- [x] Extend Claude prompt to return protein (g), carbs (g), fat (g) per food item alongside calories
- [x] Add macros fields to FoodItem model (protein, carbs, fat)
- [x] Create macro ring visualization on HomeView (3 nested rings: P/C/F)
- [x] Show macro summary per meal in HistoryView
- [x] Add daily macro targets to UserProfile (auto-calculated from diet type)
- [x] Factor macros into meal recommendations ("you're low on protein today")

**M16 — Meal Templates & Quick Log** [S] ✅
- [x] Create MealTemplate model (name, foodItems snapshot, source: manual/AI)
- [x] "Save as template" button on meal detail view
- [x] "Quick log" tab on CameraView — pick from saved templates
- [x] Auto-suggest templates based on time of day (breakfast/lunch/dinner)
- [x] Most-used meals surface first

### P1 — Should Have (launch readiness)

**M17 — App Icon & Launch Screen** [S] ✅
- [x] Design app icon matching dark luxury theme (gold on black, calorie ring motif)
- [x] Create all required icon sizes for App Store
- [x] Design launch screen with brand identity
- [x] Add to Assets.xcassets

**M18 — iOS Widgets** [M] ⚠️ (source ready, needs Xcode target setup)
- [x] Create WidgetKit extension source (SportsMealWidget/)
- [x] Small widget: daily calorie ring + remaining kcal
- [x] Medium widget: calorie ring + today's meals list + macros
- [x] Lock screen widget: simple calorie remaining number
- [ ] Add Widget Extension target in Xcode (File > New > Target > Widget Extension)
- [ ] Configure App Group for shared data access
- [ ] Widget deep links to relevant app sections

**M19 — Onboarding & First-Run Polish** [S] ✅
- [x] Add API key setup step to onboarding flow (step 5, with skip option)
- [ ] "Try it now" demo with sample meal photo for first-time users
- [ ] Explain each tab's purpose on first visit (coach marks)
- [ ] Empty state illustrations for History, Pantry, Exercise tabs

### P2 — Nice to Have

**M20 — Barcode Scanner for Packaged Foods** [M] ✅
- [x] Integrate AVFoundation barcode scanning (EAN-8, EAN-13, UPC-E, Code128, Code39)
- [x] Look up nutrition via OpenFoodFacts API (free, open source)
- [x] Auto-fill calories + macros from barcode data
- [x] Fallback to manual entry if barcode not found
- [x] Save to meal log with full macro breakdown

**M21 — Data Export & Sharing** [S] ✅
- [x] Export meal history as CSV (via share sheet in History view)
- [x] Weekly summary data service (DataExportService)
- [ ] Weekly summary card (shareable image)
- [ ] Integration with Apple Shortcuts for automation

---

## Sprint 2 — Scale & Reach (v0.4)

### P1 — Should Have

**M22 — Localization** [M] ✅
- [x] Extract all user-facing strings to Localizable.strings (200+ strings)
- [x] Chinese (Simplified) translation (zh-Hans)
- [x] Adapt Claude prompts for Chinese food recognition (names in Chinese, Chinese cooking methods)
- [x] Meal recommendations locale-aware (suggests Chinese/Asian meals for zh locale)

**M23 — Watch App Companion** [M] ⚠️ (source ready, needs Xcode target setup)
- [x] Watch app with calorie ring UI (SportsMealWatch/)
- [x] Quick-log from wrist (template meals)
- [x] Exercise start/stop from watch (run, walk, cycle)
- [x] WatchConnectivity manager for iPhone sync
- [ ] Add WatchKit target in Xcode (File > New > Target > Watch App)

**M24 — Performance & Cost Optimization** [S] ✅
- [x] Response caching with 5-min TTL for text AI calls
- [x] Image compression tuned to 60% quality (was 80%), max 1024px
- [x] API usage tracking dashboard in Profile (requests, tokens, cost estimate)
- [ ] Offline mode indicator + queued uploads

### P2 — Nice to Have

**M25 — Social & Accountability** [S] ✅
- [x] Weekly progress summary notifications (Sunday 8 PM)
- [x] Daily streak reminder notification (7 PM if no meals logged)
- [x] Streak tracking on HomeView (current streak with fire icon)
- [x] StreakService with current + longest streak calculations
- [ ] Share meal cards to social media

---

## Sprint 3 — App Store Submission (v1.0)

- [x] App Store screenshots (5 screenshots at 1290x2796px in design/screenshots/)
- [x] App Store description, keywords, and metadata (design/appstore_metadata.md)
- [x] Privacy policy (design/privacy_policy.md — covers HealthKit, photos, API, barcode)
- [ ] TestFlight beta distribution
- [x] Performance profiling: added timestamp index on Meal, task cancellation in CameraView, image compression tuned to 60%
- [x] Accessibility audit: added VoiceOver labels to calorie ring, macro rings, charts; fixed color-only indicators in MenuScannerView
- [ ] Final QA pass across device sizes

---

## Design Assets
- [x] Marketing poster: `design/sportsmeal_poster.png` — dark luxury showcase (Aureum Vitae aesthetic)
- [x] Design philosophy: `design/aureum_vitae_philosophy.md`
- [x] App icon: `Assets.xcassets/AppIcon.appiconset/icon_1024.png` (M17)
- [x] App Store screenshots: `design/screenshots/` (5 screenshots, 1290x2796px)
- [x] App Store metadata: `design/appstore_metadata.md`
- [x] Privacy policy: `design/privacy_policy.md`

---

## Completed Milestones (v0.1)

### M1 - Foundation & User Profile ✅
- [x] Tab structure (Home/Scan/History/Exercise/Profile)
- [x] User Profile model + onboarding wizard
- [x] BMI, BMR (Mifflin-St Jeor), TDEE calculators
- [x] SwiftData persistence

### M2 - Meal Photo & Calorie Estimation ✅
- [x] PhotosUI integration + Claude Vision API
- [x] Food recognition with calorie estimation
- [x] Meal model with photo storage (@Attribute(.externalStorage))

### M3 - Daily Tracking & History ✅
- [x] Daily calorie summary + meal history (grouped by date)
- [x] Swift Charts (7-day calorie + meal count)
- [x] Meal detail view + delete functionality

### M4 - Exercise & Weight Loss Planning ✅
- [x] 10 exercise types with MET values
- [x] Caloric deficit calculator (BMR + exercise - food)
- [x] Realistic weight loss projections (capped at 0.5 kg/week)
- [x] Daily balance status (surplus/deficit/maintaining)

### M5 - Polish & UX ✅
- [x] Dark luxury theme (gold accents, glass cards)
- [x] In-app API key management (Keychain storage)
- [x] BMI/BMR/TDEE info popovers
- [x] Camera/photo permissions
- [x] Image downscaling before API upload

---

## Architecture Notes
- **API Client**: Needs refactor from single CalorieEstimationService → shared ClaudeAPIClient (M9, do before Phase 3)
- **Cost awareness**: Fridge photo = most expensive API call. Recipe generation = text-only, cheap. Exercise recs = zero API cost.
- **Offline**: Pantry browsing, preference editing, exercise logging, history — all offline. AI features require internet.
- **Frameworks needed**: HealthKit (M11), CoreLocation/MapKit (NOT needed — menu scanner replaces restaurant feature)

## Open Questions
1. ~~**Photo AI approach**~~ — DECIDED: Claude Vision API
2. ~~**Restaurant integration**~~ — REFRAMED: Menu scanner instead (no restaurant database needed)
3. **Nutrition database** — Still open. AI-only for now, consider adding for manual entry fallback later
4. **Target iOS version** — iOS 17+ (SwiftData requires 17)
5. **API cost management** — Need caching strategy before Phase 3 features go live
