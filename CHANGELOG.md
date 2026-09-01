# Changelog

## 2026-08-27
- **Updated** `lib/widgets/group_name_dialog.dart` — no autofocus on name field to avoid Samsung keyboard side toolbar popping over the dialog

## 2026-08-26
- **Added** `scripts/release.ps1` — bumps Play versionCode (+N) and builds the release AAB

## 2026-08-25
- **Updated** `lib/core/constants/revenue_cat_config.dart` — set Google Play RevenueCat API key
- **Updated** `android/app/build.gradle.kts` — release builds use upload keystore from `key.properties`
- **Added** `android/key.properties.example` — template for store/key passwords (real `key.properties` is gitignored)
- **Added** local `android/upload-keystore.jks` + `android/key.properties` (gitignored; not committed)
- **Updated** root `.gitignore` — ignore Android keystore and `key.properties`
- **Updated** Android `applicationId` / namespace to `com.yourname.clearday` and moved `MainActivity`
- **Updated** `lib/core/constants/revenue_cat_config.dart` — Google Play API key placeholder, entitlement `pro`, product `clearday_pro`
- **Updated** `lib/services/revenue_cat_service.dart` — DeepFocus-style configure, restore, and entitlement matching
- **Updated** `android/app/src/main/AndroidManifest.xml` — added `INTERNET` for release purchases; notification permissions unchanged
- **Updated** `test/core/entitlement_match_test.dart` — asserts Play release RevenueCat IDs
- **Confirmed** version remains `1.0.0+1` (`versionCode` 1 via `flutter.versionCode`)

## 2026-08-17
- **Updated** Material 3 UI polish: teal/green palette, card spacing, empty states, task check-off animation, and Pro badges
- **Updated** free limits to 2 groups, 3 subgroups, and 25 active tasks
- **Updated** subgroups so they can nest under other subgroups (e.g. Home · Kitchen · Sink)
- **Updated** free tier to allow 10 subgroups (still 2 top-level groups)
- **Updated** Pro matching to accept `ClarDay Pro` from the RevenueCat dashboard
- **Updated** purchase lookup to use product ID `ClearDayPro` and entitlement `ClarDay Pro`
- **Updated** Pro entitlement match to include RevenueCat ID `ClarDay Pro`
- **Updated** RevenueCat Test Store API key in `lib/core/constants/revenue_cat_config.dart`
- **Added** app launcher icon from `icon/icon.jpg` for Android, iOS, and Windows
- **Updated** Android `compileSdk` to 37 and enabled Java 8 desugaring for notifications
- **Added** unit tests for groups, tasks, Pro limits, and recurring tasks
- **Added** subgroups under a group (Home → Add subgroup, or menu on a group)
- **Updated** Home to show Groups first; tasks now live inside a Group
- **Added** `lib/models/task_group.dart` and `lib/screens/group/group_tasks_screen.dart`
- **Updated** free limits copy to 2 groups and 20 active tasks
- **Removed** list-first navigation (`lists_screen.dart`)
- **Added** Flutter app scaffold with Material 3, Riverpod, and local persistence
- **Added** `lib/models/` — Task, TaskList, Recurrence, AppSettings, AppData
- **Added** `lib/services/storage_service.dart` — JSON storage in shared_preferences
- **Added** `lib/services/notification_service.dart` — local task reminders
- **Added** `lib/services/revenue_cat_service.dart` — one-time Pro purchase and restore
- **Added** `lib/screens/home/home_screen.dart` — grouped Overdue / Today / Upcoming / Done
- **Added** `lib/screens/task_editor/task_editor_screen.dart` — due dates, reminders, recurring
- **Added** `lib/screens/lists/lists_screen.dart` — multiple lists with a 2-list free cap
- **Added** `lib/screens/paywall/paywall_screen.dart` — $1.99 one-time Pro unlock
- **Added** `lib/screens/settings/settings_screen.dart` — theme, reminders, Restore Purchase
- **Added** free limits of 20 active tasks and 2 lists, with Pro locks for recurring
- **Added** `.cursor/rules/flutter-tech-stack.mdc` — Flutter + Material 3, Riverpod, RevenueCat stack
- **Added** `.cursor/rules/flutter-monetization.mdc` — free trial + $1.99 one-time Pro, no subscriptions
- **Added** `.cursor/rules/flutter-architecture.mdc` — lib folder layout and small widgets
- **Added** `.cursor/rules/flutter-ui-ux.mdc` — light/dark, trial limits, paywall copy
- **Added** `.cursor/rules/flutter-behavior.mdc` — offline-first, MVP first
- **Added** `.cursor/rules/dev-log.mdc` — log files and features the agent creates
