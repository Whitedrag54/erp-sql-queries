--Top 5 Ranked Contacts Per Customer
--Purpose: Used in the SQL Report Server to provide management with the top 5 most used contacts per customer

--## Obtain a count of orders per contact per customer
WITH ContactOrderCount AS (
    SELECT
        voh.customer_id,
        va.name,
        voh.contact_id,
        vc.first_name,
        vc.last_name,
        COUNT(voh.order_no) AS OrderCount

    FROM
        p21_view_oe_hdr AS voh
        LEFT JOIN p21_view_contacts AS vc ON vc.id = voh.contact_id
        LEFT JOIN p21_view_address AS va ON va.id = vc.address_id

    WHERE
        --## Parameter here for SQL Report Server. If debugging include DECLARE
        voh.customer_id IN (SELECT s FROM dbo.Split(',', REPLACE(@CustomerList, ' ', '')))
        AND voh.order_date BETWEEN DATEADD(year, -1, CURRENT_TIMESTAMP) AND CURRENT_TIMESTAMP
        AND voh.projected_order <> 'Y'
        AND va.delete_flag <> 'Y'
        AND vc.delete_flag <> 'Y'

    GROUP BY 
        voh.contact_id,
        va.[name], 
        voh.customer_id,
        vc.first_name,
        vc.last_name

    --## For debugging
    -- ORDER BY 1,5 DESC
),

RankedContacts AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY OrderCount DESC) AS ContactRank
    FROM ContactOrderCount
    WHERE contact_id IS NOT NULL
)

--## Provide only up to the top 5 contacts
SELECT
    customer_id,
    [name],
    contact_id,
    first_name,
    last_name,
    OrderCount,
    ContactRank

FROM
    RankedContacts
    WHERE ContactRank <= 5

ORDER BY customer_id, ContactRank
