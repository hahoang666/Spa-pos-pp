-- Spa POS - Attendance employee-link resolution fix
-- Additive follow-up migration: profiles.employee_id is the primary account-to-employee link.
-- Existing employees may intentionally have no login account.
begin;

create or replace function public.attendance_current_employee_id()
returns bigint
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_employee_id bigint;
  v_match_count integer;
begin
  if auth.uid() is null then
    return null;
  end if;

  -- Primary mapping used by the current application: profiles.id = auth.uid()
  -- and profiles.employee_id references employees.id.
  select count(*), min(p.employee_id)
    into v_match_count, v_employee_id
  from public.profiles p
  join public.employees e on e.id = p.employee_id
  where p.id = auth.uid()
    and coalesce(p.is_active, true) = true
    and coalesce(e.is_active, true) = true;

  if v_match_count = 1 then
    return v_employee_id;
  elsif v_match_count > 1 then
    -- Fail closed if the account-to-employee mapping is unexpectedly ambiguous.
    return null;
  end if;

  -- Backward-compatible fallback for deployments using employees.auth_user_id.
  select count(*), min(e.id)
    into v_match_count, v_employee_id
  from public.employees e
  where e.auth_user_id = auth.uid()
    and coalesce(e.is_active, true) = true;

  if v_match_count = 1 then
    return v_employee_id;
  end if;

  -- Do not guess if no link exists or the mapping is ambiguous.
  return null;
end;
$$;

revoke all on function public.attendance_current_employee_id() from public;
grant execute on function public.attendance_current_employee_id() to authenticated;

commit;
