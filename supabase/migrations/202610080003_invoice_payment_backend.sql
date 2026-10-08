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

commit;