# Spa POS API Contract v1.0 — Foundation

Status: Draft for implementation and Postman testing.

## Base

- Authentication: Supabase Auth / Bearer access token.
- API boundary: Supabase REST for simple CRUD; RPC/Edge Functions for multi-step business transactions.
- Every protected endpoint must authorize the authenticated user server-side. UI visibility is not an authorization control.

## Phase 1 resources

### Auth
- POST /auth/v1/token?grant_type=password — login through Supabase Auth.
- GET /auth/v1/user — current authenticated user.
- POST /auth/v1/logout — client/session logout.

### Employees / profiles
- GET /rest/v1/profiles
- GET /rest/v1/employee_profiles
- POST /rest/v1/employee_profiles
- PATCH /rest/v1/employee_profiles?id=eq.<id>

### Customers
- GET /rest/v1/customers
- POST /rest/v1/customers
- PATCH /rest/v1/customers?id=eq.<id>

### Products
- GET /rest/v1/products
- POST /rest/v1/products
- PATCH /rest/v1/products?id=eq.<id>
- GET /rest/v1/product_prices

### Shifts
Simple CRUD can use REST, but opening/closing a shift should eventually be exposed as RPC/Edge Functions so validation and atomicity are server-side:
- POST /rest/v1/rpc/open_shift
- POST /rest/v1/rpc/close_shift
- GET /rest/v1/shifts?status=eq.open

### Funds
- GET /rest/v1/funds
- POST /rest/v1/funds

## Planned Phase 2 transaction APIs

These are contracts to implement after the foundation migration is applied:

- POST /rest/v1/rpc/create_sale
- POST /rest/v1/rpc/record_payment
- POST /rest/v1/rpc/collect_debt
- POST /rest/v1/rpc/create_return
- POST /rest/v1/rpc/cancel_sale
- GET /rest/v1/cashbook_transactions

A transaction API must update all related records atomically. For example, a cash sale must not succeed if payment or required stock/cashbook updates fail.

## QA rules

1. Missing authentication token -> 401.
2. Authenticated but insufficient permission -> 403.
3. Invalid input -> 400/422.
4. Missing resource -> 404.
5. Business-rule violation -> 409 or a documented 4xx response.
6. Successful creation -> 201 for REST resources or 200 for RPC, consistently documented.
7. Sensitive operations must create an audit/approval record.
8. Tests must verify database side effects, not only HTTP status.

## First Postman collection

The first executable collection should cover:

- API-AUTH-01..08
- API-PRODUCT-01..05
- API-SHIFT-01..06

Then proceed to sales/payment/debt/return after the Phase 2 transaction RPCs exist.
