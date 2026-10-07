-- Spa POS Phase 1: database foundation
-- PostgreSQL / Supabase
-- Purpose: identity, employees, RBAC, customers, products, prices, funds and shifts.
-- This migration is intentionally additive and does not replace the current localStorage-based UI.

create extension if not exists pgcrypto;

create table if not exists public.roles (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name text not null,
  description text,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.permissions (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name text not null,
  description text,
  created_at timestamptz not null default now()
);

create table if not exists public.role_permissions (
  role_id uuid not null references public.roles(id) on delete cascade,
  permission_id uuid not null references public.permissions(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (role_id, permission_id)
);

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text unique,
  display_name text,
  role_id uuid references public.roles(id),
  is_active boolean not null default true,
  locked_until timestamptz,
  failed_login_attempts integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.employee_profiles (
  id uuid primary key default gen_random_uuid(),
  employee_code text not null unique,
  full_name text not null,
  phone text,
  email text,
  job_title text,
  specialty text,
  status text not null default 'active'
    check (status in ('active','inactive','terminated')),
  profile_id uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.customers (
  id uuid primary key default gen_random_uuid(),
  customer_code text not null unique,
  full_name text not null,
  phone text,
  email text,
  address text,
  customer_type text not null default 'new'
    check (customer_type in ('new','existing')),
  status text not null default 'active'
    check (status in ('active','inactive')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  product_code text not null unique,
  name text not null,
  product_type text not null
    check (product_type in ('service','package','cosmetic','material','other')),
  unit text,
  cost_price numeric(18,2) not null default 0 check (cost_price >= 0),
  selling_price numeric(18,2) not null default 0 check (selling_price >= 0),
  vat_rate numeric(5,2) not null default 10
    check (vat_rate in (0,5,8,10)),
  stock_managed boolean not null default false,
  status text not null default 'active'
    check (status in ('active','inactive')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.product_prices (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products(id) on delete cascade,
  price numeric(18,2) not null check (price >= 0),
  effective_from timestamptz not null default now(),
  effective_to timestamptz,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  check (effective_to is null or effective_to > effective_from)
);

create table if not exists public.price_change_logs (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products(id) on delete restrict,
  old_price numeric(18,2),
  new_price numeric(18,2) not null,
  reason text,
  changed_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now()
);

create table if not exists public.funds (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name text not null,
  fund_type text not null
    check (fund_type in ('cash','bank','ewallet','card')),
  opening_balance numeric(18,2) not null default 0
    check (opening_balance >= 0),
  opening_date date not null default current_date,
  allow_negative boolean not null default false,
  status text not null default 'active'
    check (status in ('active','inactive')),
  created_at timestamptz not null default now()
);

create table if not exists public.shifts (
  id uuid primary key default gen_random_uuid(),
  opened_by uuid references auth.users(id) on delete set null,
  opened_at timestamptz not null default now(),
  opening_cash numeric(18,2) not null default 0
    check (opening_cash >= 0),
  closed_by uuid references auth.users(id) on delete set null,
  closed_at timestamptz,
  actual_cash numeric(18,2)
    check (actual_cash is null or actual_cash >= 0),
  expected_cash numeric(18,2)
    check (expected_cash is null or expected_cash >= 0),
  difference numeric(18,2),
  status text not null default 'open'
    check (status in ('open','closed','cancelled')),
  note text,
  created_at timestamptz not null default now(),
  check (
    (status = 'open' and closed_at is null)
    or status <> 'open'
  )
);

create unique index if not exists ux_one_open_shift_per_user
  on public.shifts(opened_by)
  where status = 'open';

create index if not exists ix_profiles_role_id on public.profiles(role_id);
create index if not exists ix_employee_profiles_profile_id on public.employee_profiles(profile_id);
create index if not exists ix_customers_phone on public.customers(phone);
create index if not exists ix_products_type on public.products(product_type);
create index if not exists ix_product_prices_product on public.product_prices(product_id);
create index if not exists ix_shifts_status on public.shifts(status);
create index if not exists ix_shifts_opened_at on public.shifts(opened_at);

-- Seed the minimum roles used by the current QA baseline.
insert into public.roles (code, name, description)
values
  ('ADMIN', 'Admin', 'Toàn quyền hệ thống'),
  ('MANAGER', 'Quản lý', 'Quản lý nghiệp vụ và phê duyệt'),
  ('EMPLOYEE', 'Nhân viên', 'Quyền nghiệp vụ theo cấu hình')
on conflict (code) do nothing;

-- Seed permissions needed by the first API/security test set.
insert into public.permissions (code, name, description)
values
  ('AUTH_LOGIN', 'Đăng nhập', 'Đăng nhập hệ thống'),
  ('CUSTOMER_VIEW', 'Xem khách hàng', 'Xem hồ sơ khách hàng'),
  ('CUSTOMER_EDIT', 'Sửa khách hàng', 'Sửa hồ sơ khách hàng'),
  ('PRODUCT_VIEW', 'Xem hàng hóa', 'Xem hàng hóa/dịch vụ'),
  ('PRODUCT_EDIT', 'Sửa hàng hóa', 'Tạo/sửa hàng hóa và dịch vụ'),
  ('PRICE_EDIT', 'Sửa đơn giá', 'Thay đổi đơn giá'),
  ('SHIFT_OPEN', 'Mở ca', 'Mở ca thu ngân'),
  ('SHIFT_CLOSE', 'Chốt ca', 'Chốt ca thu ngân'),
  ('SALE_CREATE', 'Tạo hóa đơn', 'Tạo giao dịch bán hàng'),
  ('SALE_CANCEL', 'Hủy hóa đơn', 'Hủy hóa đơn'),
  ('PAYMENT_CREATE', 'Thanh toán', 'Ghi nhận thanh toán'),
  ('DEBT_COLLECT', 'Thu nợ', 'Thu tiền công nợ'),
  ('RETURN_CREATE', 'Trả hàng', 'Tạo giao dịch trả hàng'),
  ('CASHBOOK_VIEW', 'Xem sổ quỹ', 'Xem giao dịch quỹ'),
  ('REPORT_REVENUE_VIEW', 'Xem doanh thu', 'Xem báo cáo doanh thu'),
  ('APPROVAL_SENSITIVE', 'Phê duyệt giao dịch nhạy cảm', 'Phê duyệt giảm giá, sửa giá, hủy, hoàn tiền')
on conflict (code) do nothing;

-- Initial role mappings. Future versions can refine these permissions.
insert into public.role_permissions (role_id, permission_id)
select r.id, p.id
from public.roles r
cross join public.permissions p
where r.code = 'ADMIN'
on conflict do nothing;

insert into public.role_permissions (role_id, permission_id)
select r.id, p.id
from public.roles r
join public.permissions p on p.code in (
  'AUTH_LOGIN','CUSTOMER_VIEW','CUSTOMER_EDIT','PRODUCT_VIEW',
  'SHIFT_OPEN','SALE_CREATE','PAYMENT_CREATE','DEBT_COLLECT',
  'RETURN_CREATE'
)
where r.code = 'EMPLOYEE'
on conflict do nothing;

insert into public.role_permissions (role_id, permission_id)
select r.id, p.id
from public.roles r
join public.permissions p on p.code in (
  'AUTH_LOGIN','CUSTOMER_VIEW','CUSTOMER_EDIT','PRODUCT_VIEW','PRODUCT_EDIT',
  'PRICE_EDIT','SHIFT_OPEN','SHIFT_CLOSE','SALE_CREATE','SALE_CANCEL',
  'PAYMENT_CREATE','DEBT_COLLECT','RETURN_CREATE','CASHBOOK_VIEW',
  'REPORT_REVENUE_VIEW','APPROVAL_SENSITIVE'
)
where r.code = 'MANAGER'
on conflict do nothing;

-- Updated-at helper for tables that are edited over time.
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_profiles_updated_at on public.profiles;
create trigger trg_profiles_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

drop trigger if exists trg_employee_profiles_updated_at on public.employee_profiles;
create trigger trg_employee_profiles_updated_at
before update on public.employee_profiles
for each row execute function public.set_updated_at();

drop trigger if exists trg_customers_updated_at on public.customers;
create trigger trg_customers_updated_at
before update on public.customers
for each row execute function public.set_updated_at();

drop trigger if exists trg_products_updated_at on public.products;
create trigger trg_products_updated_at
before update on public.products
for each row execute function public.set_updated_at();
