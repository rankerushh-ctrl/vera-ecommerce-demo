# VERA Merchant Dashboard

The merchant dashboard lives at `/admin` and uses the existing Supabase client and `orders` table. The storefront is unchanged.

## Setup

1. Keep `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY` in `.env`.
2. Run the updated `supabase-schema.sql` in Supabase SQL Editor.
3. In Supabase Authentication, create a merchant user with email/password.
4. Copy that user's UUID from Authentication > Users.
5. In SQL Editor, authorize that user:

```sql
insert into public.admin_users (user_id)
values ('YOUR_AUTH_USER_UUID');
```

6. Open `http://localhost:5173/admin` and sign in with that merchant account.

## Dashboard behavior

- Orders are read from `public.orders`, newest first.
- Selecting an order shows customer, shipping, line items, subtotal, date and status.
- Status changes update `public.orders.status` directly.
- Supported statuses: `new`, `processing`, `shipped`, `completed`.
- Customers do not receive SELECT/UPDATE access to orders through RLS.
- No service-role key is used in the frontend.
