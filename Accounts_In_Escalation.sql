--Customer Accounts In Escalation
--Purpose: Provides a list of customers who are in escalation. This is used in SSRS and by our Controller for reporting

WITH [61_90_Aging] AS (
    SELECT
        pvih.customer_id AS 'customer_id',
            SUM(
            CASE
                WHEN DATEDIFF(DAY, pvih.terms_due_date, CURRENT_TIMESTAMP) BETWEEN 61 AND 90 
                THEN (pvih.total_amount_home - pvih.amount_paid_home - pvih.terms_taken_home - pvih.allowed_home + pvih.memo_amount_home + pvih.bad_debt_amount_home)
                ELSE 0
            END
        ) AS [61-90],

        MIN(
            CASE 
                WHEN DATEDIFF(DAY, pvih.terms_due_date, CURRENT_TIMESTAMP) > 60 
                THEN pvih.terms_due_date 
            END
        ) AS [terms_due_date]

    FROM
    p21_view_invoice_hdr AS pvih
    JOIN p21_view_ship_to AS vst ON vst.ship_to_id = pvih.customer_id
    JOIN p21_view_address AS vad ON vad.id = pvih.customer_id

    WHERE
    pvih.invoice_no = pvih.invoice_reference_no
    AND pvih.consolidated <> 'Y'
    AND pvih.invoice_adjustment_type IN ('C', 'D', 'I', 'R', 'W', 'P')
    AND (
        pvih.total_amount_home - pvih.amount_paid_home - pvih.terms_taken_home - pvih.allowed_home + pvih.memo_amount_home + pvih.bad_debt_amount_home
    ) <> 0.00

    GROUP BY
    pvih.customer_id,
    pvih.bill2_name,
    vst.preferred_location_id,
    vad.mail_address1,
    vad.mail_address2,
    vad.mail_address3,
    vad.mail_city,
    vad.mail_state,
    vad.mail_postal_code,
    vad.central_phone_number

    HAVING SUM(
        CASE
            WHEN DATEDIFF(DAY, pvih.terms_due_date, CURRENT_TIMESTAMP) BETWEEN 61 AND 90 
            THEN (pvih.total_amount_home - pvih.amount_paid_home - pvih.terms_taken_home - pvih.allowed_home + pvih.memo_amount_home + pvih.bad_debt_amount_home)
            ELSE 0
        END
    ) <> 0
),

[91+_Aging] AS (
    SELECT
        pvih.customer_id AS 'customer_id',

        SUM(
            CASE
                WHEN DATEDIFF(DAY, pvih.terms_due_date, CURRENT_TIMESTAMP) > 90 
                THEN (pvih.total_amount_home - pvih.amount_paid_home - pvih.terms_taken_home - pvih.allowed_home + pvih.memo_amount_home + pvih.bad_debt_amount_home)
                ELSE 0
            END
        ) AS [90+],

        -- Returns the oldest due date for any open invoice over 90 days overdue
        MIN(
            CASE 
                WHEN DATEDIFF(DAY, pvih.terms_due_date, CURRENT_TIMESTAMP) > 90 
                THEN pvih.terms_due_date 
            END
        ) AS [terms_due_date]

    FROM
    p21_view_invoice_hdr AS pvih
    JOIN p21_view_ship_to AS vst ON vst.ship_to_id = pvih.customer_id
    JOIN p21_view_address AS vad ON vad.id = pvih.customer_id

    WHERE
    pvih.invoice_no = pvih.invoice_reference_no
    AND pvih.consolidated <> 'Y'
    AND pvih.invoice_adjustment_type IN ('C', 'D', 'I', 'R', 'W', 'P')
    AND (
        pvih.total_amount_home - pvih.amount_paid_home - pvih.terms_taken_home - pvih.allowed_home + pvih.memo_amount_home + pvih.bad_debt_amount_home
    ) <> 0

    GROUP BY
    pvih.customer_id,
    pvih.bill2_name,
    vst.preferred_location_id,
    vad.mail_address1,
    vad.mail_address2,
    vad.mail_address3,
    vad.mail_city,
    vad.mail_state,
    vad.mail_postal_code,
    vad.central_phone_number

    HAVING SUM(
        CASE
            WHEN DATEDIFF(DAY, pvih.terms_due_date, CURRENT_TIMESTAMP) > 90 
            THEN (pvih.total_amount_home - pvih.amount_paid_home - pvih.terms_taken_home - pvih.allowed_home + pvih.memo_amount_home + pvih.bad_debt_amount_home)
            ELSE 0
        END
    ) <> 0
)

SELECT --TOP(1000)
    pvih.customer_id AS 'Customer ID',
    pvih.bill2_name AS 'Customer',
    vst.preferred_location_id AS 'Branch',
    [61].[61-90],
    [91].[90+],
    CAST(GETDATE() AS DATE) AS 'date_run',
    '' AS 'cash_leader',
    CONCAT_WS(' ', con.first_name, con.mi, con.last_name) AS 'branch_leader',
    '' AS 'disputed',
    CASE
        WHEN c.credit_status = 'HOLD'
            THEN 'Y'
        ELSE 'N'
    END AS 'On Hold'

FROM
    p21_view_invoice_hdr AS pvih
    JOIN p21_view_ship_to AS vst ON vst.ship_to_id = pvih.customer_id
    JOIN p21_view_address AS vad ON vad.id = pvih.customer_id
    JOIN [61_90_Aging] AS [61] ON [61].customer_id = pvih.customer_id
    JOIN [91+_Aging] AS [91] ON [91].customer_id = pvih.customer_id
    JOIN customer AS c ON c.customer_id = pvih.customer_id
    JOIN contacts AS con ON c.salesrep_id = con.id

WHERE
    pvih.invoice_no = pvih.invoice_reference_no
    AND pvih.consolidated <> 'Y'
    AND pvih.invoice_adjustment_type IN ('C', 'D', 'I', 'R', 'W', 'P')
    AND (
        pvih.total_amount_home - pvih.amount_paid_home - pvih.terms_taken_home - pvih.allowed_home + pvih.memo_amount_home + pvih.bad_debt_amount_home
    ) <> 0
    AND (
        [61].[61-90] > 0
        OR [91].[90+] > 0
    )

GROUP BY
    pvih.customer_id,
    pvih.bill2_name,
    vst.preferred_location_id,
    vad.mail_address1,
    vad.mail_address2,
    vad.mail_address3,
    vad.mail_city,
    vad.mail_state,
    vad.mail_postal_code,
    vad.central_phone_number,
    [61].[61-90],
    [91].[90+],
    [61].terms_due_date,
    [91].[terms_due_date],
    c.credit_status,
    con.last_name, 
    con.first_name,
    con.mi

ORDER BY
    pvih.bill2_name
