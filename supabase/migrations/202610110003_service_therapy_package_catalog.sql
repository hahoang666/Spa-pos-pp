-- Spa POS v1.1: service and therapy-package catalog fields + authenticated write path.
-- Additive only: preserves existing products and sales data.

begin;

alter table public.products
  add column if not exists product_group text,
  add column if not exists unit_name text,
  add column if not exists duration_minutes integer not null default 0,
  add column if not exists session_count integer not null default 0,
  add column if not exists valid_days integer not null default 0,
  add column if not exists price_after_vat numeric(18,3);

do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'products_duration_minutes_nonnegative') then
    alter table public.products add constraint products_duration_minutes_nonnegative check (duration_minutes >= 0);
  end if;
  if not exists (select 1 from pg_constraint where conname = 'products_session_count_nonnegative') then
    alter table public.products add constraint products_session_count_nonnegative check (session_count >= 0);
  end if;
  if not exists (select 1 from pg_constraint where conname = 'products_valid_days_nonnegative') then
    alter table public.products add constraint products_valid_days_nonnegative check (valid_days >= 0);
  end if;
  if not exists (select 1 from pg_constraint where conname = 'products_price_after_vat_nonnegative') then
    alter table public.products add constraint products_price_after_vat_nonnegative check (price_after_vat >= 0);
  end if;
end $$;

create index if not exists ix_products_product_type_status
  on public.products(product_type, status);

alter table public.products enable row level security;

drop policy if exists "Authenticated users can read products" on public.products;
create policy "Authenticated users can read products"
  on public.products for select to authenticated
  using (true);

drop policy if exists "Product editors can insert products" on public.products;
create policy "Product editors can insert products"
  on public.products for insert to authenticated
  with check (
    exists (
      select 1
      from public.profiles pr
      join public.role_permissions rp on rp.role_id = pr.role_id
      join public.permissions pe on pe.id = rp.permission_id
      where pr.id = auth.uid()
        and pr.is_active = true
        and pe.code = 'PRODUCT_EDIT'
    )
  );

drop policy if exists "Product editors can update products" on public.products;
create policy "Product editors can update products"
  on public.products for update to authenticated
  using (
    exists (
      select 1
      from public.profiles pr
      join public.role_permissions rp on rp.role_id = pr.role_id
      join public.permissions pe on pe.id = rp.permission_id
      where pr.id = auth.uid()
        and pr.is_active = true
        and pe.code = 'PRODUCT_EDIT'
    )
  )
  with check (
    exists (
      select 1
      from public.profiles pr
      join public.role_permissions rp on rp.role_id = pr.role_id
      join public.permissions pe on pe.id = rp.permission_id
      where pr.id = auth.uid()
        and pr.is_active = true
        and pe.code = 'PRODUCT_EDIT'
    )
  );

commit;
