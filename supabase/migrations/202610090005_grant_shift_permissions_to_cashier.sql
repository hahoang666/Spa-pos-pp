begin;

-- Grant the cashier role permission to view, open, and close its own shift.
-- Role 2 is the cashier role in the current demo database.
insert into public.role_permissions (role_id, permission_id)
select 2, p.id
from public.permissions p
where p.code in ('shift.view', 'shift.open', 'shift.close')
  and not exists (
    select 1
    from public.role_permissions rp
    where rp.role_id = 2
      and rp.permission_id = p.id
  );

commit;
