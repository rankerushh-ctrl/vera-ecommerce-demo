-- VERA order storage
-- Run this in Supabase SQL Editor.

create extension if not exists pgcrypto;

create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete set null,
  order_number text not null unique,
  customer_name text not null,
  customer_email text not null,
  customer_phone text not null,
  shipping_address text not null,
  city text not null,
  state text not null,
  pincode text not null,
  items jsonb not null,
  subtotal numeric(12,2) not null check (subtotal >= 0),
  status text not null default 'new' check (status in ('new','processing','shipped','completed')),
  created_at timestamptz not null default now()
);

alter table public.orders add column if not exists user_id uuid references auth.users(id) on delete set null;
alter table public.orders enable row level security;

-- No public SELECT/UPDATE/DELETE policies are created.
-- Customers can only create an order through the controlled RPC below.

drop function if exists public.create_vera_order(jsonb);
create or replace function public.create_vera_order(order_payload jsonb)
returns table(id uuid, order_number text)
language plpgsql
security definer
set search_path = public
as $$
declare
  created_id uuid;
  created_number text;
begin
  if order_payload is null then
    raise exception 'Order payload is required';
  end if;

  insert into public.orders (
    user_id,
    order_number,
    customer_name,
    customer_email,
    customer_phone,
    shipping_address,
    city,
    state,
    pincode,
    items,
    subtotal,
    status
  )
  values (
    auth.uid(),
    order_payload->>'order_number',
    order_payload->>'customer_name',
    order_payload->>'customer_email',
    order_payload->>'customer_phone',
    order_payload->>'shipping_address',
    order_payload->>'city',
    order_payload->>'state',
    order_payload->>'pincode',
    order_payload->'items',
    (order_payload->>'subtotal')::numeric,
    'new'
  )
  returning orders.id, orders.order_number
  into created_id, created_number;

  return query select created_id, created_number;
end;
$$;

revoke all on function public.create_vera_order(jsonb) from public;
grant execute on function public.create_vera_order(jsonb) to anon, authenticated;


-- Customers may only read orders that were created while authenticated as them.
drop policy if exists "Customers can view own orders" on public.orders;
create policy "Customers can view own orders"
on public.orders for select
to authenticated
using (auth.uid() = user_id);

-- Merchant dashboard access.
-- Create the merchant account in Supabase Authentication first, then insert its auth user id here.
create table if not exists public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

alter table public.admin_users enable row level security;

-- An authenticated merchant can only verify their own admin record.
drop policy if exists "Admin users can view own record" on public.admin_users;
create policy "Admin users can view own record"
on public.admin_users for select
to authenticated
using (auth.uid() = user_id);

-- Merchant order read/update access. Customers and anonymous users receive no direct order access.
drop policy if exists "Admins can view orders" on public.orders;
create policy "Admins can view orders"
on public.orders for select
to authenticated
using (exists (select 1 from public.admin_users a where a.user_id = auth.uid()));

drop policy if exists "Admins can update orders" on public.orders;
create policy "Admins can update orders"
on public.orders for update
to authenticated
using (exists (select 1 from public.admin_users a where a.user_id = auth.uid()))
with check (exists (select 1 from public.admin_users a where a.user_id = auth.uid()));

-- Keep the customer RPC locked down to the two client-facing roles.
revoke all on function public.create_vera_order(jsonb) from public;
grant execute on function public.create_vera_order(jsonb) to anon, authenticated;

-- If the existing orders table was created by the first VERA schema, replace its
-- original new-only status constraint with the merchant dashboard statuses.
alter table public.orders drop constraint if exists orders_status_check;
alter table public.orders add constraint orders_status_check
  check (status in ('new','processing','shipped','completed'));
