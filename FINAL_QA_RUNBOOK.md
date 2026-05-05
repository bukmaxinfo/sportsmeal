# SportsMeal Final QA Runbook

> For Hermes: run this checklist in order and record pass/fail evidence next to each item. Keep scope focused on launch-critical validation.

Goal: convert the existing launch checklist into a practical execution runbook with clear priorities, current known status, and exact verification order.

Last updated: 2026-04-13
Branch: `launch/sportsmeal-first-ship`

---

## Current Known Status

Already verified by repo/tooling:
- [x] Debug simulator build succeeds via:
  - `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project sportsmeal.xcodeproj -scheme sportsmeal -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' build`
- [x] Basic automated tests previously succeeded on iPhone 17 simulator
- [x] App Store metadata file exists: `design/appstore_metadata.md`
- [x] Privacy policy exists: `design/privacy_policy.md`
- [x] Screenshots exist in `design/screenshots/`
- [x] CloudKit entitlement now includes `iCloud.BK.sportsmeal`
- [x] Unused remote-notification / push capability drift removed from `Info.plist` and entitlements

Not yet verified / still manual:
- [ ] TestFlight distribution
- [ ] Final QA pass across device sizes
- [ ] Fresh install onboarding on device/archive build
- [ ] Real API key validation paths
- [ ] Core meal analysis plausibility
- [ ] HealthKit end-to-end behavior
- [ ] Localization behavior
- [ ] Offline/error-state behavior
- [ ] Release archive warning check

Known risk to keep in mind:
- Full `xcodebuild test` can take a long time and timed out during a later run because simulator/UI-test execution became slow/hung. Do not treat timeout as product failure without checking the `.xcresult` and simulator state.

---

## Priority Levels

- P0 = must pass before TestFlight/public launch
- P1 = should pass before broad tester rollout
- P2 = polish / confidence checks

---

## Phase 1 — Release Candidate Integrity (P0)

### 1. Confirm clean branch state
Expected: only intentional launch work is present.

Run:
```bash
git status --short
git branch --show-current
git log --oneline -5
```

Record:
- branch name
- whether working tree is clean
- latest commit hash

### 2. Confirm build still succeeds
Run:
```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild \
  -project sportsmeal.xcodeproj \
  -scheme sportsmeal \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  build
```

Pass if:
- build succeeds with no fatal errors

### 3. Confirm release messaging files are current
Review manually:
- `design/appstore_metadata.md`
- `design/privacy_policy.md`

Pass if:
- BYOK Anthropic key requirement is explicit
- Sign in with Apple / private iCloud sync story matches actual behavior
- no false push-notification claims

---

## Phase 2 — Fresh Install / Onboarding (P0)

Use a real device if possible. If not, use a freshly erased simulator.

### 4. Fresh install test
Steps:
1. Delete app from device/simulator
2. Install from Xcode archive or fresh build
3. Launch app
4. Complete onboarding flow

Validate:
- [ ] Login screen renders correctly
- [ ] Sign in with Apple flow behaves correctly
- [ ] onboarding name/body info saves correctly
- [ ] API key step is clear about BYOK and user-controlled costs

### 5. Invalid API key validation
Steps:
1. Open API key setup
2. Enter intentionally invalid key
3. Save/validate

Pass if:
- [ ] shows graceful validation failure
- [ ] no crash
- [ ] no false success state

### 6. No API key flow
Steps:
1. Skip API key during onboarding
2. land in app
3. open Scan tab

Pass if:
- [ ] app launches normally without key
- [ ] scan path clearly prompts for API key
- [ ] no crash or dead end

---

## Phase 3 — Core Product Loop (P0)

### 7. Home-cooked meal scan
Pass if:
- [ ] food items appear
- [ ] calories/macros are plausible
- [ ] save flow works

### 8. Chinese dish scan
Pass if:
- [ ] recognizes Chinese dish reasonably
- [ ] oil/cooking-method behavior feels sensible

### 9. Packaged food scan with visible label
Pass if:
- [ ] identifies packaged food nature
- [ ] uses official/label-like numbers when visible

### 10. Barcode scan
Pass if:
- [ ] barcode scanner opens
- [ ] OpenFoodFacts lookup returns usable data for common item
- [ ] fallback is graceful if not found

### 11. Menu scanner
Pass if:
- [ ] route is reachable from Scan toolbar
- [ ] menu image scans
- [ ] dish list appears
- [ ] budget-fit indicator appears

### 12. Portion multiplier
Pass if:
- [ ] 0.5x and 2x adjust totals correctly

### 13. Save meal as template
Pass if:
- [ ] template save works
- [ ] quick log shows template later

### 14. Multi-meal day dashboard
Pass if:
- [ ] calorie ring updates
- [ ] macro rings update
- [ ] remaining budget updates

---

## Phase 4 — Supporting Functional Checks (P1)

### 15. Exercise logging and projection
Pass if:
- [ ] exercise entry logs correctly
- [ ] calories burned look plausible
- [ ] weight-loss projection cap behaves correctly

### 16. Pantry basics
Pass if:
- [ ] add/edit pantry items works
- [ ] expiration sorting/warnings work
- [ ] recipe generation returns usable suggestions

### 17. HealthKit behavior
Run three subchecks:
- [ ] grant permissions and verify reads
- [ ] log meal and verify Health write
- [ ] deny permissions and verify app still works

### 18. Notifications
Pass if:
- [ ] local notification permission prompt behaves normally
- [ ] weekly/daily reminder logic still works if reachable in current UX
- [ ] no push-specific dependency exists

### 19. History and export
Pass if:
- [ ] history renders by date
- [ ] 7-day chart renders
- [ ] CSV export opens and contains expected fields

---

## Phase 5 — Localization / Error Paths (P1)

### 20. Switch to Chinese
Pass if:
- [ ] important UI strings translate
- [ ] AI flow still works
- [ ] no broken layout

### 21. Switch back to English
Pass if:
- [ ] no mixed-language leftovers

### 22. Offline meal scan behavior
Pass if:
- [ ] clear error appears
- [ ] no hang/crash

### 23. Poor-image edge cases
Pass if:
- [ ] dark/blurry image fails gracefully
- [ ] very large meal does not break layout

### 24. Persistence / lifecycle
Pass if:
- [ ] background/foreground preserves state
- [ ] kill/relaunch preserves stored data

---

## Phase 6 — Final Submission Checks (P0)

### 25. Screenshots match shipped UI
Review:
- `design/screenshots/`

Pass if:
- [ ] screenshots still represent current app accurately

### 26. App icon validation
Pass if:
- [ ] icon looks correct on home screen/settings/search

### 27. Version/build validation
Pass if:
- [ ] version/build values are what you want to submit

### 28. Release archive check
Run in Xcode or with command line if archive workflow is ready.
Pass if:
- [ ] archive succeeds
- [ ] no suspicious release warnings

### 29. Source sanity check
Pass if:
- [ ] no test API keys
- [ ] no stray debug prints
- [ ] no temporary hacks you don’t want in release notes

---

## Execution Order Recommendation

Run in this order:
1. Phase 1 — release candidate integrity
2. Phase 2 — onboarding/API-key flows
3. Phase 3 — core meal loop
4. Phase 6 — submission checks
5. Phase 4/5 — supporting and error-path checks

Reason:
- if onboarding or core scan flow fails, stop there and fix before doing broader QA

---

## Stop Conditions

Stop and fix before continuing if any of these fail:
- build failure
- onboarding failure
- invalid API key causes crash
- no-API-key flow traps the user
- meal scan core loop produces broken/empty results on normal inputs
- privacy / App Store copy becomes inconsistent again

---

## Suggested Result Template

Use this after running QA:

```markdown
## SportsMeal QA Result
- Build: PASS/FAIL
- Fresh install onboarding: PASS/FAIL
- API key flows: PASS/FAIL
- Core meal loop: PASS/FAIL
- HealthKit: PASS/FAIL
- Localization: PASS/FAIL
- Submission assets: PASS/FAIL
- Release archive: PASS/FAIL

Top blockers:
1. ...
2. ...
3. ...

Recommendation:
- Ready for TestFlight / Not ready
```
