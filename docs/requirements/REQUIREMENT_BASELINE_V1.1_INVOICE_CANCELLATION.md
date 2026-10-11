# Requirement Baseline v1.1 Amendment — Invoice Cancellation and Simulated E-Invoice

- **Version:** 1.1 amendment
- **Date:** 2026-10-11
- **Status:** Proposed requirement update for the Spa POS demo
- **Supersedes:** Nothing in v1.0; v1.0 remains immutable history.
- **Scope:** Invoice cancellation, simulated e-invoice issuance state, audit logging, payment/refund and cashbook consistency.

## INV-CANCEL-01 — Cancellation eligibility

An invoice may be cancelled only when the user has the required permission, provides a non-empty reason, the transaction period is not locked, and the applicable shift/business rules are satisfied. The backend is the source of truth; the UI must not show success or mutate dependent business state before backend confirmation.

## INV-CANCEL-02 — Unpaid invoice, e-invoice not issued

A completed invoice with no recorded payment and no simulated e-invoice issuance may be cancelled. Persist the cancellation reason, timestamp, actor and audit event.

## INV-CANCEL-03 — Partially or fully paid invoice, e-invoice not issued

A completed invoice with partial or full payment may be cancelled if the simulated e-invoice has not been issued. The workflow must:
- require a cancellation reason and permission/approval according to existing rules;
- record an audit event with actor, timestamp, invoice ID, prior state, new state, reason, paid amount and refund outcome;
- handle any amount already collected through a clearly recorded refund/reversal workflow;
- keep payment, cashbook, shift, stock, therapy-card/session and commission records consistent;
- be idempotent and prevent duplicate refunds, cashbook reversals, stock restoration or commission reversals;
- perform related backend changes atomically, or return a clear failure without partial mutation.

Cancellation does not mean the original payment row should be silently deleted. Preserve the payment and represent any refund/reversal with explicit linked records.

## INV-CANCEL-04 — E-invoice has been issued

If the simulated e-invoice has been issued, do not allow direct cancellation through the ordinary invoice-cancel action, regardless of whether the invoice is unpaid, partially paid or fully paid. Show a clear message directing the user to the demo's simulated adjustment/replacement workflow. Do not claim any connection to the tax authority.

## INV-CANCEL-05 — Already cancelled

A cancelled invoice cannot be cancelled again. Repeated requests must not create duplicate audit events, refunds, cashbook transactions or stock changes.

## INV-CANCEL-06 — Audit and security

The backend must enforce authorization, eligibility and duplicate-operation protection. Audit logging must be persisted in a backend table/RPC-backed operation, not only in browser localStorage. Rejected operations must not mutate invoice/payment/cashbook/inventory state.

## Simulated e-invoice state

The demo must distinguish at minimum:
- `NOT_ISSUED` — not issued;
- `ISSUED` — simulated issuance completed;
- optionally `ADJUSTED` or `REPLACED` for later demo workflows.

These values represent demo-only state and do not constitute a real tax invoice or transmission to a tax authority. The exact database column/table mapping must be confirmed against the current schema before implementation.

## Acceptance tests

| ID | Scenario | Expected result |
|---|---|---|
| INV-CANCEL-01 | Unpaid, not issued | Cancel succeeds; audit persisted |
| INV-CANCEL-02 | Partially paid, not issued | Cancel/refund workflow succeeds once; audit and cashbook reconcile |
| INV-CANCEL-03 | Fully paid, not issued | Cancel/refund workflow succeeds once; audit and cashbook reconcile |
| INV-CANCEL-04 | Partially paid, issued | Direct cancellation blocked; no data changes |
| INV-CANCEL-05 | Fully paid, issued | Direct cancellation blocked; no data changes |
| INV-CANCEL-06 | Cancel an already cancelled invoice | Rejected; no duplicate side effects |
| INV-CANCEL-07 | User lacks permission | Backend rejects; no data changes |
| INV-CANCEL-08 | Backend error during cancellation | UI shows failure; no false success or partial local mutation |
| INV-CANCEL-09 | Reload after cancellation | Persisted state remains consistent with Supabase |
| INV-CANCEL-10 | Verify audit trail | Actor, time, reason, invoice, previous/new state and refund outcome are queryable |

## Implementation guardrails

- Preserve existing create-invoice, payment, open/close-shift and cashbook reconciliation flows.
- Do not directly edit production-like invoice rows to make a test pass.
- Do not reuse invoice ID 9 as a clean retest fixture: its UI/local state and backend state have diverged.
- Before implementing the paid-invoice path, inspect the current schema and existing refund/cashbook APIs, then implement the backend transaction and frontend integration together.
