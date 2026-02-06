# Vinted Inventory Assistant (Flutter)

Flutter rebuild of the StockPlunge web app with Supabase-backed inventory management.

## Setup

1. Install Flutter 3.3+.
2. Provide Supabase credentials using `--dart-define`.

```bash
flutter run -d chrome \
  --dart-define=SUPABASE_URL=your_supabase_url \
  --dart-define=SUPABASE_ANON_KEY=your_supabase_anon_key
```

## Supabase

Ensure the following tables/views exist (see project prompt for full schema):

- `items`
- `listings`
- `sales`
- `item_stock`
- `item_purchases`
- `item_costs` (view)

Edge Function:
- `import-vinted`

All queries filter by `user_id`.
