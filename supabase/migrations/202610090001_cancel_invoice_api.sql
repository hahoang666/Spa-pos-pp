begin;

-- Cancel Invoice API
-- Safe first iteration: only unpaid invoices can be cancelled.
-- Paid/partially paid invoices are rejected until the refund workflow
-- can reverse payments, cashbook, inventory, package sessions and commission
-- atomically. Do not bypass this API with a direct table update.

create or replace function public.cancel_invoice(
    p_invoice_id bigint,
    p_cancel_reason text
)
returns public.invoices
language plpgsql
security definer
set search_path = public
as $function$
declare
    v_user uuid := auth.uid();
    v_invoice public.invoices;
    v_shift public.shifts;
begin
    if v_user is null then
        raise exception using
            errcode = '42501',
            message = 'AUTH_REQUIRED';
    end if;

    if not public.has_permission('SALE_CANCEL') then
        raise exception using
            errcode = '42501',
            message = 'FORBIDDEN: missing permission SALE_CANCEL';
    end if;

    if p_invoice_id is null then
        raise exception using
            errcode = '22023',
            message = 'INVALID_INVOICE_ID';
    end if;

    if p_cancel_reason is null or length(btrim(p_cancel_reason)) = 0 then
        raise exception using
            errcode = '22023',
            message = 'CANCEL_REASON_REQUIRED';
    end if;

    -- Require the current user to have an open shift. This prevents
    -- cancellation actions from being recorded after the user's shift closes.
    select *
      into v_shift
      from public.shifts
     where opened_by = v_user
       and status = 'OPEN'
     order by opened_at desc
     limit 1
     for update;

    if not found then
        raise exception using
            errcode = '42501',
            message = 'FORBIDDEN: no open shift for current user';
    end if;

    -- Serialize concurrent cancellation/payment attempts on the invoice.
    select *
      into v_invoice
      from public.invoices
     where id = p_invoice_id
     for update;

    if not found then
        raise exception using
            errcode = 'P0002',
            message = 'INVOICE_NOT_FOUND';
    end if;

    if v_invoice.status = 'CANCELLED' then
        raise exception using
            errcode = '23505',
            message = 'INVOICE_ALREADY_CANCELLED';
    end if;

    if v_invoice.status <> 'COMPLETED' then
        raise exception using
            errcode = '22023',
            message = 'INVOICE_STATUS_NOT_CANCELLABLE';
    end if;

    -- Never cancel an invoice with any recorded payment. A future refund API
    -- must create the refund and reversal cashbook entries in the same
    -- transaction before it can safely cancel paid invoices.
    if coalesce(v_invoice.paid_amount, 0) > 0
       or exists (
           select 1
             from public.payments p
            where p.invoice_id = v_invoice.id
       ) then
        raise exception using
            errcode = '22023',
            message = 'PAID_INVOICE_REQUIRES_REFUND_WORKFLOW';
    end if;

    update public.invoices
       set status = 'CANCELLED',
           cancel_reason = btrim(p_cancel_reason),
           canceled_at = now(),
           canceled_by = v_user,
           updated_at = now()
     where id = v_invoice.id
     returning * into v_invoice;

    return v_invoice;
end;
$function$;

revoke all on function public.cancel_invoice(bigint, text) from public;
grant execute on function public.cancel_invoice(bigint, text) to authenticated;

commit;
