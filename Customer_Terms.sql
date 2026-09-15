--Customer Terms
--Purpose: Allows Finance team to view all customer's terms in one report. Or to exclude CASH customers.
--  This is a SSRS report

/*-------For debugging-------*/
-- DECLARE @LastPurchaseDate AS DATE
-- DECLARE @CreditStatus AS VARCHAR(10)

-- SET @CreditStatus = 'ALL'
-- SET @LastPurchaseDate = '09/10/2026'
/*-------For debugging-------*/


SELECT DISTINCT--TOP(100)
    c.customer_id,
    a.name,
    t.terms_desc,
    c.terms_id,
    MAX(oh.order_date) AS LastPurchaseDate

FROM
    customer AS c
    LEFT JOIN [address] AS a ON c.customer_id = a.id
    LEFT JOIN terms AS t ON c.terms_id = t.terms_id
    LEFT JOIN oe_hdr AS oh ON c.customer_id = oh.customer_id

WHERE
    c.delete_flag = 'N'
    AND c.company_id = 'MSI'
    --Request to include customers with even a non-completed order 3 years back
    AND (oh.delete_flag = 'N'
        OR (oh.delete_flag = 'Y' 
            AND oh.date_last_modified > DATEADD(YEAR,-3, GETDATE())--'1/1/2023 00:00:00'
        )
    )
    AND oh.projected_order = 'N'
    AND oh.completed = 'N'
    --Used to filter out CASH customers
    AND (@CreditStatus = 'ALL' OR c.credit_status <> @CreditStatus)

GROUP BY
    c.customer_id,
    a.name,
    t.terms_desc,
    c.terms_id

--Used to find latest purcahse date
HAVING
    MAX(CAST(oh.order_date AS DATE)) >= @LastPurchaseDate
