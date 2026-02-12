# Vinted Inventory Assistant (Flutter)

Flutter rebuild of the StockPlunge web app with Supabase-backed inventory management.

## Setup

1. Install Flutter 3.3+.
2. Provide Supabase credentials using `--dart-define` on the same `flutter run` command (do not run `--dart-define` by itself).

```bash
flutter run -d chrome \
  --dart-define=SUPABASE_URL=your_supabase_url \
  --dart-define=SUPABASE_ANON_KEY=your_supabase_anon_key
```

PowerShell (single line):

```powershell
flutter run -d chrome --dart-define=SUPABASE_URL=your_supabase_url --dart-define=SUPABASE_ANON_KEY=your_supabase_anon_key
```

## Supabase

Ensure the following tables/views exist (see project prompt for full schema):

- `items`
- `sales`
- `item_stock`
- `purchases`
- `purchase_details`
- `item_costs` (view)

Edge Function:
- `import-vinted`

All queries filter by `user_id`.


## Codemagic fix for this repo

This repository currently tracks only the Dart source (`lib/`) and does not include generated native folders like `ios/` or `android/`.

If Codemagic is configured as **Android & iOS**, the iOS step fails with:

```
Did not find xcodeproj from /Users/builder/clone/ios
```

Use the checked-in `codemagic.yaml` workflow (`android-debug`) so Codemagic:

1. Runs `flutter pub get`
2. Generates `android/` only when needed (`flutter create --platforms=android .`)
3. Builds a debug APK

If you want iOS builds too, generate and commit the `ios/` project first (or add a matching `flutter create --platforms=ios .` step and signing configuration).
