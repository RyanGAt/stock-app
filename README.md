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

This repository currently tracks only the Dart source (`lib/`) and may not include generated native folders like `ios/` or `android/`.

If Codemagic is configured as **Android & iOS** while those folders are missing, builds fail with:

```
Did not find xcodeproj from /Users/builder/clone/ios
```

Use the checked-in `codemagic.yaml` workflow (`yaml-auto-native`) and make sure the app is set to **Use codemagic.yaml** in Codemagic settings. This workflow:

1. Runs `flutter pub get`
2. Auto-generates missing native projects (`flutter create --platforms=android,ios .` as needed)
3. Builds Android debug APK
4. Builds iOS debug app with `--no-codesign`

If your build screen still shows generic steps like **Installing dependencies** and fails before the script named **Verify YAML workflow is running**, then Codemagic is still using a UI workflow instead of `codemagic.yaml`.

If you keep using Codemagic UI workflows instead of `codemagic.yaml`, you must manually add a pre-build step that runs `flutter create --platforms=ios .` before iOS build steps.
