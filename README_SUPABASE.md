# VERA Supabase Order Storage

## Configure environment

Copy `.env.example` to `.env.local` and set:

```env
VITE_SUPABASE_URL=https://YOUR_PROJECT_ID.supabase.co
VITE_SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_PUBLIC_KEY
```

Only the Supabase public/anon key belongs in the frontend. Never put a service-role key in `.env.local` or frontend code.

## Create the database

Open the Supabase SQL Editor and run `supabase-schema.sql`.

The script creates `public.orders`, enables Row Level Security, and exposes a narrow `create_vera_order(jsonb)` RPC. There are no public SELECT, UPDATE, or DELETE policies, so the browser cannot list or modify existing orders.

## Order flow

Checkout validates the existing form, snapshots the current cart into `items`, and calls the RPC. The RPC inserts the order with status `new` and returns the database `id` and `order_number`. Only after a successful response does the frontend clear the local cart and show the existing confirmation screen.

If the request fails, the cart is untouched and the checkout shows an error so the customer can retry.
