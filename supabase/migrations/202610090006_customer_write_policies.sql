-- Allow active authenticated Spa POS profiles to create and edit customer records.
-- Deliberately does not grant DELETE; customer history must be preserved.
begin;

grant select, insert, update on table public.customers to authenticated;

drop policy if exists "Active profiles can insert customers" on public.customers;
create policy "Active profiles can insert customers"
  on public.customers
  for insert
  to authenticated
  with check (
    exists (
      select 1
      from public.profiles p
      where p.id = auth.uid()
        and p.is_active = true
        and p.role_id in (1, 2, 3)
    )
  );

drop policy if exists "Active profiles can update customers" on public.customers;
create policy "Active profiles can update customers"
  on public.customers
  for update
  to authenticated
  using (
    exists (
      select 1
      from public.profiles p
      where p.id = auth.uid()
        and p.is_active = true
        and p.role_id in (1, 2, 3)
    )
  )
  with check (
    exists (
      select 1
      from public.profiles p
      where p.id = auth.uid()
        and p.is_active = true
        and p.role_id in (1, 2, 3)
    )
  );

commit;
