begin;

-- Reject null and non-positive invoice IDs before looking up an invoice.
-- Keep the existing cancel_invoice authorization and business rules unchanged.

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

    if not public.has_permission('INVOICE_CANCEL') then
        raise exception using
            errcode = '42501',
            message = 'FORBIDDEN: missing permission INVOICE_CANCEL';
    end if;

    if p_invoice_id is null or p_invoice_id <= 0 then
        raise exception using
            errcode = '22023',
            message = 'INVALID_INVOICE_ID';
    end if;

    if p_cancel_reason is null or length(btrim(p_cancel_reason)) = 0 then
        raise exception using
            errcode = '22023',
            message = 'CANCEL_REASON_REQUIRED';
    end if;

    -- Require an open shift owned by the current user.
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

    -- Serialize concurrent operations on this invoice.
    select *
      into v_invoice
      from public.invoices
     where id = p_invoice_id
     for update;

    if not found then
        raise exception using
            errcode = '22023',
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

    -- Do not cancel invoices with payments until refund/reversal is implemented.
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
