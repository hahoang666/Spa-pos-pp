-- HR visibility policy: scope employee-profile reads by the authenticated user's role/link.
-- ADMIN: all employee rows. CASHIER: own linked row only. EMPLOYEE/MANAGER: own row plus technician/consultant rows.
-- INSERT/UPDATE remain governed by the existing can_manage_employees() policies.
create or replace function public.can_view_employee_profile(
  p_employee_id bigint,
  p_position text,
  p_department text
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.profiles me
    join public.roles r on r.id = me.role_id
    where me.id = auth.uid()
      and me.is_active = true
      and (
        r.code = 'ADMIN'
        or me.employee_id = p_employee_id
        or (
          r.code in ('EMPLOYEE', 'MANAGER')
          and (
            coalesce(p_position, '') || ' ' || coalesce(p_department, '')
          ) ~* '(kỹ[[:space:]-]*thuật|ky[[:space:]-]*thuat|technician|tư[[:space:]-]*vấn|tu[[:space:]-]*van|consultant)'
        )
      )
  );
$$;

revoke all on function public.can_view_employee_profile(bigint, text, text) from public;
grant execute on function public.can_view_employee_profile(bigint, text, text) to authenticated;

do $$
declare
  pol record;
begin
  -- Remove any permissive SELECT policy on employees; PostgreSQL ORs permissive policies together.
  for pol in
    select policyname
    from pg_policies
    where schemaname = 'public'
      and tablename = 'employees'
      and cmd = 'SELECT'
  loop
    execute format('drop policy if exists %I on public.employees', pol.policyname);
  end loop;
end $$;

create policy employees_select_scoped
on public.employees
for select
to authenticated
using (public.can_view_employee_profile(id, position, department));
