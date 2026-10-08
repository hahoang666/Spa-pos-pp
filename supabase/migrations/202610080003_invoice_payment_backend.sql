begin;

-- =========================================================
-- 1. Seed funds if they do not already exist
-- =========================================================

insert into public.funds (
    code,
    name,
    fund_type,
    opening_balance,
    is_active
)
select
    v.code,
    v.name,
    v.fund_type,
    0,
    true
from (
    values
        ('CASH',          'Quỹ tiền mặt', 'CASH'),
        ('BANK_TRANSFER', 'Ngân hàng',    'BANK'),
        ('E_WALLET',      'Ví điện tử',  'E_WALLET'),
        ('CARD',          'Máy POS thẻ', 'CARD_POS')
) as v(code, name, fund_type)
where not exists (
    select 1
    from public.funds f
    where f.code = v.code
);

-- =========================================================
-- 2. CREATE INVOICE
-- =========================================================

create or replace function public.create_invoice(
    p_items jsonb,
    p_customer_id bigint default null,
    p_employee_id bigint default null,
    p_type text default 'CASHIER',
    p_notes text default null
)
returns public.invoices
language plpgsql
security definer
set search_path = public
as $function$

declare
    v_invoice public.invoices;
    v_item jsonb;
    v_product public.products;

    v_quantity numeric(18,3);
    v_line_discount numeric(18,3);
    v_allocated_discount numeric(18,3);

    v_line_subtotal numeric(18,3);
    v_discount_total numeric(18,3);
    v_taxable_amount numeric(18,3);
    v_line_vat numeric(18,3);
    v_line_total numeric(18,3);

    v_subtotal numeric(18,3) := 0;
    v_discount numeric(18,3) := 0;
    v_vat numeric(18,3) := 0;
    v_total numeric(18,3) := 0;

begin

    if not public.has_permission('INVOICE_CREATE') then
        raise exception using
            errcode = '42501',
            message = 'FORBIDDEN: missing permission INVOICE_CREATE';
    end if;

    if p_type not in ('CASHIER', 'SALES') then
        raise exception using
            errcode = '22023',
            message = 'INVALID invoice type';
    end if;

    if p_items is null
       or jsonb_typeof(p_items) <> 'array'
       or jsonb_array_length(p_items) = 0 then
        raise exception using
            errcode = '22023',
            message = 'Invoice must contain at least one item';
    end if;

    if p_customer_id is not null then
        if not exists (
            select 1
            from public.customers
            where id = p_customer_id
        ) then
            raise exception using
                errcode = '23503',
                message = 'Customer does not exist';
        end if;
    end if;

    if p_employee_id is not null then
        if not exists (
            select 1
            from public.employees
            where id = p_employee_id
        ) then
            raise exception using
                errcode = '23503',
                message = 'Employee does not exist';
        end if;
    end if;

    insert into public.invoices (
        type,
        customer_id,
        employee_id,
        subtotal_before_vat,
        vat_amount,
        discount_amount,
        total_amount,
        paid_amount,
        due_amount,
        payment_status,
        status,
        notes
    )
    values (
        p_type,
        p_customer_id,
        p_employee_id,
        0,
        0,
        0,
        0,
        0,
        0,
        'UNPAID',
        'COMPLETED',
        p_notes
    )
    returning * into v_invoice;

    for v_item in
        select value
        from jsonb_array_elements(p_items)
    loop

        if not (v_item ? 'product_id') then
            raise exception using
                errcode = '22023',
                message = 'product_id is required';
        end if;

        if not (v_item ? 'quantity') then
            raise exception using
                errcode = '22023',
                message = 'quantity is required';
        end if;

        select *
        into v_product
        from public.products
        where id = (v_item->>'product_id')::bigint
          and status = 'ACTIVE';

        if not found then
            raise exception using
                errcode = '23503',
                message = 'Product does not exist or is inactive';
        end if;

        v_quantity := (v_item->>'quantity')::numeric;

        if v_quantity <= 0 then
            raise exception using
                errcode = '22023',
                message = 'Quantity must be greater than 0';
        end if;

        v_line_discount :=
            coalesce(
                (v_item->>'line_discount_amount')::numeric,
                0
            );

        v_allocated_discount :=
            coalesce(
                (v_item->>'allocated_order_discount_amount')::numeric,
                0
            );

        if v_line_discount < 0
           or v_allocated_discount < 0 then
            raise exception using
                errcode = '22023',
                message = 'Discount cannot be negative';
        end if;

        v_line_subtotal :=
            round(
                v_quantity * v_product.price_before_vat,
                3
            );

        v_discount_total :=
            v_line_discount + v_allocated_discount;

        if v_discount_total > v_line_subtotal then
            raise exception using
                errcode = '22023',
                message = 'Discount cannot exceed line subtotal';
        end if;

        v_taxable_amount :=
            greatest(
                v_line_subtotal - v_discount_total,
                0
            );

        v_line_vat :=
            round(
                v_taxable_amount * v_product.vat_rate / 100,
                3
            );

        v_line_total :=
            round(
                v_taxable_amount + v_line_vat,
                3
            );

        insert into public.invoice_items (
            invoice_id,
            product_id,
            product_code,
            product_name,
            unit_name,
            quantity,
            unit_price_before_vat,
            unit_price_after_vat,
            vat_rate,
            line_subtotal_before_vat,
            line_discount_amount,
            line_vat_amount,
            line_total_amount,
            allocated_order_discount_amount
        )
        values (
            v_invoice.id,
            v_product.id,
            v_product.code,
            v_product.name,
            (
                select u.name
                from public.units u
                where u.id = v_product.unit_id
            ),
            v_quantity,
            v_product.price_before_vat,
            v_product.price_after_vat,
            v_product.vat_rate,
            v_line_subtotal,
            v_line_discount,
            v_line_vat,
            v_line_total,
            v_allocated_discount
        );

        v_subtotal := v_subtotal + v_line_subtotal;
        v_discount := v_discount + v_discount_total;
        v_vat := v_vat + v_line_vat;
        v_total := v_total + v_line_total;

    end loop;

    update public.invoices
    set
        subtotal_before_vat = round(v_subtotal, 3),
        discount_amount = round(v_discount, 3),
        vat_amount = round(v_vat, 3),
        total_amount = round(v_total, 3),
        paid_amount = 0,
        due_amount = round(v_total, 3),
        payment_status = 'UNPAID',
        status = 'COMPLETED',
        updated_at = now()
    where id = v_invoice.id
    returning * into v_invoice;

    return v_invoice;

end;

$function$;

revoke all on function public.create_invoice(
    jsonb,
    bigint,
    bigint,
    text,
    text
) from public;

grant execute on function public.create_invoice(
    jsonb,
    bigint,
    bigint,
    text,
    text
) to authenticated;


-- =========================================================
-- 3. CREATE PAYMENT
--
-- Payment is created only by a user with PAYMENT_CREATE.
-- The OPEN shift is resolved from auth.uid(); clients cannot
-- choose another user's shift.
-- The existing payment trigger recalculates invoice status.
-- A successful payment also creates the corresponding
-- cashbook SALE transaction in the mapped fund and shift.
-- =========================================================

create or replace function public.create_payment(
    p_invoice_id bigint,
    p_payment_method_id bigint,
    p_amount numeric,
    p_reference_no text default null,
    p_notes text default null
)
returns public.payments
language plpgsql
security definer
set search_path = public
as $function$

declare
    v_invoice public.invoices;
    v_method public.payment_methods;
    v_shift public.shifts;
    v_fund public.funds;
    v_payment public.payments;

    v_due numeric(18,3);

begin

    -- =====================================================
    -- Authorization
    -- =====================================================

    if not public.has_permission('PAYMENT_CREATE') then
        raise exception using
            errcode = '42501',
            message = 'FORBIDDEN: missing permission PAYMENT_CREATE';
    end if;


    -- =====================================================
    -- Validate amount
    -- =====================================================

    if p_amount is null or p_amount <= 0 then
        raise exception using
            errcode = '22023',
            message = 'Payment amount must be greater than 0';
    end if;


    -- =====================================================
    -- Lock invoice
    -- =====================================================

    select *
    into v_invoice
    from public.invoices
    where id = p_invoice_id
    for update;

    if not found then
        raise exception using
            errcode = '23503',
            message = 'Invoice does not exist';
    end if;


    if v_invoice.status = 'CANCELLED' then
        raise exception using
            errcode = '22023',
            message = 'Cannot pay a cancelled invoice';
    end if;


    v_due :=
        greatest(
            v_invoice.total_amount
            - coalesce(v_invoice.paid_amount, 0),
            0
        );


    if v_due <= 0 then
        raise exception using
            errcode = '22023',
            message = 'Invoice is already fully paid';
    end if;


    if p_amount > v_due then
        raise exception using
            errcode = '22003',
            message = 'Payment amount exceeds invoice due amount';
    end if;


    -- =====================================================
    -- Validate payment method
    -- =====================================================

    select *
    into v_method
    from public.payment_methods
    where id = p_payment_method_id
      and is_active = true;

    if not found then
        raise exception using
            errcode = '23503',
            message = 'Payment method does not exist or is inactive';
    end if;


    -- =====================================================
    -- Resolve current user's OPEN SHIFT
    -- =====================================================

    select *
    into v_shift
    from public.shifts
    where opened_by = auth.uid()
      and status = 'OPEN'
    order by opened_at desc
    limit 1
    for update;

    if not found then
        raise exception using
            errcode = '42501',
            message = 'FORBIDDEN: no open shift for current user';
    end if;


    -- =====================================================
    -- Validate corresponding fund
    -- Payment method codes and fund codes are intentionally
    -- aligned: CASH / BANK_TRANSFER / E_WALLET / CARD.
    -- =====================================================

    select *
    into v_fund
    from public.funds
    where code = v_method.code
      and is_active = true;

    if not found then
        raise exception using
            errcode = 'P0001',
            message =
                'Fund is not configured for payment method '
                || v_method.code;
    end if;


    -- =====================================================
    -- Create payment
    -- The existing AFTER INSERT trigger
    -- payment_change_invoice_status calls
    -- recalculate_invoice_payment_status().
    -- =====================================================

    insert into public.payments (
        invoice_id,
        payment_method_id,
        amount,
        reference_no,
        notes,
        paid_at,
        created_by,
        shift_id
    )
    values (
        p_invoice_id,
        p_payment_method_id,
        p_amount,
        p_reference_no,
        p_notes,
        now(),
        auth.uid(),
        v_shift.id
    )
    returning * into v_payment;


    -- =====================================================
    -- Create cashbook transaction
    -- A successful payment is an IN / SALE transaction in
    -- the fund mapped to the payment method.
    -- =====================================================

    insert into public.cashbook_transactions (
        fund_id,
        shift_id,
        transaction_type,
        category,
        direction,
        amount,
        payment_id,
        reference_type,
        reference_id,
        txn_at,
        created_by,
        note
    )
    values (
        v_fund.id,
        v_shift.id,
        'SALE',
        'SALE',
        'IN',
        p_amount,
        v_payment.id,
        'INVOICE',
        p_invoice_id,
        coalesce(v_payment.paid_at, now()),
        auth.uid(),
        coalesce(
            p_notes,
            'Payment for invoice ' || v_invoice.code
        )
    );


    return v_payment;

end;

$function$;


-- =========================================================
-- 4. Execute permission
-- =========================================================

revoke all on function public.create_payment(
    bigint,
    bigint,
    numeric,
    text,
    text
) from public;

grant execute on function public.create_payment(
    bigint,
    bigint,
    numeric,
    text,
    text
) to authenticated;


commit;