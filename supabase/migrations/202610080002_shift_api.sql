-- Phase 1.2 - Shift API
-- Supabase RPC + RLS
-- Safe additive migration. Does not delete existing business data.
--
-- RPCs:
--   public.open_shift(p_opening_cash)
--   public.get_current_shift()
--   public.close_shift(p_shift_id, p_actual_cash)
--
-- IMPORTANT:
-- 1) Permissions are created if missing, but NOT assigned to any role automatically.
-- 2) Direct client writes to shifts are explicitly denied.
-- 3) RPCs use SECURITY DEFINER and validate authorization themselves.

begin;

-- =========================================================
-- 1. Ensure shift permissions exist
-- =========================================================
insert into public.permissions (code, name, description)
values
  ('shift.view', 'Xem ca', 'Xem ca hiện tại và thông tin ca'),
  ('shift.open', 'Mở ca', 'Mở ca thu ngân'),
  ('shift.close', 'Chốt ca', 'Chốt ca thu ngân')
on conflict (code) do nothing;

-- =========================================================
-- 2. Authorization helper
-- =========================================================
create or replace function public.has_permission(p_permission_code text)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.profiles p
    join public.role_permissions rp
      on rp.role_id = p.role_id
    join public.permissions pm
      on pm.id = rp.permission_id
    where p.id = auth.uid()
      and p.is_active = true
      and pm.code = p_permission_code
  );
$$;

revoke all on function public.has_permission(text) from public;
grant execute on function public.has_permission(text) to authenticated;

-- =========================================================
-- 3. RLS for shifts
-- =========================================================
alter table public.shifts enable row level security;

drop policy if exists "Authenticated users can read shifts" on public.shifts;

create policy "Users with shift.view can read shifts"
  on public.shifts
  for select
  to authenticated
  using (
    public.has_permission('shift.view')
    and (
      opened_by = auth.uid()
      or closed_by = auth.uid()
    )
  );

-- Explicitly deny direct client writes.
drop policy if exists "No direct shift insert" on public.shifts;
create policy "No direct shift insert"
  on public.shifts
  for insert
  to authenticated
  with check (false);

drop policy if exists "No direct shift update" on public.shifts;
create policy "No direct shift update"
  on public.shifts
  for update
  to authenticated
  using (false)
  with check (false);

drop policy if exists "No direct shift delete" on public.shifts;
create policy "No direct shift delete"
  on public.shifts
  for delete
  to authenticated
  using (false);

-- =========================================================
-- 4. OPEN SHIFT
-- =========================================================
create or replace function public.open_shift(p_opening_cash numeric)
returns public.shifts
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_shift public.shifts;
begin
  if v_user is null then
    raise exception 'AUTH_REQUIRED'
      using errcode = '42501';
  end if;

  if not public.has_permission('shift.open') then
    raise exception 'FORBIDDEN: missing permission shift.open'
      using errcode = '42501';
  end if;

  if p_opening_cash is null or p_opening_cash < 0 then
    raise exception 'INVALID_OPENING_CASH'
      using errcode = '22023';
  end if;

  if exists (
    select 1
    from public.shifts
    where opened_by = v_user
      and status = 'OPEN'
  ) then
    raise exception 'SHIFT_ALREADY_OPEN'
      using errcode = '23505';
  end if;

  insert into public.shifts (
    code,
    opened_by,
    opened_at,
    opening_cash,
    expected_cash,
    status
  )
  values (
    'CA-' || to_char(clock_timestamp(), 'YYYYMMDDHH24MISSMS'),
    v_user,
    now(),
    p_opening_cash,
    p_opening_cash,
    'OPEN'
  )
  returning * into v_shift;

  return v_shift;
end;
$$;

revoke all on function public.open_shift(numeric) from public;
grant execute on function public.open_shift(numeric) to authenticated;

-- =========================================================
-- 5. GET CURRENT SHIFT
-- =========================================================
create or replace function public.get_current_shift()
returns public.shifts
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_shift public.shifts;
begin
  if v_user is null then
    raise exception 'AUTH_REQUIRED'
      using errcode = '42501';
  end if;

  if not public.has_permission('shift.view') then
    raise exception 'FORBIDDEN: missing permission shift.view'
      using errcode = '42501';
  end if;

  select *
  into v_shift
  from public.shifts
  where opened_by = v_user
    and status = 'OPEN'
  order by opened_at desc
  limit 1;

  return v_shift;
end;
$$;

revoke all on function public.get_current_shift() from public;
grant execute on function public.get_current_shift() to authenticated;

-- =========================================================
-- 6. CLOSE SHIFT
-- =========================================================
create or replace function public.close_shift(
  p_shift_id bigint,
  p_actual_cash numeric
)
returns public.shifts
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_shift public.shifts;
  v_expected_cash numeric;
begin
  if v_user is null then
    raise exception 'AUTH_REQUIRED'
      using errcode = '42501';
  end if;

  if not public.has_permission('shift.close') then
    raise exception 'FORBIDDEN: missing permission shift.close'
      using errcode = '42501';
  end if;

  if p_shift_id is null then
    raise exception 'INVALID_SHIFT_ID'
      using errcode = '22023';
  end if;

  if p_actual_cash is null or p_actual_cash < 0 then
    raise exception 'INVALID_ACTUAL_CASH'
      using errcode = '22023';
  end if;

  select *
  into v_shift
  from public.shifts
  where id = p_shift_id
  for update;

  if not found then
    raise exception 'SHIFT_NOT_FOUND'
      using errcode = 'P0002';
  end if;

  if v_shift.status <> 'OPEN' then
    raise exception 'SHIFT_NOT_OPEN'
      using errcode = '55000';
  end if;

  -- A normal cashier can close only their own shift.
  -- A manager/admin can close another user's shift when the role
  -- has the additional permission shift.close.any.
  if v_shift.opened_by <> v_user
     and not public.has_permission('shift.close.any') then
    raise exception 'FORBIDDEN: cannot close another user shift'
      using errcode = '42501';
  end if;

  -- Current Phase 1.2 baseline:
  -- expected cash starts from opening cash.
  -- Sales/debt/returns will update this through cashbook in later phases.
  v_expected_cash := v_shift.expected_cash;

  update public.shifts
  set
    closed_by = v_user,
    closed_at = now(),
    actual_cash = p_actual_cash,
    expected_cash = v_expected_cash,
    difference = p_actual_cash - v_expected_cash,
    status = 'CLOSED',
    updated_at = now()
  where id = p_shift_id
  returning * into v_shift;

  return v_shift;
end;
$$;

revoke all on function public.close_shift(bigint, numeric) from public;
grant execute on function public.close_shift(bigint, numeric) to authenticated;

commit;
