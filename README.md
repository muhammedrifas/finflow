# FinFlow

A fast, offline-first personal finance management Android app built with Flutter, Riverpod, and Firebase Firestore.

## Features

- **Quick Transaction Logging:** Log debit and credit transactions in seconds with custom payment types (Cash, UPI, Credit Cards, Bank Accounts) and categories.
- **Offline-First Cloud Backup:** Writes instantly to local cache and automatically syncs to Firebase Firestore in the background.
- **Payment Reminders (±30 Days):** Schedule custom reminder dates/times (defaulting to 1 day before due date at 9:00 AM), toggle monthly repetition, check off paid bills with a 1-tap option to log the transaction, or export directly to any installed calendar app.
- **Financial Reports:** Analyze spending and income across any custom date range, grouped by either Payment Type or Category with interactive charts.
- **Advanced Search & Filtering:** Filter transactions by keyword, debit/credit, payment type, category, open-ended amount ranges (min/max), and date range.
- **Safe Editing & Deletion:** Long-press to edit transactions or reminders; confirmation prompts protect against accidental deletions.
- **Adaptive UI:** Material 3 design with automatic Light/Dark theme support.

## Tech Stack

- **Framework:** Flutter (Dart)
- **State Management:** Riverpod (`flutter_riverpod`)
- **Backend & Sync:** Firebase Auth (Anonymous) & Cloud Firestore (offline persistence enabled)
- **Notifications & Calendar:** `flutter_local_notifications`, `timezone`, `add_2_calendar`
- **Charts & Formatting:** `fl_chart`, `intl`