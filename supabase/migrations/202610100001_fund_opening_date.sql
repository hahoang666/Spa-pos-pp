-- Keep each fund's opening balance date in Supabase as the source of truth.
ALTER TABLE public.funds
  ADD COLUMN IF NOT EXISTS opening_date date;

UPDATE public.funds
SET opening_date = DATE '2026-10-07'
WHERE opening_date IS NULL;

ALTER TABLE public.funds
  ALTER COLUMN opening_date SET DEFAULT DATE '2026-10-07';

ALTER TABLE public.funds
  ALTER COLUMN opening_date SET NOT NULL;

COMMENT ON COLUMN public.funds.opening_date IS
  'Date from which opening_balance is the starting balance for fund summaries.';
